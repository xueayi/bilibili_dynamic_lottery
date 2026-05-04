# Docker 容器化与 CI/CD 设计文档

## 概述

为 bilibili_dynamic_lottery 项目添加 Docker 容器化支持和 GitHub Actions 自动构建推送工作流，实现一键部署和自动化发布。

## 决策记录

| 决策 | 选择 | 理由 |
|---|---|---|
| 镜像架构 | 单镜像（Nginx + PHP-FPM + Vue 静态文件） | 项目体量小，单镜像部署最简单 |
| 触发条件 | 仅 tag 发布时触发 | 适合稳定发布节奏 |
| 前端 API 地址 | 运行时 envsubst 注入 | 同一镜像可用于不同环境 |
| 版本策略 | 从 v2.5.0 开始 | 与项目现有版本号衔接 |

## 文件清单

| 文件 | 说明 |
|---|---|
| `Dockerfile` | 多阶段构建：Node.js 构建前端 → PHP-FPM + Nginx 运行时 |
| `docker-compose.yml` | 示例 compose 配置 |
| `.dockerignore` | Docker 构建排除文件列表 |
| `docker/nginx.conf` | Nginx 配置，前端静态文件 + PHP API |
| `docker/entrypoint.sh` | 容器启动脚本，envsubst 替换 + 配置初始化 |
| `docker/config/cookie.example.txt` | Cookie 配置示例文件 |
| `docker/config/env.example.php` | PHP 环境配置示例文件 |
| `.github/workflows/docker-publish.yml` | GitHub Actions 自动构建推送工作流 |

## 架构设计

### Dockerfile（多阶段构建）

```
阶段1: node:20-alpine
├── 复制 vue/ 目录
├── npm install
├── npm run build → dist/ 静态文件
└── 输出 dist/

阶段2: php:8.2-fpm-alpine
├── 安装 Nginx、PHP 扩展
├── 复制 api/、config/、docker/ 目录
├── 复制阶段1 dist/ 到 Nginx webroot
├── 配置 entrypoint.sh
└── 暴露 80 端口
```

### 前端环境变量运行时注入

Vite 在构建时会将 `import.meta.env.VITE_*` 变量内联为字符串字面量到 JS bundle 中。为实现运行时注入：

1. 构建阶段：`.env.docker` 文件中使用占位符值（如 `__VITE_API_ROOT_URL__`）
2. 启动阶段：`entrypoint.sh` 通过 `sed` 将占位符替换为实际环境变量值

前端代码中引用的全部环境变量（共 5 个）：
- `VITE_API_ROOT_URL` — 后端 API 地址（`vue/src/constants/constants.js`）
- `VITE_BILIBLI_LINK` — B站频道链接（`vue/src/components/header/MyHeader.vue`）
- `VITE_GITHUB_LINK` — GitHub 项目链接（`vue/src/components/header/MyHeader.vue`）
- `VITE_GITHUB_BILIBILI_API_COLLECT_LINK` — B站 API 文档链接（`vue/src/components/header/MyHeader.vue`）
- `VITE_APP_VERSION` — 网页显示版本号（`vue/src/components/MyFooter.vue`）

### Nginx 配置

- 监听 80 端口
- `/` 路由：前端静态文件（try_files 到 index.html，支持 SPA）
- `/api/` 路由：转发到 PHP-FPM（fastcgi_pass 127.0.0.1:9000）
- PHP 超时时间设置为 3 小时（与项目原配置一致）

### 敏感配置文件

通过 volume 挂载，不打包进镜像：
- `config/cookie.txt` — B站 Cookie
- `api/env.php` — PHP 环境配置

示例文件统一存放在 `docker/config/` 目录。

### docker-compose.yml

```yaml
services:
  bilibili-lottery:
    image: ${DOCKERHUB_USERNAME}/bilibili_dynamic_lottery:latest
    ports:
      - "8080:80"
    environment:
      - VITE_API_ROOT_URL=https://your-domain.com/api/index.php
      - VITE_BILIBLI_LINK=
      - VITE_GITHUB_LINK=
      - VITE_APP_VERSION=2.5.0
    volumes:
      - ./docker/config/cookie.txt:/var/www/html/config/cookie.txt
      - ./docker/config/env.php:/var/www/html/api/env.php
    restart: unless-stopped
```

## GitHub Actions 工作流

### 触发条件

推送 tag（格式 `v*`），如 `git tag v2.5.0 && git push origin v2.5.0`。

### 执行流程

1. Checkout 代码
2. 设置 Docker Buildx
3. 登录 Docker Hub（使用 secrets）
4. 提取 tag 版本号（如 v2.5.0 → 2.5.0）
5. 构建并推送镜像，打两个标签：`2.5.0` + `latest`
6. 支持多平台：linux/amd64, linux/arm64

### Secrets 配置

在仓库 Settings → Secrets and variables → Actions 中配置：

| Secret | 说明 |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub 用户名 |
| `DOCKERHUB_TOKEN` | Docker Hub Access Token |

### 镜像标签

镜像名称：`<DOCKERHUB_USERNAME>/bilibili_dynamic_lottery`

| 触发方式 | 标签 |
|---|---|
| 推送 tag `v2.5.0` | `2.5.0`, `latest` |
| 推送 tag `v2.5.1` | `2.5.1`, `latest` |

## 部署步骤（用户视角）

### 快速开始

```bash
# 1. 拉取镜像
docker pull <username>/bilibili_dynamic_lottery:latest

# 2. 准备配置文件
cp docker/config/cookie.example.txt docker/config/cookie.txt
cp docker/config/env.example.php docker/config/env.php
# 编辑 cookie.txt 和 env.php 填入实际值

# 3. 修改 docker-compose.yml 中的环境变量

# 4. 启动
docker compose up -d
```

### README 更新

在 README.md 中新增 Docker 部署方式说明，包括：
- 前提条件（安装 Docker + Docker Compose）
- 快速开始步骤
- 环境变量说明
- 配置文件说明
- 常用命令（启动/停止/查看日志/更新）

## 版本号管理

- Docker 镜像标签：由 git tag 决定
- 网页显示版本：由 `VITE_APP_VERSION` 环境变量决定
- 建议保持两者一致
- 首个 Docker 版本：v2.5.0

## 注意事项

1. PHP 超时时间（3小时）需在 Nginx 和 PHP-FPM 配置中同步设置
2. cookie.txt 和 env.php 通过 volume 挂载，镜像中不含敏感信息
3. entrypoint.sh 需处理首次启动时配置文件不存在的情况（从示例文件复制）
4. 环境变量替换需要在前端构建产物的所有相关文件中执行
