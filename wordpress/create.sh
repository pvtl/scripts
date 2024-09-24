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

# Misc
QUESTION_PREFIX=" ┌────── ───── ─── ── ─ \n │ 👋👋👋 \n │ Q. "
ANSWER_PREFIX=" │ 👉  "
ANSWER_SUFFIX=" └──────── ─────── ───── ──── ─── ── ─ "

# DB Details
DB_HOST="mysql"
DB_USER="root"
RAND=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
RAND_EMAIL="${RAND}@pvtl.io"
WP_PW=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

# WP Secrets
WP_AUTH_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_SECURE_AUTH_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_LOGGED_IN_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_NONCE_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_AUTH_SALT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_SECURE_AUTH_SALT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_LOGGED_IN_SALT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_NONCE_SALT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)


# Site Config
# ---------------------------------------------
# Directory/DB Name
echo -e "${QUESTION_PREFIX} We'll create a new directory & DB for the project. What shall we call them? [wordpress${RAND}] "
read -p "${ANSWER_PREFIX}" DIR_NAME
echo -e "${ANSWER_SUFFIX}"

if [[ -z "$DIR_NAME" ]]; then
  DIR_NAME="wordpress${RAND}"
fi

DIR_NAME=$(echo $DIR_NAME | tr -cd '[[:alnum:]].')
DIR_NAME=`echo "$DIR_NAME" | tr '[:upper:]' '[:lower:]'`

URL="http://${DIR_NAME}.pub.localhost"


# Turns on Salient specific features
echo -e "${QUESTION_PREFIX} Is this a Salient (i.e. template) build? [y/n] "
read -p "${ANSWER_PREFIX}" IS_SALIENT
echo -e "${ANSWER_SUFFIX}"

[ "$IS_SALIENT" != "${IS_SALIENT#[Yy]}" ] && IS_SALIENT=1 || IS_SALIENT=0


# Install Pivotal Theme? (only when it's not a Salient site)
if [[ ${IS_SALIENT} == 0 ]] ; then
  echo -e "${QUESTION_PREFIX} Would you like the Pivotal theme installed? [y/n] "
  read -p "${ANSWER_PREFIX}" INSTALL_THEME
  echo -e "${ANSWER_SUFFIX}"
fi

[ "$INSTALL_THEME" != "${INSTALL_THEME#[Yy]}" ] && INSTALL_THEME=1 || INSTALL_THEME=0

# LDE database password
echo -e "${QUESTION_PREFIX} Please enter the password for your LDE's MySQL: [dbroot] "
read -p "${ANSWER_PREFIX}" DB_PW
echo -e "${ANSWER_SUFFIX}"

if [[ -z "$DB_PW" ]]; then
  DB_PW="dbroot"
fi


# Fetch latest or older version of ACF Pro
echo -e "${QUESTION_PREFIX} To pre-install the latest version of ACF Pro, enter the licence key (starting with \"b3JkZ...\"). Otherwise an older version will be used."
read -p "${ANSWER_PREFIX}" ACF_LICENCE
echo -e "${ANSWER_SUFFIX}"


# Create the directory
# ---------------------------------------------
mkdir $DIR_NAME && cd $DIR_NAME
SITE_ROOT="$(pwd)"


# Download the latest@Bedrock
# ---------------------------------------------
git clone --depth 1 https://github.com/roots/bedrock.git .
rm -rf .git
rm -rf .github


# Install Dependencies
# ---------------------------------------------
composer install --ignore-platform-reqs


# Create a Symlink for our LDE's
# ---------------------------------------------
ln -s web public


# Add Pivotal composer repos
# ---------------------------------------------
composer config repositories.wp-update-watcher git https://github.com/pvtl/wp-update-watcher
composer config repositories.pvtl-sso git https://github.com/pvtl/wordpress-pvtl-sso-plugin
composer config repositories.pvtl-itsec-login-logs git https://github.com/pvtl/wordpress-itsec-login-logs-plugin
composer config repositories.wordpress-training git https://github.com/pvtl/video-training-wp-plugin.git


