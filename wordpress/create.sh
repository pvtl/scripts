#!/usr/bin/env bash

#
#
# Installs Wordpress "the Pivotal Way"
#
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

# Variables
# ---------------------------------------------
RESET="\e[39m"
BLUE="\e[34m"


# Site Config
# ---------------------------------------------
# DB Details
DB_HOST="db"
DB_USER="root"
DB_PW="dbroot"
RAND=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
RAND_EMAIL="${RAND}@${RAND}.com"
WP_PW=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

# Git Repo
# echo -e "${BLUE}\n?? If you'd like to commit the repo straight to Git, input the repo's Git URL (otherwise leave it blank to NOT push to git): ${RESET}"
# read -p "== " GIT_URL
# if [[ -z "$GIT_URL" ]]; then
#   GIT_URL=0
# fi

# Directory/DB Name
echo -e "${BLUE}\n?? We'll create a new directory & DB for the project. What shall we call them? [wordpress${RAND}] ${RESET}"
read -p "== " DIR_NAME
if [[ -z "$DIR_NAME" ]]; then
  DIR_NAME="wordpress${RAND}"
fi

DIR_NAME=$(echo $DIR_NAME | tr -cd '[[:alnum:]].')
DIR_NAME=`echo "$DIR_NAME" | tr '[:upper:]' '[:lower:]'`

URL="http://${DIR_NAME}.pub.localhost"

# Install Pivotal Theme?
echo -e "${BLUE}\n?? Would you like the Pivotal theme installed? [y/n] ${RESET}"
read -p "== " INSTALL_THEME
if [ "$INSTALL_THEME" != "${INSTALL_THEME#[Yy]}" ] ;then
    INSTALL_THEME=1
else
    INSTALL_THEME=0
fi

# Wordpress Username
echo -e "${BLUE}\n?? Please enter the Wordpress Admin username: [user${RAND}] ${RESET}"
read -p "== " WP_USER

WP_USER=$(echo $WP_USER | tr -cd '[[:alnum:]].')
WP_USER=`echo "$WP_USER" | tr '[:upper:]' '[:lower:]'`
if [[ -z "$WP_USER" ]]; then
  WP_USER="user${RAND}"
fi

# Wordpress Email
echo -e "${BLUE}\n?? Please enter an Email for the Wordpress admin: [${RAND_EMAIL}] ${RESET}"
read -p "== " WP_EMAIL
if [[ -z "$WP_EMAIL" ]]; then
  WP_EMAIL="${RAND_EMAIL}"
fi

EMAIL_FORMAT="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"

if [[ ${WP_EMAIL} =~ ${EMAIL_FORMAT} ]] ; then
  echo -e "Great, here we go...\n---\n"
else
  echo "Please enter a real email..."
  exit 1
fi


# Create the directory
# ---------------------------------------------
mkdir $DIR_NAME && cd $DIR_NAME
SITE_ROOT="$(pwd)"


# Down the latest@Bedrock
# ---------------------------------------------
git clone https://github.com/roots/bedrock.git .
rm -rf .git
rm -rf .github


# Install Dependencies
# ---------------------------------------------
composer install --ignore-platform-reqs


# Create a Symlink for our LDE's
# ---------------------------------------------
ln -s web public


# Install default Wordpress plugins
# ---------------------------------------------
composer require wpackagist-plugin/wordpress-seo
composer require wpackagist-plugin/w3-total-cache
composer require wpackagist-plugin/wp-migrate-db
composer require wpackagist-plugin/admin-menu-editor
composer require wpackagist-plugin/better-wp-security

git clone https://github.com/wp-premium/advanced-custom-fields-pro.git web/app/plugins/advanced-custom-fields-pro
rm -rf web/app/plugins/advanced-custom-fields-pro/.git
git clone https://github.com/wp-premium/gravityforms.git web/app/plugins/gravityforms
rm -rf web/app/plugins/gravityforms/.git
git clone https://github.com/wp-premium/gravityformscampaignmonitor.git web/app/plugins/gravityformscampaignmonitor
rm -rf web/app/plugins/gravityformscampaignmonitor/.git


