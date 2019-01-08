#!/usr/bin/env bash

#
#
# Deploys Wordpress "the Pivotal Way"
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
# @copyright Copyright (c) 2019 by Pivotal Agency
# @license   http://www.gnu.org/licenses/
#
#

# Variables
# ---------------------------------------------
RESET="\e[39m"
BLUE="\e[34m"
DEPLOY_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
PWD=$(pwd)

# Directory to deploy to
  # Defaults to PWD/public_html
echo -e "${BLUE}\n?? Where should we deploy to? [${PWD}/public_html] ${RESET}"
read -p "== " DIR_NAME
if [[ -z "$DIR_NAME" ]]; then
  DIR_NAME="${PWD}/public_html"
fi

  # Create if it doesn't exist
if [ ! -d ${DIR_NAME} ]; then
  mkdir -p ${DIR_NAME};
fi

# Asks for the publicly accessible URL (used to CURL the deploy script)
  # Quit if nothing input
echo -e "${BLUE}\n?? What's the publicly accessible URL of the site? (note: include http:// and NO trailing slash) ${RESET}"
read -p "== " PUBLIC_SITE_URL

URL_FORMAT='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'

if [[ ${PUBLIC_SITE_URL} =~ ${URL_FORMAT} ]] ; then
  DEPLOY_SCRIPT_URL="${PUBLIC_SITE_URL}/deploy.php?key=${DEPLOY_KEY}"
else
  echo "Please enter a real URL..."
  exit 1
fi

# Asks for the Git repo URL of the project
  # Quit if nothing input
echo -e "${BLUE}\n?? What's URL to access the Git repo? (note: use the git version of the URL) ${RESET}"
read -p "== " GIT_REPO_URL

GIT_URL_FORMAT='git@[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'

if [[ ${GIT_REPO_URL} =~ ${GIT_URL_FORMAT} ]] ; then
  echo -e "\n"
else
  echo "Please enter a real URL..."
  exit 1
fi

# Asks for the branch to deploy
  # Defaults to master
echo -e "${BLUE}\n?? What Git branch would you like to use? [master] ${RESET}"
read -p "== " GIT_BRANCH
if [[ -z "$GIT_BRANCH" ]]; then
  GIT_BRANCH="master"
fi


# Setup Deploy script
# ---------------------------------------------
cd ${DIR_NAME}

# Gets (from bitbucket) deploy.php and the Wordpress specific config
  # Will ask for git username/password
git config --global http.sslVerify false
git clone https://bitbucket.org/pvtl/deploy-script.git deploy_tmp

# Puts both deploy.php and config (as deploy.json) into ‘folder to deploy to’
mv deploy_tmp/deploy.php deploy.php
mv deploy_tmp/config-templates/deploy.wordpress.json deploy.json
rm -rf deploy_tmp

# Update deploy.json
# Add "repoUrl"
GIT_REPO_URL_ESCD=$(echo ${GIT_REPO_URL//\//\\/})
sed -i 's/"projectPubDir": "web",/"projectPubDir": "web",\n\t"repoUrl": "'"$GIT_REPO_URL_ESCD"'"/g' deploy.json

# Add "trackedBranch"
GIT_BRANCH_ESCD=$(echo ${GIT_BRANCH//\//\\/})
sed -i 's/"projectPubDir": "web",/"projectPubDir": "web",\n\t"trackedBranch": "'"$GIT_BRANCH_ESCD"'"/g' deploy.json

# Add "publicDir"
DIR_NAME_ESCD=$(echo ${DIR_NAME//\//\\/})
sed -i 's/"projectPubDir": "web",/"projectPubDir": "web",\n\t"publicDir": "'"$DIR_NAME_ESCD"'"/g' deploy.json

# Add "secretKey"
sed -i 's/"projectPubDir": "web",/"projectPubDir": "web",\n\t"secretKey": "'"$DEPLOY_KEY"'"/g' deploy.json


# Call the Deploy script to setup and deploy
# ---------------------------------------------
# Curl request to URL/deploy.php
curl -s ${DEPLOY_SCRIPT_URL} > /dev/null


# Create the .env file
# ---------------------------------------------
cp .env.example .env
sed -i 's,http://example.com,'"$PUBLIC_SITE_URL"',g' .env


# Create a generic .htaccess file for permalinks (for convenience...user can FTP up a real one if needed)
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
echo -e "${BLUE}\n - - - - - - - - - - - - - -"
echo "You now need to:"
echo "\t • Setup and import the DB in cPanel"
echo "\t • Update .env with the DB details"
