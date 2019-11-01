FROM node:11-alpine AS builder

RUN apk add --no-cache --virtual .tmp_packages git python make g++

WORKDIR /var/www/app

COPY public ./public
COPY package*.json yarn*.lock webpack* .babelrc ./

RUN sed -i '/\@vicoders\/generator/d' ./package.json

RUN yarn install 

RUN yarn prod && apk del .tmp_packages

FROM php:7.1-fpm-alpine

LABEL Maintainer Hieupv <hieupv@codersvn.com>

RUN apk add --no-cache --virtual .tmp_packages git && apk add --no-cache bash curl \
    && curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer 

ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="./vendor/bin:$PATH"

# Setup Working Dir
WORKDIR /var/www/app

COPY . ./

RUN cat .env.prod > .env && composer install && apk del .tmp_packages

COPY --from=builder /var/www/app/public/dist ./public/dist

EXPOSE 8080

CMD ["php","-S","0.0.0.0:8080", "-t", "public"]
