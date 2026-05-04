# 阶段1：构建前端
FROM node:20-alpine AS frontend-builder

WORKDIR /app/vue
COPY vue/package.json vue/package-lock.json* ./
RUN npm ci
COPY vue/ ./
# 使用 Docker 占位符环境文件构建，运行时由 entrypoint.sh 替换
RUN cp .env.docker .env && npm run build

# 阶段2：运行时镜像
FROM php:8.2-fpm-alpine

# 安装 Nginx 和 PHP 扩展
RUN apk add --no-cache nginx \
    && docker-php-ext-install curl

# 配置 Nginx
COPY docker/nginx.conf /etc/nginx/http.d/default.conf

# 配置 PHP-FPM
RUN echo "request_terminate_timeout = 10800" >> /usr/local/etc/php-fpm.d/docker.conf \
    && echo "request_slowlog_timeout = 10800" >> /usr/local/etc/php-fpm.d/docker.conf

WORKDIR /var/www/html

# 复制后端代码
COPY api/ ./api/
COPY config/ ./config/

# 复制前端构建产物
COPY --from=frontend-builder /app/vue/dist/ ./dist/

# 复制 Docker 配置文件
COPY docker/ ./docker/

# 设置 entrypoint
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 创建必要目录并设置权限
RUN mkdir -p /var/www/html/config /var/www/html/api \
    && chmod -R 755 /var/www/html

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