# Create a Database
# ---------------------------------------------
php -r '
$conn = mysqli_connect($argv[1], $argv[2], $argv[3]);
mysqli_query($conn, "CREATE DATABASE " . $argv[4] . " CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
' $DB_HOST $DB_USER $DB_PW $DIR_NAME


# Create the .env file and setup DB connection
# ---------------------------------------------
cp .env.example .env
sed -i 's/database_name/'"$DIR_NAME"'/g' .env
sed -i 's/database_user/'"$DB_USER"'/g' .env
sed -i 's/database_password/'"$DB_PW"'\nDB_HOST='"$DB_HOST"'/g' .env
sed -i 's,http://example.com,'"$URL"',g' .env


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


# Set Wordpress config & activate plugins
# ---------------------------------------------
# URL structure
wp rewrite structure /%category%/%postname%/ --allow-root
wp rewrite flush --allow-root

# Active theme and plugins
wp plugin activate advanced-custom-fields-pro --allow-root
wp plugin activate gravityforms --allow-root
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
wp menu item add-post main-menu 3 --allow-root
wp menu item add-post main-menu 4 --allow-root
wp menu item add-post main-menu 2 --allow-root
wp menu item add-post footer-menu 3 --allow-root
wp menu item add-post footer-menu 4 --allow-root
wp menu item add-post footer-menu 2 --allow-root

# Timezone
wp option update timezone_string Australia/Brisbane --allow-root


# Install the Pivotal theme
# ---------------------------------------------
if [[ ${INSTALL_THEME} == 1 ]] ; then
  git clone https://bitbucket.org/pvtl/wordpress-theme-boilerplate.git web/app/themes/pvtl
  cd web/app/themes/pvtl
  rm -rf .git

  # Build assets
  npm install
  npm run build

  # Setup for local dev
  cp config-default.yml config.yml
  sed -i 's,url: "",url: "'"$URL"'",g' config.yml

  cd $SITE_ROOT

  # Activate Theme
  wp theme activate pvtl --allow-root

  # Assign header and footer menus to theme menu locations
  wp menu location assign main-menu top-bar-r --allow-root
  wp menu location assign main-menu mobile-nav --allow-root

  # Install ACF CLI (to enable us to install some default fields)
  git clone https://github.com/hoppinger/advanced-custom-fields-wpcli.git web/app/plugins/advanced-custom-fields-wpcli

  # Import our ACF fields for the theme
  wp plugin activate advanced-custom-fields-wpcli --allow-root
  wp acf import --json_file=web/app/themes/pvtl/acf-fields.json --allow-root

  # Remove ACF CLI plugin - we don't need it anymore
  wp plugin deactivate advanced-custom-fields-wpcli --allow-root
  rm -rf web/app/plugins/advanced-custom-fields-wpcli
fi


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

#### 1. Clone this repo
```bash
git clone <repo-url>
```

#### 2. Copy `.env.example` to `.env` and add your environment's settings
```bash
cp .env.example .env
```

#### 3. Import the DB

Once imported: update `siteurl` and `home` in the `wp_options` table + scrub any sensitive data (eg. customer info, credit card tokens etc).

#### 4. Enable Browsersync
```bash
cp web/app/themes/pvtl/config-default.yml web/app/themes/pvtl/config.yml
```
_Then update `BROWSERSYNC` > `url` to be your site's Wordpress URL_

---

## Local development

### Installation

Working in the [Pivotal Docker Dev environment](https://github.com/pvtl/docker-dev), you'll need to do the following:

- You'll need `DB_HOST=db` in your `.env`
- You'll need to create a symlink of `/public` to `/web` (`ln -s web public`)
- Your Hostname will need to be {website}__.pub.localhost__ (note the `.pub`)

### Theme Development

To compile theme assets, the following commands can be used from within the theme directory.

| Command | Description |
| --- | --- |
| `npm start` | Watch/compile assets & start Browsersync (*to use Browsersync, you must run `npm i && npm start` from outside of the Docker container) |
| `npm run build` | Compile assets for production |

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


# Add to Git
# if [[ ${GIT_URL} != 0 ]] ; then
#   git init && git add . && git commit -m 'init'
#   git remote add origin $GIT_URL
#   git push origin master
#   git branch develop
#   git checkout develop
#   git push origin develop
# fi


# Output the login details
# ---------------------------------------------
echo -e "${BLUE}\n - - - - - - - - - - - - - -"
echo "Wordpress has been installed at: ${URL}"
echo "- - -"
echo "Login to Wordpress at: ${URL}/wp/wp-admin"
echo "Your Wordpress username is: ${WP_USER}"
echo "Your Wordpress password is: ${WP_PW}"
echo "Your Wordpress admin email is: ${WP_EMAIL}"
echo "- - -"
echo "The site is located in: ${SITE_ROOT}"
echo "The site is using database: ${DIR_NAME}"
echo -e "- - - - - - - - - - - - - - ${RESET}"
