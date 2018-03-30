FROM jubicoy/nginx-php:php7-stable

RUN  apt-get update \
  && apt-get -y install \
    apache2-utils \
    curl \
    git \
    gzip \
    jq \
    mysql-client \
    netcat \
    php-imagick \
    php-memcache \
    php-pear \
    php-redis \
    php7.0-cli \
    php7.0-common \
    php7.0-curl \
    php7.0-dev \
    php7.0-fpm \
    php7.0-gd \
    php7.0-imap \
    php7.0-json \
    php7.0-mbstring \
    php7.0-mcrypt \
    php7.0-mysql \
    php7.0-pgsql \
    php7.0-sqlite \
    php7.0-zip \
    wget \
    wkhtmltopdf \
  && rm -rf /var/lib/apt/lists/*

ENV COMPOSER_VERSION 1.6.3
ENV SABRE_VERSION ~3.1.0
ENV DRUSH_VERSION 8.1.16

# Install Drupal, Composer, Sabre and Drush
RUN  rm -rf /var/www/* \
  && curl -k https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION:-8.4.5}.tar.gz | tar zx -C /var/www/ \
  && mv /var/www/drupal-${DRUPAL_VERSION:-8.4.5} /var/www/drupal \
  && cp -rf /var/www/drupal/sites/default /tmp/ \
  && /usr/libexec/fix-permissions /tmp/ \
  && cp -f /var/www/drupal/robots.txt /workdir/ \
  && rm -rf /var/www/drupal/themes/ \
  && rm -rf /var/www/drupal/modules/ \
  && rm -rf /var/www/drupal/robots.txt \
  && rm -rf /var/www/drupal/sites/default \
  && mv /var/www/drupal/vendor /workdir/vendor-seed \
  && mv /var/www/drupal/composer.lock /workdir/composer.lock.drupal

# Install Composer & Sabre
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version="${COMPOSER_VERSION}" \
  &&  mkdir -p /var/www/webdav/locks \
  && chmod -R 777 /var/www/webdav/locks \
  && cd /var/www/webdav \
  && composer require sabre/dav "${SABRE_VERSION}" \
  && composer update sabre/dav \
  && cd

# Install Drush
RUN  curl -SL https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar -o /usr/local/bin/drush \
  && chmod +x /usr/local/bin/drush \
  && yes | drush init

# Install latest APCu module
RUN mkdir -p /tmp/apcu-build \
  && cd /tmp/apcu-build \
  && git clone https://github.com/krakjoe/apcu \
  && cd apcu \
  && git checkout v5.1.9 \
  && phpize7.0 \
  && ./configure --with-php-config=/usr/bin/php-config7.0 \
  && make \
  && TEST_PHP_ARGS='-n' make test \
  && make install \
  && cd \
  && rm -rf /tmp/apcu-build

# Install jsmin php extension
RUN  git clone -b feature/php7 https://github.com/sqmk/pecl-jsmin.git /workdir/pecl-jsmin \
  && cd /workdir/pecl-jsmin \
    && phpize \
    && ./configure \
    && make install clean \
  && cd \
  && touch /etc/php/7.0/cli/conf.d/20-jsmin.ini \
  && echo 'extension="jsmin.so"' >> /etc/php/7.0/cli/conf.d/20-jsmin.ini \
  && echo 'extension="jsmin.so"' >> /tmp/php.ini

COPY root /

# Link & patch configuration files
# Additional CA certificate bundle (Mozilla)
RUN  rm -rf /etc/nginx/conf.d/default.conf \
  && ln -s /volume/conf/default.conf /etc/nginx/conf.d/default.conf \
  && mv /etc/php/7.0/fpm/php.ini /tmp/php.ini \
  && /usr/libexec/fix-permissions /workdir \
  && mkdir /volume \
  && /usr/libexec/fix-permissions /volume \
  && ln -s /volume/themes/ /var/www/drupal/themes \
  && ln -s /volume/modules/ /var/www/drupal/modules \
  && ln -s /volume/default/ /var/www/drupal/sites/default \
  && ln -s /volume/libraries/ /var/www/drupal/libraries \
  && ln -s /volume/vendor /var/www/drupal/vendor \
  && ln -s /volume/composer.lock.drupal /var/www/drupal/composer.lock \
  && ln -s /volume/robots.txt /var/www/drupal/robots.txt \
  && ln -s /volume/conf/php.ini /etc/php/7.0/fpm/php.ini \
  && cat /var/www/drupal/composer.json \
    | jq -r '.extra["merge-plugin"].include = .extra["merge-plugin"].include + ["modules/*/composer.json", "/volume/composer.json"]' \
    > /var/www/drupal/composer.json.tmp \
    && mv /var/www/drupal/composer.json.tmp /var/www/drupal/composer.json \
  && bash /workdir/mailchimp-ca.sh \
  && update-ca-certificates \
  && sed -i '/upload_max_filesize/c\upload_max_filesize = 250M' /tmp/php.ini \
  && sed -i '/post_max_size/c\post_max_size = 250M' /tmp/php.ini

VOLUME ["/volume"]

EXPOSE 5000
EXPOSE 5005

USER 100104

CMD ["/opt/bin/start-cmd"]