# Install default Wordpress plugins
# ---------------------------------------------
composer require wpackagist-plugin/wordpress-seo \
  wpackagist-plugin/w3-total-cache \
  wpackagist-plugin/better-wp-security \
  wpackagist-plugin/wp-migrate-db \
  wpackagist-plugin/admin-menu-editor \
  wpackagist-plugin/custom-post-type-ui \
  wpackagist-plugin/simple-custom-post-order \
  wpackagist-plugin/duplicate-post \
  wpackagist-plugin/ewww-image-optimizer \
  wpackagist-plugin/redirection \
  wpackagist-plugin/email-templates \
  wpackagist-plugin/user-switching \
  pvtl/wp-update-watcher \
  "pvtl/pvtl-sso:~1.0" \
  "pvtl/pvtl-itsec-login-logs:~1.0" \
  "pvtl/wordpress-training:~1.0"

# We're not sure if these will forever be around, so we'll manually add them to the directory
git clone --depth 1 https://github.com/pronamic/gravityforms.git web/app/plugins/gravityforms
rm -rf web/app/plugins/gravityforms/.git

# Install Advanced Custom Fields Pro
if [[ -z "$ACF_LICENCE" ]]; then
  # No licence, use an older version
  git clone --depth 1 https://github.com/wp-premium/advanced-custom-fields-pro.git web/app/plugins/advanced-custom-fields-pro
  rm -rf web/app/plugins/advanced-custom-fields-pro/.git
else
  # Licence provided, use the ACF official composer package
  composer config repositories.advanced-custom-fields-pro composer https://$ACF_LICENCE:https%3A%2F%2Fconcepts.pivotalagency.com.au@connect.advancedcustomfields.com
  composer require wpengine/advanced-custom-fields-pro
fi


