FROM php:7.2-apache

# install the PHP extensions we need
RUN apt-get update && apt-get install -y dos2unix git && set -eux; \
    docker-php-ext-install -j "$(nproc)" opcache pdo_mysql mysqli

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=60'; \
        echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN a2enmod rewrite expires

ENV YOURLS_VERSION 1.7.6
ENV YOURLS_SHA256 f3623af6e4cabee61a39d3deca3c941717c5e0a60bc288b6f3a668f87a20ae2e

RUN set -eux; \
    curl -o yourls.tar.gz -fsSL "https://github.com/YOURLS/YOURLS/archive/${YOURLS_VERSION}.tar.gz"; \
    echo "$YOURLS_SHA256 *yourls.tar.gz" | sha256sum -c -; \
# upstream tarballs include ./YOURLS-${YOURLS_VERSION}/ so this gives us /usr/src/YOURLS-${YOURLS_VERSION}
    tar -xf yourls.tar.gz -C /usr/src/; \
# move back to a common /usr/src/yourls
    mv "/usr/src/YOURLS-${YOURLS_VERSION}" /usr/src/yourls; \
    rm yourls.tar.gz; \
    mkdir /usr/src/yourls/plugins;\
    git clone https://github.com/k3a/yourls-ldap-plugin.git && mv yourls-ldap-plugin /usr/src/yourls/plugins/yourls-ldap-plugin; \
    chown -R www-data:www-data /usr/src/yourls

COPY docker-entrypoint.sh /usr/local/bin/
COPY config-docker.php /usr/src/yourls/user/
COPY .htaccess /usr/src/yourls/
RUN dos2unix /usr/local/bin/docker-entrypoint.sh && dos2unix /usr/src/yourls/user/config-docker.php && dos2unix /usr/src/yourls/.htaccess && apt-get autoremove -y
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]