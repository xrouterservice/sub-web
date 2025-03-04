# ---- Dependencies ----
FROM node:16-alpine AS dependencies
WORKDIR /app
COPY package.json ./
RUN yarn install

# ---- Build ----
FROM dependencies AS build
WORKDIR /app
COPY . /app
RUN yarn build

# ARG VERSION_ALPINE=3.16
FROM alpine:3.16
# Create user
RUN adduser -D -u 1000 -g 1000 -s /bin/sh www && \
    mkdir -p /var/www && \
    chown -R www:www /var/www

# Install tini - 'cause zombies - see: https://github.com/ochinchina/supervisord/issues/60
# (also pkill hack)
RUN apk add --no-cache --update tini

# Install a golang port of supervisord
COPY --from=ochinchina/supervisord:latest /usr/local/bin/supervisord /usr/bin/supervisord
#RUN wget https://github.com/tindy2013/subconverter/releases/download/v0.7.2/subconverter_linux64.tar.gz && tar -zxvf subconverter_linux64.tar.gz
#RUN rm /subconverter/pref.*
#COPY ./pref.example.toml /subconverter/
#RUN chmod -R 777 /subconverter
# Create cachedir and fix permissions
RUN apk add --no-cache --update \
    gettext zip unzip git \
    curl ca-certificates \
    nginx && \
    mkdir -p /var/cache/nginx && \
    chown -R www:www /var/cache/nginx && \
    chown -R www:www /var/lib/nginx

COPY ./supervisord.conf /supervisord.conf
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY --from=build /app/dist /usr/share/nginx/html

CMD ["/usr/bin/supervisord","-c","/supervisord.conf"]