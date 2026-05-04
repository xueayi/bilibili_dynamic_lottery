#!/bin/sh
set -e

echo "[entrypoint] 初始化容器配置..."

# 如果挂载的敏感配置文件不存在，从示例文件复制
if [ ! -f /var/www/html/config/cookie.txt ]; then
    echo "[entrypoint] cookie.txt 不存在，从示例文件复制..."
    cp /var/www/html/config/cookie.example.txt /var/www/html/config/cookie.txt
fi

if [ ! -f /var/www/html/api/env.php ]; then
    echo "[entrypoint] env.php 不存在，从示例文件复制..."
    cp /var/www/html/api/env.example.php /var/www/html/api/env.php
fi

# 替换前端 JS 文件中的环境变量占位符
# Vite 构建时会将 import.meta.env.VITE_* 内联为字符串字面量
# 我们使用占位符值构建，启动时用 sed 替换为实际值
echo "[entrypoint] 注入前端环境变量..."

# 定义需要替换的环境变量列表及默认值
: "${VITE_API_ROOT_URL:=http://localhost/api/index.php}"
: "${VITE_BILIBLI_LINK:=}"
: "${VITE_GITHUB_LINK:=}"
: "${VITE_GITHUB_BILIBILI_API_COLLECT_LINK:=https://socialsisteryi.github.io/bilibili-API-collect/}"
: "${VITE_APP_VERSION:=}"

# 在 dist 目录中的 JS 文件执行占位符替换
JS_FILES=$(find /var/www/html/dist/assets -name '*.js' 2>/dev/null || true)

if [ -n "$JS_FILES" ]; then
    for file in $JS_FILES; do
        sed -i "s|__VITE_API_ROOT_URL__|${VITE_API_ROOT_URL}|g" "$file"
        sed -i "s|__VITE_BILIBLI_LINK__|${VITE_BILIBLI_LINK}|g" "$file"
        sed -i "s|__VITE_GITHUB_LINK__|${VITE_GITHUB_LINK}|g" "$file"
        sed -i "s|__VITE_GITHUB_BILIBILI_API_COLLECT_LINK__|${VITE_GITHUB_BILIBILI_API_COLLECT_LINK}|g" "$file"
        sed -i "s|__VITE_APP_VERSION__|${VITE_APP_VERSION}|g" "$file"
    done
    echo "[entrypoint] 环境变量注入完成"
else
    echo "[entrypoint] 警告: 未找到前端 JS 文件，跳过环境变量注入"
fi

echo "[entrypoint] 启动 PHP-FPM..."
php-fpm -D

echo "[entrypoint] 启动 Nginx..."
nginx -g 'daemon off;'
