ARG NGINX_VERSION=1.27.3
ARG NGINX_FROM_IMAGE=nginx:${NGINX_VERSION}-alpine-slim
FROM ${NGINX_FROM_IMAGE} as builder

ARG NGINX_VERSION=1.27.3
ARG HEADERS_MORE_VERSION=v0.37
ARG NGINX_TO_IMAGE=nginx:${NGINX_VERSION}-alpine-slim

RUN apk update \
 && apk add linux-headers openssl-dev pcre2-dev zlib-dev openssl abuild \
            musl-dev libxslt libxml2-utils make mercurial gcc unzip git \
            xz g++ coreutils curl

RUN cd /opt \
 && git clone --depth 1 -b ${HEADERS_MORE_VERSION} --single-branch https://github.com/openresty/headers-more-nginx-module.git \
 && cd /opt/headers-more-nginx-module \
 && git submodule update --init \
 && cd /opt \
 && wget -O - http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar zxfv - \
 && mv /opt/nginx-${NGINX_VERSION} /opt/nginx \
 && cd /opt/nginx \
 && ./configure --with-compat --add-dynamic-module=/opt/headers-more-nginx-module \
 && make modules 

FROM ${NGINX_FROM_IMAGE}

COPY --from=0 /opt/nginx/objs/ngx_http_headers_more_filter_module.so /usr/lib/nginx/modules

RUN chmod -R 644 /usr/lib/nginx/modules/ngx_http_headers_more_filter_module.so
# && sed -i '1iload_module \/usr\/lib\/nginx\/modules\/ngx_http_headers_more_filter_module.so;' /etc/nginx/nginx.conf

ENV NGINX_PORT 8080
ENV SERVICE_S3_BUCKET localhost
ENV ALLOW_ORIGIN '*'
ENV STRICT_TRANSPORT_SECURITY 'max-age=15552000; includeSubDomains'

RUN apk add --update --no-cache aws-cli shadow sudo bash curl
RUN mkdir /etc/nginx/templates \
 && sed -i '1iload_module \/etc\/nginx\/modules\/ngx_http_headers_more_filter_module.so;' /etc/nginx/nginx.conf
COPY ./config/default.conf.template /etc/nginx/templates/default.conf.template
COPY ./config/nginx.conf /etc/nginx/nginx.conf
RUN chown -R nginx:nginx /etc/nginx
# コンテナのread-only対応
VOLUME /etc/nginx/conf.d
VOLUME /tmp

# ECS SSM Agent
# コンテナのread-only対応
RUN mkdir -p /var/lib/amazon \
 && chmod 750 /var/lib/amazon
RUN mkdir -p /var/log/amazon \
 && chmod 700 /var/log/amazon
VOLUME /var/lib/amazon
VOLUME /var/log/amazon

# 実行ユーザーをnginxに変更
USER nginx

# セキュリティ対策メモ
# https://qiita.com/nigamizawa/items/1cd6a1a73a43a51d2f1c
# https://qiita.com/hoogee/items/7f277a025dee0c5745c5
#