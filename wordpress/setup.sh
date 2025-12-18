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
RAND=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

# DB Details
DB_HOST="mysql"
DB_USER="root"

# WP Secrets
WP_AUTH_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_SECURE_AUTH_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_LOGGED_IN_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_NONCE_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_AUTH_SALT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_SECURE_AUTH_SALT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_LOGGED_IN_SALT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_NONCE_SALT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)

# Options
while getopts "s" arg; do
  case $arg in
    s)
      IS_STAGE=1
      ;;
  esac
done


# Site Config
# ---------------------------------------------
# LDE database password
echo -e "\n  ➤  Please enter the password for MySQL: [dbroot] "
read -p "== " DB_PW

if [[ -z "$DB_PW" ]]; then
  DB_PW="dbroot"
fi

# Asks for the Git repo URL of the project
  # Quit if nothing input
echo -e "\n  ➤  What's the URL to access the Git repo?"
echo -e "     Note: use the HTTPS version of the URL"
read -p "== " GIT_REPO_URL_HTTPS

GIT_URL_FORMAT="^(https)(:\/\/|@)([^@:]+)([^\/:]+)[\/:]([^\/:]+)\/(.+).git$"

if [[ ${GIT_REPO_URL_HTTPS} =~ ${GIT_URL_FORMAT} ]] ; then
  # Create the GIT equivalent URL - for use outside the docker container
  # - The HTTPS version is only for use inside the docker container
  BASH_REMATCH_3=${BASH_REMATCH[3]}
  BASH_REMATCH_4=${BASH_REMATCH[4]}
  BASH_REMATCH_5=${BASH_REMATCH[5]}
  BASH_REMATCH_6=${BASH_REMATCH[6]}
  
  # If Bitbucket
  if [[ ${GIT_REPO_URL_HTTPS} =~ .*bitbucket* ]] ; then
    GIT_REPO_HOSTNAME=${BASH_REMATCH_4}
    GIT_REPO_OWNER=${BASH_REMATCH_5}
    GIT_REPO_NAME=${BASH_REMATCH_6}

  # Else: Github (likely)
  else
    GIT_REPO_HOSTNAME="@"${BASH_REMATCH_3}${BASH_REMATCH_4}
    GIT_REPO_OWNER=${BASH_REMATCH_5}
    GIT_REPO_NAME=${BASH_REMATCH_6}
  fi

  GIT_REPO_URL_GIT="git${GIT_REPO_HOSTNAME}:${GIT_REPO_OWNER}/${GIT_REPO_NAME}.git"
  echo ${GIT_REPO_URL_GIT}

else
  echo -e "  ⚠  Please enter the HTTPS version of the URL..."
  exit 1
fi

# Asks for the branch to deploy
  # Defaults to master
echo -e "\n  ➤  What Git branch would you like to use?"
echo -e "     Default: develop"
read -p "== " GIT_BRANCH
if [[ -z "$GIT_BRANCH" ]]; then
  GIT_BRANCH="develop"
fi

# Create a default dir and DB name
DIR_NAME_TMP=$(echo $GIT_REPO_NAME | tr -cd '[[:alnum:]].' | tr '[:upper:]' '[:lower:]')

# Directory/DB Name
  # Defaults to a random folder name
echo -e "\n  ➤   We'll create a new directory & DB for the project. What shall we call them?"
echo -e "     Default: ${DIR_NAME_TMP}"
read -p "== " DIR_NAME
if [[ -z "$DIR_NAME" ]]; then
  DIR_NAME="${DIR_NAME_TMP}"
fi

DIR_NAME=$(echo $DIR_NAME | tr -cd '[[:alnum:]].' | tr '[:upper:]' '[:lower:]')

URL="http://${DIR_NAME}.pub.localhost"
if [[ ${IS_STAGE} == 1 ]] ; then
  URL="http://${DIR_NAME}.pub.pvtl.io"
  URL_STAGE_SCRIPT="http://pvtl:pvtl@${DIR_NAME}.pvtl.io/stage.php"
fi

  # Error if directory already exists
if [ -d ${DIR_NAME} ]; then
  echo -e "  ⚠  That directory already exists..."
  exit 1
fi


# Create the directory
# ---------------------------------------------
mkdir $DIR_NAME && cd $DIR_NAME
SITE_ROOT="$(pwd)"


