FROM php:7.4-fpm-alpine

LABEL Maintainer Hieupv <hieupv@codersvn.com>

RUN apk add --no-cache \
    nginx \
    zip \
    nano \
    mysql-client \
    supervisor \
    # in theory, docker-entrypoint.sh is POSIX-compliant, but priority is a working, consistent image
    bash \
    # BusyBox sed is not sufficient for some of our sed expressions
    sed \
    # Ghostscript is required for rendering PDF previews
    ghostscript \
    # Alpine package for "imagemagick" contains ~120 .so files, see: https://github.com/docker-library/wordpress/pull/497
    imagemagick

# install the PHP extensions we need (https://make.wordpress.org/hosting/handbook/handbook/server-environment/#php-extensions)
RUN set -ex; \
    \
    apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    freetype-dev \
    imagemagick-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libzip-dev \
    libxml2-dev \
    bzip2-dev \
    oniguruma-dev \
    sqlite-dev \
    icu-dev \
    ; \
    \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j "$(nproc)" \
    bcmath \
    exif \
    gd \
    mysqli \
    pdo \
    pdo_mysql \
    pdo_sqlite \
    zip \
    xml \
    sockets \
    json \
    intl \
    bz2 \
    pcntl \
    mbstring \
    ; \
    pecl install imagick-3.4.4; \
    docker-php-ext-enable imagick; \
    \
    runDeps="$( \
    scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
    | tr ',' '\n' \
    | sort -u \
    | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --virtual .wordpress-phpexts-rundeps $runDeps; \
    apk del .build-deps

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN set -eux; \
    docker-php-ext-enable opcache; \
    { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini
RUN { \
    echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
    echo 'display_errors = Off'; \
    echo 'display_startup_errors = Off'; \
    echo 'log_errors = On'; \
    echo 'error_log = /dev/stderr'; \
    echo 'log_errors_max_len = 1024'; \
    echo 'ignore_repeated_errors = On'; \
    echo 'ignore_repeated_source = Off'; \
    echo 'html_errors = Off'; \
    } > /usr/local/etc/php/conf.d/error-logging.ini

RUN { \
    echo 'upload_max_filesize = 200M'; \
    echo 'max_file_uploads = 20'; \
    echo 'post_max_size = 200M'; \
    } > /usr/local/etc/php/conf.d/upload-max-size.ini

# Add Composer
RUN curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="./vendor/bin:$PATH"

ADD ./.docker/supervisor/master.ini /etc/supervisor.d/
COPY ./.docker/nginx/default.conf /etc/nginx/conf.d/

WORKDIR /var/www

COPY docker-entrypoint.sh /usr/bin/

RUN chmod +x /usr/bin/docker-entrypoint.sh

RUN mkdir -p /run/nginx

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["supervisord"]
