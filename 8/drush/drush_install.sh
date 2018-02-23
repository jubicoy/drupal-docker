#!/bin/bash
wget https://github.com/drush-ops/drush/releases/download/8.1.16/drush.phar
chmod +x drush.phar
mv drush.phar /usr/local/bin/drush

yes | drush init
