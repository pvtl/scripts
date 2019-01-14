#!/usr/bin/env bash

#
#
# Sets up (locally) Wordpress "the Pivotal Way"
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
RESET_FORMATTING="\e[49m\e[39m"
FORMAT_QUESTION="\e[44m\e[30m"
FORMAT_MESSAGE="\e[43m\e[30m"
FORMAT_SUCCESS="\e[102m\e[30m"
FORMAT_ERROR="\e[41m\e[30m"
RAND=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

# DB Details
DB_HOST="mysql"
DB_USER="root"
DB_PW="dbroot"

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
  # Defaults to a random folder name
echo -e "${FORMAT_QUESTION}\n  ➤  We'll create a new directory & DB for the project. What shall we call them? [wordpress${RAND}] ${RESET_FORMATTING}"
read -p "== " DIR_NAME
if [[ -z "$DIR_NAME" ]]; then
  DIR_NAME="wordpress${RAND}"
fi

DIR_NAME=$(echo $DIR_NAME | tr -cd '[[:alnum:]].')
DIR_NAME=`echo "$DIR_NAME" | tr '[:upper:]' '[:lower:]'`

URL="http://${DIR_NAME}.pub.localhost"

# Asks for the Git repo URL of the project
  # Quit if nothing input
echo -e "${FORMAT_QUESTION}\n  ➤  What's the URL to access the Git repo?"
echo -e "     Note: use the HTTPS version of the URL${RESET_FORMATTING}"
read -p "== " GIT_REPO_URL_HTTPS

GIT_URL_FORMAT="^(https)(:\/\/|@)([^@:]+)([^\/:]+)[\/:]([^\/:]+)\/(.+).git$"

if [[ ${GIT_REPO_URL_HTTPS} =~ ${GIT_URL_FORMAT} ]] ; then
  # Create the HTTP equivalent URL - for use within the docker container
  # protocol=${BASH_REMATCH[1]}
  # separator=${BASH_REMATCH[2]}
  user=${BASH_REMATCH[4]}
  hostname=${BASH_REMATCH[4]}
  owner=${BASH_REMATCH[5]}
  repo=${BASH_REMATCH[6]}

  GIT_REPO_URL_GIT="git${hostname}:${owner}/${repo}.git"

  echo ${GIT_REPO_URL_GIT}
else
  echo -e "${FORMAT_ERROR}  ⚠  Please enter the HTTPS version of the URL...${RESET_FORMATTING}"
  exit 1
fi


# Create the directory
# ---------------------------------------------
mkdir $DIR_NAME && cd $DIR_NAME
SITE_ROOT="$(pwd)"


# Clone the repo
# ---------------------------------------------
git clone ${GIT_REPO_URL_HTTPS} .

  # Exit if it didn't clone
if [ ! -f ".env.example" ]; then
  echo -e "${FORMAT_ERROR}  ⚠  Git clone failed${RESET_FORMATTING}"
  exit 1
fi

git checkout develop


# Install Dependencies
# ---------------------------------------------
composer install --ignore-platform-reqs
( cd web/app/themes/pvtl ; yarn )
# ( cd web/app/themes/pvtl ; yarn run production )


# Create a Symlink for our LDE's
# ---------------------------------------------
ln -s web public


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


# Output the next steps
# ---------------------------------------------
echo -e "${FORMAT_SUCCESS}\n  ✓  Setup Successfully!"
echo -e " "
echo -e "     Wordpress has been installed at: ${URL}"
echo -e "     and you can login at: ${URL}/wp/wp-admin"
echo -e " "
echo -e "     Next Steps:"
echo -e "       1. Download any assets (images, files etc) to: ${SITE_ROOT}"
echo -e "       2. Import the Database to the new DB: ${DIR_NAME}"
echo -e "${RESET_FORMATTING}"