# Create a Database
# ---------------------------------------------
php -r '
$conn = mysqli_connect($argv[1], $argv[2], $argv[3]);
mysqli_query($conn, "CREATE DATABASE " . $argv[4] . " CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
' $DB_HOST $DB_USER $DB_PW $DIR_NAME


# Add Debugging helpers
# ---------------------------------------------
# Add extra .env variables
sed -i "s,WP_DEBUG_LOG='/path/to/debug.log',\nDISABLE_WP_CRON=false\nWP_DEBUG_LOG=false,g" .env.example

# Ensure the .env debug vars work for staging and production
echo "Config::define('WP_DEBUG', false);" >> ./config/environments/staging.php
echo "Config::define('WP_DEBUG_DISPLAY', false);" >> ./config/environments/staging.php
echo "Config::define('WP_POST_REVISIONS', 20);" >> ./config/environments/staging.php
echo "Config::define('WP_DISABLE_FATAL_ERROR_HANDLER', true);" >> ./config/environments/staging.php

# Create the .env file and setup DB connection
# ---------------------------------------------
cp .env.example .env

# Add URL/Database credentials
sed -i "s/WP_ENV='development'/WP_ENV='production'/g" .env
sed -i 's/database_name/'"$DIR_NAME"'/g' .env
sed -i 's/database_user/'"$DB_USER"'/g' .env
sed -i 's/database_password/'"$DB_PW"'/g' .env
sed -i "s/# DB_HOST='localhost'/DB_HOST='$DB_HOST'/g" .env
sed -i 's,http://example.com,'"$URL"',g' .env

# Generate secrets
sed -i "s/SECURE_AUTH_KEY='generateme'/SECURE_AUTH_KEY='"$WP_SECURE_AUTH_KEY"'/g" .env
sed -i "s/AUTH_KEY='generateme'/AUTH_KEY='"$WP_AUTH_KEY"'/g" .env
sed -i "s/LOGGED_IN_KEY='generateme'/LOGGED_IN_KEY='"$WP_LOGGED_IN_KEY"'/g" .env
sed -i "s/NONCE_KEY='generateme'/NONCE_KEY='"$WP_NONCE_KEY"'/g" .env
sed -i "s/SECURE_AUTH_SALT='generateme'/SECURE_AUTH_SALT='"$WP_SECURE_AUTH_SALT"'/g" .env
sed -i "s/AUTH_SALT='generateme'/AUTH_SALT='"$WP_AUTH_SALT"'/g" .env
sed -i "s/LOGGED_IN_SALT='generateme'/LOGGED_IN_SALT='"$WP_LOGGED_IN_SALT"'/g" .env
sed -i "s/NONCE_SALT='generateme'/NONCE_SALT='"$WP_NONCE_SALT"'/g" .env

# Debug vars don't work in development (this case) - so remove to save confusion
sed -i '/WP_DEBUG/d' .env


# Install Wordpress
# ---------------------------------------------
wp core install \
  --url="${URL}" \
  --title="${DIR_NAME}" \
  --admin_user="${DIR_NAME}" \
  --admin_password="${WP_PW}" \
  --admin_email="${RAND_EMAIL}" \
  --skip-email \
  --allow-root


# Activate plugins
# ---------------------------------------------
wp plugin activate advanced-custom-fields-pro --allow-root
wp plugin activate admin-menu-editor --allow-root
wp plugin activate duplicate-post --allow-root
wp plugin activate gravityforms --allow-root
wp plugin activate simple-custom-post-order --allow-root
wp plugin activate wordpress-seo --allow-root


# Create MU plugin/s
# ---------------------------------------------
# ACF hider
cat << 'EOF' >> ./web/app/mu-plugins/hide-acf-panel.php
<?php
/**
 * Plugin Name:  Hide ACF Panel
 * Description:  Hide the ACF Admin Panel, unless it's the development environment.
 * Version:      1.0.0
 * Author:       Pivotal Agency
 * Author URI:   https://pvtl.io/
 * License:      MIT License
 */

if ( defined( 'WP_ENV' ) && WP_ENV !== 'development' ) {
    add_filter( 'acf/settings/show_admin', '__return_false' );
}
EOF

# CSS Customizer remover
cat << 'EOF' >> ./web/app/mu-plugins/remove-customizer-css.php
<?php
/**
 * Plugin Name:  Remove Customizer CSS
 * Description:  Remove the CSS editor from the WordPress Customizer.
 * Version:      1.0.0
 * Author:       Pivotal Agency
 * Author URI:   https://pvtl.io/
 * License:      MIT License
 */

function prefix_remove_css_section( $wp_customize ) {
  $wp_customize->remove_section( 'custom_css' );
}

add_action( 'customize_register', 'prefix_remove_css_section', 15 );
EOF


# Set Wordpress config
# ---------------------------------------------
# URL structure
wp rewrite structure /%category%/%postname%/ --allow-root
wp rewrite flush --allow-root

# Timezone
wp option update timezone_string Australia/Brisbane --allow-root


# Install all the Salient things
# ---------------------------------------------
if [[ ${IS_SALIENT} == 1 ]] ; then
  # Parent theme
  git clone --depth 1 https://github.com/pvtl/wp-salient.git web/app/themes/salient
  ( cd web/app/themes/salient && rm -rf .git )

  # Copy all of the Salient plugins to 'plugins'
  for i in `ls web/app/themes/salient/plugins/*.zip`; do unzip $i -d web/app/plugins/; done

  # Activate each of the plugins
  cd web/app/themes/salient/plugins/
  for i in `ls *.zip`; do wp plugin activate $(echo $i | sed 's/.zip//g') --allow-root --path="../../../../wp/"; done
  cd $SITE_ROOT

  # Delete the Zips - we don't need them in out Git repos
  rm web/app/themes/salient/plugins/*.zip

  # Child theme
  git clone --depth 1 https://github.com/pvtl/wp-salient-child.git web/app/themes/salient-child
  ( cd web/app/themes/salient-child && rm -rf .git )

  # Move the PHPCS-root config from the theme, into the root (mainly for SublimeLinter...)
  mv ./phpcs.xml ./config/phpcs.xml
  mv web/app/themes/salient-child/phpcs-root.xml ./phpcs.xml

  # Move the Github Actions file into the root
  mkdir ./.github && mkdir ./.github/workflows
  mv ./web/app/themes/salient-child/github-workflows-test.yml ./.github/workflows/test.yml
  rm -rf ./web/app/themes/salient-child/.github

  # Activate Theme
  wp theme activate salient-child --allow-root
fi


# Install the Pivotal theme
# ---------------------------------------------
if [[ ${INSTALL_THEME} == 1 ]] ; then
  # Parent theme
  git clone --depth 1 https://github.com/understrap/understrap.git web/app/themes/understrap
  ( cd web/app/themes/understrap && rm -rf .git )

  # Child theme
  git clone --depth 1 https://github.com/pvtl/wordpress-theme-boilerplate-v3.git web/app/themes/pvtl-child
  cd web/app/themes/pvtl-child
  rm -rf .git

  # Build assets
  yarn &>/dev/null &

  cd $SITE_ROOT

  # Move the PHPCS-root config from the theme, into the root (mainly for SublimeLinter...)
  mv ./phpcs.xml ./config/phpcs.xml
  mv web/app/themes/pvtl-child/phpcs-root.xml ./phpcs.xml

  # Move the Bitbucket Pipelines file into the root
  mv web/app/themes/pvtl-child/bitbucket-pipelines.yml ./bitbucket-pipelines.yml
  sed -i 's,# - cd web/app/themes/pvtl-child,- cd web/app/themes/pvtl-child,g' ./bitbucket-pipelines.yml

  # Move the Github Actions file into the root
  mkdir ./.github && mkdir ./.github/workflows
  mv web/app/themes/pvtl-child/github-workflows-test.yml ./.github/workflows/test.yml
  rm -rf web/app/themes/pvtl-child/.github

  # Activate Theme
  wp theme activate pvtl-child --allow-root

  # Install ACF CLI (to enable us to install some default fields)
  git clone --depth 1 https://github.com/hoppinger/advanced-custom-fields-wpcli.git web/app/plugins/advanced-custom-fields-wpcli

  # Import our ACF fields for the theme
  wp plugin activate advanced-custom-fields-wpcli --allow-root
  wp acf import --json_file=web/app/themes/pvtl-child/acf-fields.json --allow-root

  # Remove ACF CLI plugin - we don't need it anymore
  wp plugin deactivate advanced-custom-fields-wpcli --allow-root
  rm -rf web/app/plugins/advanced-custom-fields-wpcli

  # Import content
  wp plugin install wordpress-importer --activate --allow-root
  sed -i 's,http://pvtl20.pub.localhost,'"$URL"',g' web/app/themes/pvtl-child/wordpress-pages-export.xml
  wp import web/app/themes/pvtl-child/wordpress-pages-export.xml --authors="skip" --allow-root
  sed -i 's,http://pvtl20.pub.localhost,'"$URL"',g' web/app/themes/pvtl-child/wordpress-posts-export.xml
  wp import web/app/themes/pvtl-child/wordpress-posts-export.xml --authors="skip" --allow-root
  wp plugin deactivate wordpress-importer --allow-root
  rm -rf web/app/plugins/wordpress-importer

  # Setup the home/blog pages - 76=about 74=home 102=blog 78=contact
  wp option update show_on_front 'page' --allow-root
  wp option update page_on_front 74 --allow-root
  wp option update page_for_posts 102 --allow-root

  # Create a couple of menus for the theme
  wp menu create "Main Menu" --allow-root
  wp menu create "Top Bar" --allow-root
  wp menu item add-post main-menu 74 --allow-root
  wp menu item add-post main-menu 76 --allow-root
  wp menu item add-post main-menu 102 --allow-root
  wp menu item add-post main-menu 78 --allow-root
  wp menu item add-post top-bar 76 --allow-root
  wp menu item add-post top-bar 78 --allow-root

  # Assign header and footer menus to theme menu locations
  wp menu location assign main-menu primary --allow-root
  wp menu location assign main-menu mobile --allow-root
  wp menu location assign top-bar topbar --allow-root

  # Add some footer widgets
  # wp widget add nav_menu footer-widgets-1 1 --title="Quick Nav" --nav_menu="2" --allow-root
  # wp widget add nav_menu footer-widgets-2 1 --title="Terms" --nav_menu="3" --allow-root
fi


# Create a .htaccess file for permalinks
# ---------------------------------------------
echo '
<IfModule mod_rewrite.c>
  #### If URL is not XYZ, then redirect to XYZ
  # RewriteCond %{HTTP_HOST} !^example\.com
  # RewriteRule ^(.*)$ https://example.com/$1 [R=301,L]

  #### Permanent page redirects
  # RewriteRule ^old-url?$ /new-url [R=301]
</IfModule>

# BEGIN WordPress
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.php$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.php [L]
</IfModule>
# END WordPress
' >> web/.htaccess


# Add the following to the .gitignore
# ---------------------------------------------
echo '
# Generic
.DS_Store
.DS_STORE
*.log
error_log
error_log_dev

# Ignore LDE symlink
/public

# W3Total Cache
web/app/cache
web/app/w3tc-config
web/app/db.php
web/app/advanced-cache.php
web/app/object-cache.php

# Include these plugins
!web/app/plugins/advanced-custom-fields-pro
!web/app/plugins/gravityforms
!web/app/plugins/gravityformscampaignmonitor

# Include Salient plugins
!web/app/plugins/js_composer_salient
!web/app/plugins/salient-*

# Ignore dynamic salient stylesheet
web/app/themes/salient/css/salient-dynamic-styles.css
' >> .gitignore


# Update the Readme
# ---------------------------------------------
rm README.md
cat << 'EOF' >> README.md
# A Wordpress site by Pivotal Agency

## Installation

### a) Automated


[Run a single command](https://github.com/pvtl/install-scripts/tree/master/wordpress#%EF%B8%8F-setup-the-site-locally)

### b) Manual

#### 1. Clone this repo

```bash
git clone <repo-url>
```

#### 2. Copy `.env.example` to `.env` (and add your environment's settings)

```bash
cp .env.example .env
```

#### 3. Import the DB


Once imported: scrub any sensitive data (eg. customer info, credit card tokens etc).

#### 4. Install dependencies (composer, npm)

```bash
composer install --ignore-platform-reqs
( cd web/app/themes/pvtl-child ; yarn )
```

---

## Local development

### Installation


Working in the [Pivotal Docker Dev environment](https://github.com/pvtl/docker-dev), you'll need to do the following:

- You'll need `DB_HOST=mysql` in your `.env`
- You'll need to create a symlink of `/public` to `/web` (`ln -s web public`)
- Your Hostname will need to be {website}__.pub.localhost__ (note the `.pub`)

### Theme


For more information on working with this site's theme, please see the README.md from this site's theme directory.

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
# ---------------------------------------------
git config --global user.email "tech+github@pvtl.io"
git config --global user.name "PVTL Install Bot"
git init && git add . && git commit -m 'init'
git branch develop
git checkout develop

# ACF Pro cleanup
# ---------------------------------------------
if [[ ! -z "$ACF_LICENCE" ]]; then
  # Licence provided, remove ACF from composer.json, but keep the files.
  # This is to prevent issues with later installs.
  composer config --unset repositories.advanced-custom-fields-pro
  composer remove --no-update wpengine/advanced-custom-fields-pro
fi


# Turn full debug mode back on (we turned it off to disable CLI errors)
# ---------------------------------------------
sed -i "s/WP_ENV='production'/WP_ENV='development'/g" .env


# Output the next steps
# ---------------------------------------------
echo -e "${QUESTION_PREFIX} ✓  Installed Successfully!"
echo -e " | "
echo -e " |     Wordpress has been installed at: ${URL}"
echo -e " |     and you can login at: ${URL}/wp/wp-admin"
echo -e " | "
echo -e "${ANSWER_SUFFIX}"

disown
