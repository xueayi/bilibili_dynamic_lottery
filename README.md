<p align="center">
    <img src="./vue/public/logo.png" width="250" height="250">
</p>

# B站在线抽奖工具

本工具可以从B站 (视频/动态) 中提取出 (评论/转发/点赞) 用户列表, 然后随机选出中奖者。

支持以下功能：
- 从视频或动态中提取评论、转发、点赞用户
- 随机抽取中奖用户
- 检测用户是否完成评论+点赞+转发全部要求
- 登陆B站账号后查询，可降低触发风控的概率
- 一键查询目标用户是否为自己的粉丝

## 在线使用地址
[https://bilibili.mikuclub.cc/](https://bilibili.mikuclub.cc/ "https://bilibili.mikuclub.cc/")

## 浏览器插件版本
（此项目库单独存放在[https://github.com/sakmist/Bilibili-Lottery-Local-Extension](https://github.com/sakmist/Bilibili-Lottery-Local-Extension "https://github.com/sakmist/Bilibili-Lottery-Local-Extension")
为了进一步降低触发B站风控的概率，我们还提供了浏览器插件版本。插件通过本地浏览器读取互动数据，避免服务器高频请求，具有以下优势：

- 减少接口限流风险
- 保留与在线工具一致的操作体验
- 支持离线保存抽奖过程，方便日后复盘与公示

### 支持的浏览器
- Chrome / Edge / 360 等 Chromium 浏览器
- Firefox

### 安装方法
1. 下载 `Bilibili-Lottery-Local-Extension.zip` 并解压
2. 在浏览器中加载已解压的扩展程序
   - Chrome/Edge: 打开 `chrome://extensions` 或 `edge://extensions`，开启「开发者模式」，点击「加载已解压的扩展程序」
   - Firefox: 将文件夹压缩为 `.xpi` 文件，在 `about:debugging` 中加载

## 参考文档
[SocialSisterYi/bilibili-API-collect](https://github.com/SocialSisterYi/bilibili-API-collect/tree/master "SocialSisterYi/bilibili-API-collect")

## 贡献名单
| 头像 | 用户名 |
| ---- | ------ |
| <a href="https://github.com/monoglo"><img src="https://avatars.githubusercontent.com/u/26409918?v=4" width="50" /></a> | [monoglo](https://github.com/monoglo) |
| <a href="https://github.com/sakmist"><img src="https://avatars.githubusercontent.com/u/123816165?v=4" width="50" /></a> | [sakmist](https://github.com/sakmist) |


## 后端的部署方法
1. 需要一台支持PHP环境的服务器
2. 把项目除了 `vue` 目录以外的文件部署到网站的目录下
3. 重命名`api`目录里的 `env.exemple.php` 改成 `env.php`
4. 重命名`config`目录里的 `cookie.example.txt` 改成 `cookie.txt` 
5. 然后创建一个B站小号登陆B站, 把账号使用的cookie字符串复制到 `cookie.txt` 文件内
6. 项目的访问入口为api目录里的 `index.php` , 部署完成后就能通过 api路径访问 例子: https://www.abcd/api/index.php

## 前端的部署方法
1. 安装Nodejs+npm
2. 在`vue`目录里打开命令行 运行 `npm install` 安装下载依赖文件
3. 重命名vue目录里的 `.env.example` 改成 `.env`
4. 根据注释 修改 `.env` 文件里的变量数值
5. 运行 `npm run dev` 可以本地调试前端项目
6. 运行  `npm run build` 可以生成 `dist` 目录, 里面包含构建好的前端代码
7. 把 `dist` 目录里的文件部署到前端的服务器

## Docker 部署方法（推荐）

### 前提条件
- 安装 [Docker](https://docs.docker.com/get-docker/) 和 [Docker Compose](https://docs.docker.com/compose/install/)

### 快速开始

1. 克隆项目到本地
   ```bash
   git clone https://github.com/hexie2108/bilibili_dymaic_lottery.git
   cd bilibili_dymaic_lottery
   ```

2. 准备敏感配置文件
   ```bash
   # 从示例文件复制并编辑
   cp docker/config/cookie.example.txt docker/config/cookie.txt
   cp docker/config/env.example.php docker/config/env.php
   # 编辑 cookie.txt 填入B站账号的 SESSDATA
   # 编辑 env.php 按需修改配置
   ```

3. 修改 `docker-compose.yml` 中的环境变量
   ```yaml
   environment:
     - VITE_API_ROOT_URL=https://your-domain.com/api/index.php  # 改为你的实际地址
     - VITE_APP_VERSION=2.5.0
   ```

4. 启动服务
   ```bash
   docker compose up -d
   ```

5. 访问 `http://localhost:8080` 即可使用

### 常用命令
```bash
docker compose up -d          # 后台启动
docker compose down            # 停止服务
docker compose logs -f         # 查看日志
docker compose pull            # 拉取最新镜像
docker compose up -d --force-recreate  # 使用新镜像重建容器
```

### 本地构建镜像
如果不使用 Docker Hub 的预构建镜像，可以本地构建：
```bash
# 修改 docker-compose.yml，注释 image 行，取消注释 build 行
docker compose up -d --build
```

### 环境变量说明

| 变量名 | 说明 | 默认值 |
|---|---|---|
| `VITE_API_ROOT_URL` | 后端 API 完整地址 | `http://localhost/api/index.php` |
| `VITE_BILIBLI_LINK` | B站频道链接 | 空 |
| `VITE_GITHUB_LINK` | GitHub 项目链接 | 空 |
| `VITE_GITHUB_BILIBILI_API_COLLECT_LINK` | B站 API 文档链接 | `https://socialsisteryi.github.io/bilibili-API-collect/` |
| `VITE_APP_VERSION` | 网页显示版本号 | 空 |

### 配置文件说明

| 文件 | 挂载路径 | 说明 |
|---|---|---|
| `docker/config/cookie.txt` | `/var/www/html/config/cookie.txt` | B站账号的 SESSDATA Cookie |
| `docker/config/env.php` | `/var/www/html/api/env.php` | PHP 后端环境配置 |

> 首次启动时，如果未挂载配置文件，容器会自动从示例文件复制。

### GitHub Actions 自动构建

项目配置了 GitHub Actions 工作流，在推送版本标签时自动构建并推送到 Docker Hub。

**使用方式：**
1. 在 GitHub 仓库 Settings → Secrets and variables → Actions 中配置：
   - `DOCKERHUB_USERNAME` — Docker Hub 用户名
   - `DOCKERHUB_TOKEN` — Docker Hub Access Token
2. 推送标签触发自动构建：
   ```bash
   git tag v2.5.0
   git push origin v2.5.0
   ```
3. 构建完成后镜像会推送到 `DOCKERHUB_USERNAME/bilibili_dynamic_lottery`，标签为版本号和 `latest`

> 支持多平台：linux/amd64 和 linux/arm64

## 注意事项
1. 记得手动修改Web服务器软件（Nginx/Apache2）的PHP Fast CGI请求超时时间，不然容易在抓取B站数据的过程中后台返回网关504错误，导致请求被中断 Network response was not ok.
2. 如果有使用PHP-FPM, 也需要修改单个FPM进程允许的最大执行时间 (request_terminate_timeout)， 避免PHP脚本被强行关闭.

