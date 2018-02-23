#!/bin/bash
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < /workdir/passwd.template > /tmp/passwd
export LD_PRELOAD=libnss_wrapper.so
export NSS_WRAPPER_PASSWD=/tmp/passwd
export NSS_WRAPPER_GROUP=/etc/group

if [ ! -d /volume/themes ]; then
  mkdir -p /volume/themes
fi

if [ ! -d /volume/modules ]; then
  mkdir -p /volume/modules
fi

if [ ! -d /volume/libraries ]; then
  mkdir -p /volume/libraries
fi

if [ ! -f /var/www/drupal/robots.txt ]; then
  mv -f /workdir/robots.txt /volume/robots.txt
fi

if [ ! -d /var/www/drupal/sites/default ]; then
  # Copy initial sites and configuration
  cp -arf /tmp/sites/* /var/www/drupal/sites/
  cp /var/www/drupal/sites/example.settings.local.php /var/www/drupal/sites/default/settings.local.php

  echo "Copying development.services.yml"
  # Download modules
  IFS=';' read -r -a modules <<< "$DRUPAL_MODULES"
  for module in "${modules[@]}"
  do
    echo "Downloading module $module"
    drush dl $module -y --destination=/var/www/drupal/modules/
  done
  # Download themes
  IFS=';' read -r -a themes <<< "$DRUPAL_THEMES"
  for theme in "${themes[@]}"
  do
    echo "Downloading theme $theme"
    drush dl $theme -y --destination=/var/www/drupal/themes/
  done
else
  # Run updatedb with drush
  echo "Running drush updb"
  (cd /var/www/drupal/; drush updb -y)
  # Apply pending entity schema updates
  echo "Running drush entup"
  (cd /var/www/drupal/; drush entup -y)
  echo "Running drush cr"
  (cd /var/www/drupal; drush cr)
fi

if [ ! -d /volume/default ]; then
  cp -rf /tmp/default/ /volume/
  cp /workdir/drupal-config/services.yml /volume/default/services.yml
  cp /volume/default/default.settings.php /volume/default/settings.php
  # Trust all hosts
  echo "\$settings['trusted_host_patterns'] = array('.*',);" >> /volume/default/settings.php
fi

chmod -R 774 /volume/default/

# Move Nginx configuration if does not exist
if [ ! -f /volume/conf/default.conf ]; then
# Move Nginx configuration to volume
  mkdir -p /volume/conf/
  mv /workdir/default.conf /volume/conf/default.conf
fi

if [ ! -f /volume/conf/php.ini ]; then
  mv /tmp/php.ini /volume/conf/php.ini
fi

if [ ! -f /tmp/dav_auth ]; then
  # Create WebDAV Basic auth user
  echo ${DAV_PASS}|htpasswd -i -c /tmp/dav_auth ${DAV_USER}
fi

# Disable Drupal8 twig cache
rm -rf /workdir/drupal-config


exec "/usr/bin/supervisord"
