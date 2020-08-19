FROM php:7.4-fpm-alpine

LABEL Maintainer Hieupv <hieupv@codersvn.com>

RUN apk add --no-cache \
    bash \
    libzip-dev \
    oniguruma-dev \
    sqlite-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libxml2-dev \
    bzip2-dev \
    supervisor \
    nano \
    icu-dev \
    nginx \
    zip \
    mysql-client \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    # && docker-php-ext-configure gd --with-freetype-dir=/usr --with-jpeg-dir=/usr --with-png-dir=/usr \
    && docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-install \
    opcache \
    gd \
    mysqli \
    pdo \
    pdo_mysql \
    pdo_sqlite \
    sockets \
    json \
    intl \
    xml \
    zip \
    bz2 \
    pcntl \
    bcmath \
    mbstring \
    exif

# Add Composer
RUN curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="./vendor/bin:$PATH"

COPY ./.docker/php/php.ini $PHP_INI_DIR/conf.d/
ADD ./.docker/supervisor/master.ini /etc/supervisor.d/
ADD ./.docker/nginx/default.conf /etc/nginx/conf.d/

WORKDIR /var/www/app/web

COPY docker-entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["supervisord"]
