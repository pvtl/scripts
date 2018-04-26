#!/usr/bin/env bash

#
#
# Installs Wordpress "the Pivotal Way"
#
# Simply run the following from your CLI:
# `bash <(curl -s https://gist.githubusercontent.com/mcnamee/3360ef8af8904f0bc38489b4b3a902f1/raw/install-wp.sh -L)`
#
# You get Wordpress Bedrock, the Pivotal Theme, a set of default plugins, database created,
# Wordpress installed, a Readme with nice instructions and a better .gitignore
#
# Prereq's: Composer, Git, Unix, WP-cli, NPM
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# @copyright Copyright (c) 2018 by Pivotal Agency
# @license   http://www.gnu.org/licenses/
#
#

# Config
# ---------------------------------------------
echo "•• We'll create a new directory for the project. What shall we call it? (eg. wordpress)"
read DIR_NAME

DIR_NAME=$(echo $DIR_NAME | tr -cd '[[:alnum:]].')
DIR_NAME=`echo "$DIR_NAME" | tr '[:upper:]' '[:lower:]'`
URL="http://${DIR_NAME}.pub.localhost"
DB_HOST="db"
DB_USER="root"
DB_PW="dbroot"
WP_USER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
WP_PW=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
WP_EMAIL="tech@pvtl.io"

# Create the directory
# ---------------------------------------------
mkdir $DIR_NAME && cd $DIR_NAME
SITE_ROOT="$(pwd)"

# Down the latest@Bedrock
# ---------------------------------------------
git clone https://github.com/roots/bedrock.git .

# Install Dependencies
# ---------------------------------------------
composer install --ignore-platform-reqs

# Install default Wordpress plugins
# ---------------------------------------------
composer require wpackagist-plugin/wordpress-seo
composer require wpackagist-plugin/w3-total-cache
composer require wpackagist-plugin/wp-migrate-db

git clone https://github.com/hoppinger/advanced-custom-fields-wpcli.git web/app/plugins/advanced-custom-fields-wpcli
rm -rf web/app/plugins/advanced-custom-fields-wpcli/.git
git clone https://github.com/wp-premium/advanced-custom-fields-pro.git web/app/plugins/advanced-custom-fields-pro
rm -rf web/app/plugins/advanced-custom-fields-pro/.git

# Install our theme
# ---------------------------------------------
git clone https://bitbucket.org/pvtl/wordpress-theme-boilerplate.git web/app/themes/pvtl
cd web/app/themes/pvtl
rm -rf .git
npm install
npm run build

cd $SITE_ROOT

# Create a Symlink for our LDE's
# ---------------------------------------------
ln -s web public

# Create the .env file and setup DB connection
# ---------------------------------------------
cp .env.example .env
sed -i 's/database_name/'"$DIR_NAME"'/g' .env
sed -i 's/database_user/'"$DB_USER"'/g' .env
sed -i 's/database_password/'"$DB_PW"'\nDB_HOST='"$DB_HOST"'/g' .env
sed -i 's,http://example.com,'"$URL"',g' .env

# Create a Database
# ---------------------------------------------
php -r '
$host = $argv[1];
$user = $argv[2];
$pw = $argv[3];
$name = $argv[4];

$conn = mysqli_connect($host, $user, $pw);
mysqli_query($conn, "CREATE DATABASE " . $name);
' $DB_HOST $DB_USER $DB_PW $DIR_NAME

# Install Wordpress
# ---------------------------------------------
wp core install \
  --url="${URL}" \
  --title="${DIR_NAME}" \
  --admin_user="${WP_USER}" \
  --admin_password="${WP_PW}" \
  --admin_email="${WP_EMAIL}" \
  --skip-email \
  --allow-root

# Set Wordpress config & activate theme/plugins
# ---------------------------------------------
# URL structure
wp rewrite structure /%category%/%postname%/ --allow-root
wp rewrite flush --allow-root

# Active theme and plugins
wp theme activate pvtl --allow-root
wp plugin activate advanced-custom-fields-wpcli --allow-root
wp plugin activate advanced-custom-fields-pro --allow-root
wp plugin activate wordpress-seo --allow-root

# Setup Pages - home to be home page
wp post create --post_type=page --post_title='Home' --post_date='2017-12-01 07:00:00' --post_status='publish' --allow-root
wp post create --post_type=page --post_title='Blog' --post_date='2017-12-01 07:00:00' --post_status='publish' --allow-root
wp option update show_on_front 'page' --allow-root
wp option update page_on_front 3 --allow-root
wp option update page_for_posts 4 --allow-root

# Create a couple of menus for the theme
wp menu create "Main Menu" --allow-root
wp menu create "Footer Menu" --allow-root
wp menu location assign main-menu top-bar-r --allow-root
wp menu location assign main-menu mobile-nav --allow-root
wp menu item add-post main-menu 3 --allow-root
wp menu item add-post main-menu 4 --allow-root
wp menu item add-post main-menu 2 --allow-root
wp menu item add-post footer-menu 3 --allow-root
wp menu item add-post footer-menu 4 --allow-root
wp menu item add-post footer-menu 2 --allow-root

# Timezone
wp option update timezone_string Australia/Brisbane --allow-root

# Import our ACF fields for the theme
wp acf import --json_file=web/app/themes/pvtl/acf-fields.json --allow-root

# Remove ACF CLI plugin - we don't need it anymore
wp plugin deactivate advanced-custom-fields-wpcli --allow-root
rm -rf web/app/plugins/advanced-custom-fields-wpcli

# Add the following to the .gitignore
# ---------------------------------------------
echo '
# Generic
.DS_Store
.DS_STORE
*.log
error_log
error_log_dev

# W3Total Cache
web/app/cache
web/app/w3tc-config
web/app/db.php
web/app/advanced-cache.php
web/app/object-cache.php

# Include these plugins
!web/app/plugins/advanced-custom-fields-pro
' >> .gitignore

# Update the Readme
# ---------------------------------------------
rm README.md
cat << 'EOF' >> README.md
# A Wordpress site by Pivotal Agency

## Installation

- Clone this repo
- Copy `.env.example` to `.env` and add your environment's settings
- Import the DB (and update `siteurl` and `home` in the `wp_options` table)
- Run `composer install` from the project root

### Local development

Working with our Docker LDE, you'll need the following extras:

- You'll need `DB_HOST=db` in your `.env`
- You'll need to create a symlink of `/public` to `/web` (`ln -s web public`)
- Your Hostname will need to be {website}__.pub.localhost__ (note the `.pub`)

---

## Wordpress Plugins

Wordpress Plugins are managed through composer.

### Installing

- Visit [WP Packagist](https://wpackagist.org/)
- Find the plugin (eg. akismet)
- Copy the packagist name (eg. `wpackagist-plugin/plugin-name`) and run `composer require wpackagist-plugin/plugin-name`

### Updating

Simply update the plugin's version number (to the desired version) in `composer.json` and run `composer update`.

### Removing

Simply run `composer remove wpackagist-plugin/plugin-name`
EOF

# Output the login details
# ---------------------------------------------
echo " "
echo "- - - - - - - - - - - - - -"
echo "Wordpress has been installed at: ${URL}"
echo "- - -"
echo "Login to Wordpress at: ${URL}/wp/wp-admin"
echo "Your Wordpress username is: ${WP_USER}"
echo "Your Wordpress password is: ${WP_PW}"
echo "- - -"
echo "The site is located in: ${SITE_ROOT}"
echo "The site is using database: ${DIR_NAME}"
echo "- - - - - - - - - - - - - -"
