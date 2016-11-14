FROM php:7.0-apache
MAINTAINER Jesse Bunch <jesse@getbunch.com>

# Container configuration
ENV APACHE_DOCUMENT_ROOT=/web/public \
    APACHE_SSL_CERT_FILE=/etc/ssl/certs/ssl-cert-snakeoil.pem \
    APACHE_SSL_KEY_FILE=/etc/ssl/private/ssl-cert-snakeoil.key \
    XDEBUG_ENABLED=0 \
    XDEBUG_REMOTE_ENABLE=0 \
    XDEBUG_REMOTE_AUTOSTART=0 \
    XDEBUG_REMOTE_CONNECT_BACK=0 \
    XDEBUG_REMOTE_HOST=localhost \
    XDEBUG_IDEKEY=docker \
    PHP_OPCACHE_ENABLED=1 \
    PHP_MEMORY_LIMIT=16M \
    PHP_POST_MAX_SIZE=32M \
    PHP_UPLOAD_MAX_FILESIZE=16M

# Fixes issues with docker exec
# See https://github.com/dockerfile/mariadb/issues/3
RUN echo "export TERM=xterm" >> ~/.bashrc

# Default site is phpinfo()
RUN rm -rf /var/www \
    && mkdir -p /web/public \
    && chown -R www-data.www-data /web/public \
    && echo "<?php phpinfo();" > /web/public/index.php

# Generate SSL cert
RUN cd /tmp \
    && openssl genrsa -des3 -passout pass:x -out snakeoil.pass.key 2048 \
    && openssl rsa -passin pass:x -in snakeoil.pass.key -out snakeoil.key \
    && openssl req -new -subj "/C=US/ST=California/L=San Francisco/O=Dis/CN=localhost" -key snakeoil.key -out snakeoil.csr \
    && openssl x509 -req -days 365 -in snakeoil.csr -signkey snakeoil.key -out snakeoil.pem \
    && mv ./snakeoil.key /etc/ssl/private/ssl-cert-snakeoil.key \
    && mv ./snakeoil.pem /etc/ssl/certs/ssl-cert-snakeoil.pem \
    && rm -rf /tmp/*

# Update
RUN apt-get update 

# PHP Extensions
RUN apt-get install -y \
       libfreetype6-dev \
       libjpeg62-turbo-dev \
       libmcrypt-dev \
       libpng12-dev \
       libzip-dev \
       git \
    && docker-php-ext-install -j$(nproc) iconv mcrypt zip mysqli pdo pdo_mysql json exif \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer global require "hirak/prestissimo:^0.3"

# Xdebug
RUN cd /tmp \
    && curl -o xdebug-2.5.0RC1.tgz https://xdebug.org/files/xdebug-2.5.0RC1.tgz \
    && tar -xvzf xdebug-2.5.0RC1.tgz \
    && cd xdebug-2.5.0RC1 \
    && phpize \
    && ./configure \
    && make \
    && mv modules/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-20151012/

# NodeJS
RUN curl -sL https://deb.nodesource.com/setup_7.x | bash - \
    && apt-get install -y nodejs build-essential \
    && npm install -g parallelshell

# Ruby and SASS
RUN apt-get install -y rubygems \
    && gem install sass sass-globbing

# Working directory
WORKDIR /web/public

# Configure Apache
COPY ./apache-docker.conf /etc/apache2/sites-available/docker.conf
RUN a2enmod actions ssl rewrite headers \
    && a2dissite 000-default default-ssl \ 
    && a2ensite docker

# Configure PHP
COPY /php-conf.d /usr/local/etc/php/conf.d

# Run
COPY /docker-entrypoint.sh /docker-entrypoint.sh
COPY /docker-entrypoint.d /docker-entrypoint.d
RUN chmod +x /docker-entrypoint.sh /docker-entrypoint.d/*
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["apache2-foreground"]