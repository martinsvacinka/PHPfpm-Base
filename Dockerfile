# https://hub.docker.com/_/php/tags?page=1&name=fpm-bullseye
FROM php:8.1.10-fpm-bullseye

LABEL org.opencontainers.image.source https://github.com/Container-Driven-Development/PHPfpm-Base
LABEL org.opencontainers.image.description "Base image for PHPfpm server"

WORKDIR /srv
ENV NETTE_ENV "prod"
ARG APP_VERSION
ENV APP_VERSION $APP_VERSION
ARG PHP_ENV=production
ENV TZ "Europe/Prague"

RUN curl -o /usr/local/bin/composer https://getcomposer.org/download/2.6.5/composer.phar && \
    chmod +x /usr/local/bin/composer

COPY --from=node:21.2.0-bullseye-slim /usr/local/bin/node /usr/local/bin/

RUN apt-get update && apt-get install -y \
  libfcgi-bin \
  iputils-ping \
  dnsutils \
  locales \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN echo -e "export LC_ALL=cs_CZ.UTF-8\nexport LANG=cs_CZ.UTF-8\nexport LANGUAGE=cs_CZ.UTF-8" >> /root/.bashrc
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# cs_CZ.UTF-8 UTF-8/cs_CZ.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="cs_CZ.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=cs_CZ.UTF-8

RUN set -xe && echo "pm.status_path = /status" >> /usr/local/etc/php-fpm.d/zz-docker.conf
COPY php-fpm-healthcheck.sh /usr/local/bin/

RUN set -xe && echo "pm.max_children = 11" >> /usr/local/etc/php-fpm.d/zz-docker.conf

RUN mv "$PHP_INI_DIR/php.ini-${PHP_ENV}" "$PHP_INI_DIR/php.ini"
COPY app.ini $PHP_INI_DIR/conf.d/app.ini

# https://hub.docker.com/r/mlocati/php-extension-installer/tags
COPY --from=mlocati/php-extension-installer:1.5.37 /usr/bin/install-php-extensions /usr/local/bin/

# See https://github.com/mlocati/docker-php-extension-installer
# Always use exact version to avoid mystery issues on lib upgrade
# Run this for getting installed extension version
#   php -r 'foreach (get_loaded_extensions() as $extension) echo "$extension: " . phpversion($extension) . "\n";'
RUN install-php-extensions pdo-8.1.10 pdo_mysql-8.1.10 intl-8.1.10 redis-5.3.7 mysqli-8.1.10 opcache-8.1.10 gd-2.1.0
# RUN install-php-extensions pdo pdo_mysql intl redis mysqli opcache

RUN mkdir -p /srv/var/log && \
      mkdir -p /srv/var/tmp/cache && \
      chmod -R 777 /srv/var && \
      chown -R www-data:www-data /srv/var && \
      mkdir -p /srv/log && \
      chmod -R 777 /srv/log && \
      chown -R www-data:www-data /srv/log