# Create a Database
# ---------------------------------------------
php -r '
$conn = mysqli_connect($argv[1], $argv[2], $argv[3]);
mysqli_query($conn, "CREATE DATABASE " . $argv[4] . " CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
' $DB_HOST $DB_USER $DB_PW $DIR_NAME


# Clone the repo
# ---------------------------------------------
git clone --single-branch --branch ${GIT_BRANCH} ${GIT_REPO_URL_HTTPS} .
git remote set-url origin ${GIT_REPO_URL_GIT}

  # Exit if it didn't clone
if [ ! -f ".env.example" ]; then
  echo -e "  ⚠  Git clone failed"
  exit 1
fi

# Undo the shallow clone when not staging
if [[ ${IS_STAGE} != 1 ]] ; then
  git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
  git fetch origin
fi


# Install Dependencies
# ---------------------------------------------
composer install --ignore-platform-reqs &>/dev/null &

if [ -f "web/app/themes/pvtl-child/index.php" ]; then
  ( cd web/app/themes/pvtl-child ; yarn &>/dev/null & )
fi

# The above commands are run in the background
# `disown` ensures they finish if we close the terminal
disown

# Create a Symlink for our LDE's
# ---------------------------------------------
ln -s web public


# Create the .env file and setup DB connection and secrets
# ---------------------------------------------
cp .env.example .env
sed -i 's/database_name/'"$DIR_NAME"'/g' .env
sed -i 's/database_user/'"$DB_USER"'/g' .env
sed -i 's/database_password/'"$DB_PW"'/g' .env
sed -i "s/# DB_HOST=/DB_HOST='$DB_HOST' # DB_HOST=/g" .env
sed -i 's,http://example.com,'"$URL"',g' .env

// Add or Update WP_POST_REVISIONS
grep -q "^WP_POST_REVISIONS=" .env && sed -i "s/^WP_POST_REVISIONS=.*/WP_POST_REVISIONS=25/g" .env || echo "WP_POST_REVISIONS=25" >> .env

sed -i "s/SECURE_AUTH_KEY='generateme'/SECURE_AUTH_KEY='"$WP_SECURE_AUTH_KEY"'/g" .env
sed -i "s/AUTH_KEY='generateme'/AUTH_KEY='"$WP_AUTH_KEY"'/g" .env
sed -i "s/LOGGED_IN_KEY='generateme'/LOGGED_IN_KEY='"$WP_LOGGED_IN_KEY"'/g" .env
sed -i "s/NONCE_KEY='generateme'/NONCE_KEY='"$WP_NONCE_KEY"'/g" .env
sed -i "s/SECURE_AUTH_SALT='generateme'/SECURE_AUTH_SALT='"$WP_SECURE_AUTH_SALT"'/g" .env
sed -i "s/AUTH_SALT='generateme'/AUTH_SALT='"$WP_AUTH_SALT"'/g" .env
sed -i "s/LOGGED_IN_SALT='generateme'/LOGGED_IN_SALT='"$WP_LOGGED_IN_SALT"'/g" .env
sed -i "s/NONCE_SALT='generateme'/NONCE_SALT='"$WP_NONCE_SALT"'/g" .env



# Create a .htaccess file for permalinks
# ---------------------------------------------
echo '
<IfModule mod_rewrite.c>
  #### Access any non-existent Wordpress uploads from Live site (so that you do not need to download all assets)
  RewriteCond %{REQUEST_URI} ^/app/uploads/(.*)$
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule ^(.*)$ https://www.example.com.au/$1 [QSA,L]

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


# When STAGE-ing - add the stage.php script
# ---------------------------------------------
if [[ ${IS_STAGE} == 1 ]] ; then
  # Pull the stage.php script from Github Gists
  curl -L https://gist.githubusercontent.com/mcnamee/d07145548a864a18ab786f66675efc66/raw/stage.php --output stage.php

  # Add the Git Repo to pull
  sed -i "s,git_repo_url,"$GIT_REPO_URL_GIT",g" stage.php

  # Fix any file permissions
  CORRECT_USER=$(stat -c '%U' ../)
  chown -R ${CORRECT_USER} .
fi


# Output the next steps
# ---------------------------------------------
echo -e "\n  ✓  Setup Successfully!"
echo -e " "
echo -e "     Wordpress has been installed at: ${URL}"
echo -e "     and you can login at: ${URL}/wp/wp-admin"
echo -e " "
echo -e "     We're running the install of dependencies in the background"
echo -e "     - so it may be a couple of minutes before the site is 100% ready"
echo -e " "
echo -e "     Next Steps:"
echo -e "       1. Download any assets (images, files etc) to: ${SITE_ROOT}"
echo -e "       2. Import the Database to the new DB: ${DIR_NAME}"

if [[ ${IS_STAGE} == 1 ]] ; then
  echo -e "       3. Add the dev server's Public Key ( https://pass.pvtl.io/index.php/pwd/view/4922 ) to the Git Repo (Github: Settings > Deploy Key)"
  echo -e "       4. Add the following webhook URL to your git repo, to trigger auto-deploys (Github: Settings > Webhooks)"
  echo -e "          - ${URL_STAGE_SCRIPT}"
fi

echo -e ""
