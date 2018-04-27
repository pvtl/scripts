#!/usr/bin/env bash

#
#
# Installs Voyager "the Pivotal Way"
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

# Config
# ---------------------------------------------
echo "•• We'll create a new directory for the project. What shall we call it? (eg. voyager)"
read DIR_NAME

DIR_NAME=$(echo $DIR_NAME | tr -cd '[[:alnum:]].')
DIR_NAME=`echo "$DIR_NAME" | tr '[:upper:]' '[:lower:]'`
URL="http://${DIR_NAME}.pub.localhost"
DB_HOST="db"
DB_USER="root"
DB_PW="dbroot"
RAND=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
ADMIN_USER="${RAND}@${RAND}.com"
# ADMIN_PW=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
# ADMIN_EMAIL="tech@pvtl.io"

# Install Laravel
# ---------------------------------------------
composer create-project --prefer-dist laravel/laravel $DIR_NAME "5.5.*"
cd $DIR_NAME
SITE_ROOT="$(pwd)"

# Create a Database
# ---------------------------------------------
php -r '
$host = $argv[1];
$user = $argv[2];
$pw = $argv[3];
$name = $argv[4];

$conn = mysqli_connect($host, $user, $pw);
mysqli_query($conn, "CREATE DATABASE " . $name . " CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
' $DB_HOST $DB_USER $DB_PW $DIR_NAME

# Require Voyager
# ---------------------------------------------
composer require tcg/voyager:1.0.17

# Update the .env file
# ---------------------------------------------
cp .env.example .env
sed -i 's,DB_HOST=127.0.0.1,DB_HOST='"$DB_HOST"',g' .env
sed -i 's/DB_DATABASE=homestead/DB_DATABASE='"$DIR_NAME"'/g' .env
sed -i 's/DB_USERNAME=homestead/DB_USERNAME='"$DB_USER"'/g' .env
sed -i 's/DB_PASSWORD=secret/DB_PASSWORD='"$DB_PW"'/g' .env
sed -i 's,APP_URL=http://localhost,APP_URL='"$URL"',g' .env

sed -i 's,MAIL_HOST=smtp.mailtrap.io,MAIL_HOST=mailhog,g' .env
sed -i 's,MAIL_PORT=2525,MAIL_PORT=1025,g' .env
sed -i 's,MAIL_USERNAME=null,MAIL_USERNAME=testuser,g' .env
sed -i 's,MAIL_PASSWORD=null,MAIL_PASSWORD=testpwd,g' .env

php artisan key:generate

# Run the Voyager Installer
# ---------------------------------------------
php artisan voyager:install

# Install Voyager Pages
# ---------------------------------------------
composer require pvtl/voyager-pages
php artisan voyager-pages:install

# Install Voyager Front-end
# ---------------------------------------------
composer require pvtl/voyager-frontend
composer dump-autoload && php artisan voyager-frontend:install
npm install && npm run dev

# Install Voyager Page Blocks
# ---------------------------------------------
composer require pvtl/voyager-page-blocks
php artisan voyager-page-blocks:install

# Install Voyager Forms
# ---------------------------------------------
composer require pvtl/voyager-forms
composer dump-autoload && php artisan voyager-forms:install

# Install Voyager Blog
# ---------------------------------------------
# composer require pvtl/voyager-posts
# php artisan voyager-posts:install

# Update the Readme
# ---------------------------------------------
rm README.md
cat << 'EOF' >> README.md
# A Voyager Project by Pivotal Agency

## Installation

- Clone this repo
- Import a copy of the DB to your environment
- Copy `.env.example` to `.env` and add your environment's settings
- Generate a key - `php artisan key:generate`
- Run `composer install` from the project root
EOF

# Create a Voyager Admin
# ---------------------------------------------
php artisan voyager:admin $ADMIN_USER --create

# Output the login details
# ---------------------------------------------
echo " "
echo "- - - - - - - - - - - - - -"
echo "Voyager has been installed at: ${URL}"
echo "- - -"
echo "Login to the Admin at: ${URL}/admin"
echo "Your Voyager username is: ${ADMIN_USER}"
echo "- - -"
echo "The site is located in: ${SITE_ROOT}"
echo "The site is using database: ${DIR_NAME}"
echo "- - - - - - - - - - - - - -"
