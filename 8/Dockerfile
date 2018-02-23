FROM jubicoy/nginx-php:php7
ENV DRUPAL_VERSION 8.4.5

RUN apt-get update && \
    apt-get -y install php7.0-fpm php-apcu php7.0-mysql \
    php-imagick php7.0-imap php7.0-mcrypt php7.0-curl php7.0-dev \
    php7.0-cli php7.0-gd php7.0-pgsql php7.0-sqlite php7.0-zip \
    php7.0-common php-pear curl php7.0-json php-redis php-memcache php7.0-mbstring \
    gzip netcat mysql-client wget git apache2-utils && \
    rm -rf /var/lib/apt/lists/*

RUN curl -k https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz | tar zx -C /var/www/
RUN mv /var/www/drupal-${DRUPAL_VERSION} /var/www/drupal
RUN cp -rf /var/www/drupal/sites/default /tmp/
RUN cp -f /var/www/drupal/robots.txt /workdir/

# Composer for Sabre installation
ENV COMPOSER_VERSION 1.4.1
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION}

# WebDAV configuration
#RUN apt-get install -y apache2-utils
RUN mkdir -p /var/www/webdav && mkdir -p /var/www/webdav/locks && chmod -R 777 /var/www/webdav/locks
ADD config/webdav.conf /etc/nginx/conf.d/webdav.conf
ADD sabre/index.php /var/www/webdav/index.php

# Sabre with composer
RUN cd /var/www/webdav && composer require sabre/dav ~3.1.0 && composer update sabre/dav && cd

# Add configuration files
ADD config/default.conf /workdir/default.conf
RUN rm -rf /etc/nginx/conf.d/default.conf && ln -s /volume/conf/default.conf /etc/nginx/conf.d/default.conf
RUN mv /etc/php/7.0/fpm/php.ini /tmp/php.ini

RUN mkdir /workdir/drupal-config && chmod 777 /workdir/drupal-config
ADD config/drupal-cache-config/* /workdir/drupal-config/

RUN mkdir /volume && chmod 777 /volume
RUN rm -rf /var/www/drupal/themes/ && rm -rf /var/www/drupal/modules/ && rm -rf /var/www/drupal/sites/default
RUN ln -s /volume/themes/ /var/www/drupal/themes
RUN ln -s /volume/modules/ /var/www/drupal/modules
RUN ln -s /volume/default/ /var/www/drupal/sites/default
RUN ln -s /volume/libraries/ /var/www/drupal/libraries
RUN rm -rf /var/www/drupal/robots.txt && ln -s /volume/robots.txt /var/www/drupal/robots.txt
RUN ln -s /volume/conf/php.ini /etc/php/7.0/fpm/php.ini

ADD config/nginx.conf /etc/nginx/nginx.conf


VOLUME ["/volume"]

# Additional CA certificate bundle (Mozilla)
ADD mailchimp-ca.sh /workdir/mailchimp-ca.sh
RUN chmod a+x /workdir/mailchimp-ca.sh && bash /workdir/mailchimp-ca.sh
RUN update-ca-certificates

# Install drush
ADD drush/drush_install.sh /workdir/drush_install.sh
RUN chmod a+x /workdir/drush_install.sh && bash /workdir/drush_install.sh

# Install jsmin php extension
RUN git clone -b feature/php7 https://github.com/sqmk/pecl-jsmin.git /workdir/pecl-jsmin
RUN (cd /workdir/pecl-jsmin && phpize && ./configure && make install clean)
RUN touch /etc/php/7.0/cli/conf.d/20-jsmin.ini && echo 'extension="jsmin.so"' >> /etc/php/7.0/cli/conf.d/20-jsmin.ini
RUN echo 'extension="jsmin.so"' >> /tmp/php.ini

# PHP max upload size
RUN sed -i '/upload_max_filesize/c\upload_max_filesize = 250M' /tmp/php.ini
RUN sed -i '/post_max_size/c\post_max_size = 250M' /tmp/php.ini

ADD entrypoint.sh /workdir/entrypoint.sh
RUN chown -R 104:0 /var/www && chmod -R g+rw /var/www && \
    chmod a+x /workdir/entrypoint.sh && chmod g+rw /workdir

EXPOSE 5000
EXPOSE 5005

USER 100104
