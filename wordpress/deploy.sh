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
RESET_FORMATTING="\e[49m\e[39m"
FORMAT_QUESTION="\e[44m\e[30m"
FORMAT_MESSAGE="\e[43m\e[30m"
FORMAT_SUCCESS="\e[102m\e[30m"
FORMAT_ERROR="\e[41m\e[30m"
PWD=$(pwd)
# DEPLOY_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)

# WP Secrets
WP_AUTH_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_SECURE_AUTH_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_LOGGED_IN_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_NONCE_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_AUTH_SALT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_SECURE_AUTH_SALT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_LOGGED_IN_SALT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
WP_NONCE_SALT=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)

# Directory to deploy to
  # Defaults to PWD/public_html
echo -e "${FORMAT_QUESTION}\n  ➤  Which directory should we deploy to?"
echo -e "     Default: ${PWD}/public_html${RESET_FORMATTING}"
read -p "== " DIR_NAME
if [[ -z "$DIR_NAME" ]]; then
  DIR_NAME="${PWD}/public_html"
fi

  # Create if it doesn't exist
if [ ! -d ${DIR_NAME} ]; then
  mkdir -p ${DIR_NAME};
  chmod 755 ${DIR_NAME}
fi

# Asks for the publicly accessible URL (used to CURL the deploy script)
  # Quit if nothing input
echo -e "${FORMAT_QUESTION}\n  ➤  What's the publicly accessible URL of the site?"
echo -e "     Note: include http:// and NO trailing slash${RESET_FORMATTING}"
read -p "== " PUBLIC_SITE_URL

URL_FORMAT='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'

if [[ ${PUBLIC_SITE_URL} =~ ${URL_FORMAT} ]] ; then
  DEPLOY_SCRIPT_URL="${PUBLIC_SITE_URL}/deploy.php"
else
  echo -e "${FORMAT_ERROR}  ⚠  Please enter a real URL...${RESET_FORMATTING}"
  exit 1
fi

HOSTNAME=$(sed 's_http://__g' <<<${PUBLIC_SITE_URL} | sed 's_https://__g')
SERVER_IP=$(curl http://ifconfig.me)
HOST_IP=$(ping -c 1 ${HOSTNAME} | awk -F '[()]' '{print $2}' | head -n 1)

if [[ ${SERVER_IP} != ${HOST_IP} ]]; then
  if [[ '127.0.0.1' != ${HOST_IP} ]]; then
    echo -e "${FORMAT_ERROR}  ⚠  The hostname is not currently pointed to this server.${RESET_FORMATTING}"
    echo -e "${FORMAT_ERROR}  ⚠  This will cause the deploy to fail.${RESET_FORMATTING}"
    echo -e "${FORMAT_ERROR}  ⚠  Please read the 'Prerequisites' of this script before continuing.${RESET_FORMATTING}"
    echo -e "${FORMAT_QUESTION}\n  ➤  Continue? [y/n] ${RESET_FORMATTING}"
    read -p "== " CONTINUE_WHEN_IPS_DIFF

    if [[ "$CONTINUE_WHEN_IPS_DIFF" != "${CONTINUE_WHEN_IPS_DIFF#[Nn]}" ]]; then
      exit 1
    fi
  fi
fi

# Asks for the Git repo URL of the project
  # Quit if nothing input
echo -e "${FORMAT_QUESTION}\n  ➤  What's the URL to access the Git repo?"
echo -e "     Note: use the GIT version of the URL${RESET_FORMATTING}"
read -p "== " GIT_REPO_URL

GIT_URL_FORMAT='git@[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'

if [[ ${GIT_REPO_URL} =~ ${GIT_URL_FORMAT} ]] ; then
  echo -e ""
else
  echo -e "${FORMAT_ERROR}  ⚠  Please enter a real URL...${RESET_FORMATTING}"
  exit 1
fi

# Asks for the branch to deploy
  # Defaults to master
echo -e "${FORMAT_QUESTION}\n  ➤  What Git branch would you like to use?"
echo -e "     Default: master${RESET_FORMATTING}"
read -p "== " GIT_BRANCH
if [[ -z "$GIT_BRANCH" ]]; then
  GIT_BRANCH="master"
fi


# Setup Deploy script
# ---------------------------------------------
cd ${DIR_NAME}

# Gets (from Githib) deploy.php and the Wordpress specific config
  # Will ask for git username/password
git config --global http.sslVerify false
git clone https://github.com/pvtl/deploy-script.git deploy_tmp

  # Exit if it didn't clone
if [ ! -d "deploy_tmp" ]; then
  echo -e "${FORMAT_ERROR}  ⚠  Git clone failed${RESET_FORMATTING}"
  exit 1
fi

# Puts both deploy.php and config (as deploy.json) into ‘folder to deploy to’
mv deploy_tmp/deploy.php deploy.php
mv deploy_tmp/config-templates/deploy.wordpress.json deploy.json
rm -rf deploy_tmp

  # Exit if the files don't exist
if [ ! -f "deploy.json" ]; then
  echo -e "${FORMAT_ERROR}  ⚠  Deploy script files didn't move${RESET_FORMATTING}"
  exit 1
fi

# Fix any file permissions
find ${DIR_NAME} -type d -exec chmod 755 {} \;
find ${DIR_NAME} -type f -exec chmod 644 {} \;

# Ensure exec() is enabled + give the server a bit more time to execute
echo '
max_execution_time = 250
disable_functions="show_source, system, passthru, popen"
' >> php.ini

# Setup the Deploy script
# - Posting the input details for the script to do its thing
# ---------------------------------------------
# Curl request to URL/deploy.php
curl -X POST \
  ${DEPLOY_SCRIPT_URL} \
  -H 'cache-control: no-cache' \
  -H 'content-type: multipart/form-data;' \
  -F branch=$GIT_BRANCH \
  -F publicDir=$DIR_NAME \
  -F projectPubDir=web \
  -F repoUrl=$GIT_REPO_URL \

# Get the secretKey generated by deploy.php
DEPLOY_SECRET_KEY=$(cat "../deployments/deploy.json" | python -c "import sys, json; print json.load(sys.stdin)['secretKey']")


# Show the public key and pause
# ...for the user to add the public key to the repo
# ---------------------------------------------
# Get the public key
ACC_PUBLIC_KEY_PATH=$(cat "../deployments/deploy.json" | python -c "import sys, json; print json.load(sys.stdin)['sshPubKeyPath']")
ACC_PUBLIC_KEY=$(cat $ACC_PUBLIC_KEY_PATH)

  # Can't find public key
if [[ -z "$ACC_PUBLIC_KEY" ]]; then
  echo -e "${FORMAT_ERROR}  ⚠  Something went wrong - the public/access key wasn't found${RESET_FORMATTING}"
  exit 1
fi

# Show the key and pause
echo -e "${FORMAT_QUESTION}\n  ➤  Please add this Access Key to the Git Repo"
echo -e "     Github: Settings > Access keys${RESET_FORMATTING}"
echo -e "$ACC_PUBLIC_KEY"

PUB_KEY_ADDED=0
while [  $PUB_KEY_ADDED != 1 ]; do
  echo -e "${FORMAT_QUESTION}\n  ➤  Have you added it? [y/n] ${RESET_FORMATTING}"
  read -p "== " PUB_KEY_ADDED
  [ "$PUB_KEY_ADDED" != "${PUB_KEY_ADDED#[Yy]}" ] && PUB_KEY_ADDED=1 || PUB_KEY_ADDED=0
done


# Stage and Deploy
# ---------------------------------------------
# A bit of bants
echo -e "${FORMAT_MESSAGE}\n  ➤  Deploying...please be patient, it may take 5-10mins..."
sleep 1
echo -e "     While you're waiting...Go and setup the Database and import the SQL"
sleep 1
echo -e "     - I'll ask you for DB credentials in a few minutes (you better be ready for it).${RESET_FORMATTING}"

# Give the server a bit more time to execute
# echo '
# php_value max_execution_time 250
# ' >> .htaccess

# The deploy may take some time due to pre/post-hook tasks like composer install
function do_deploy() {
  curl -X GET "${DEPLOY_SCRIPT_URL}?key=${DEPLOY_SECRET_KEY}&deploy" \
    --max-time 150 \
    --connect-timeout 150 \
    --silent > /dev/null

  echo "..."
}
do_deploy

# We may get a gateway timeout when things (eg. composer) take too long.
# So we'll pause until index.php exists
DEPLOY_FINISHED=0
DEPLOY_TIMER=0
DEPLOY_TIMER_MAX=240

while [ $DEPLOY_FINISHED != 1 ]; do
  sleep 5
  [ ! -f "${DIR_NAME}/index.php" ] && DEPLOY_FINISHED=0 || DEPLOY_FINISHED=1

  # We don't want this going on forever - try deploying again (which will use some cache)
  if (( $DEPLOY_TIMER > $DEPLOY_TIMER_MAX )); then
    # To prevent it going over and over
    DEPLOY_FINISHED=1
    echo "Retrying..."
    do_deploy
    sleep 200
  fi

  # Increment by the same as sleep
  DEPLOY_TIMER=$((DEPLOY_TIMER+5))

  echo -n "."
done


# Browse to the project root
# - opposed to the symlinked public dir
# ---------------------------------------------
cd -P ${DIR_NAME} && cd ../


# Create the .env file
# ---------------------------------------------
  # Exit if the deploy script (CURL) didn't execute
if [ ! -f ".env.example" ]; then
  echo -e "${FORMAT_ERROR}  ⚠  Deploy didn't successfully execute"
  echo "Please deploy manually:"
  echo -e " -  ${DEPLOY_SCRIPT_URL}?key=${DEPLOY_SECRET_KEY}${RESET_FORMATTING}"
  exit 1
else
  echo -e "${FORMAT_SUCCESS}\n  ✓  Code deployed.${RESET_FORMATTING}"
fi

cp .env.example .env
sed -i 's,http://example.com,'"$PUBLIC_SITE_URL"',g' .env
sed -i "s,WP_ENV='development',WP_ENV='production',g" .env

# WP Secrets
sed -i "s/SECURE_AUTH_KEY='generateme'/SECURE_AUTH_KEY='"$WP_SECURE_AUTH_KEY"'/g" .env
sed -i "s/AUTH_KEY='generateme'/AUTH_KEY='"$WP_AUTH_KEY"'/g" .env
sed -i "s/LOGGED_IN_KEY='generateme'/LOGGED_IN_KEY='"$WP_LOGGED_IN_KEY"'/g" .env
sed -i "s/NONCE_KEY='generateme'/NONCE_KEY='"$WP_NONCE_KEY"'/g" .env
sed -i "s/SECURE_AUTH_SALT='generateme'/SECURE_AUTH_SALT='"$WP_SECURE_AUTH_SALT"'/g" .env
sed -i "s/AUTH_SALT='generateme'/AUTH_SALT='"$WP_AUTH_SALT"'/g" .env
sed -i "s/LOGGED_IN_SALT='generateme'/LOGGED_IN_SALT='"$WP_LOGGED_IN_SALT"'/g" .env
sed -i "s/NONCE_SALT='generateme'/NONCE_SALT='"$WP_NONCE_SALT"'/g" .env


# DB Credentials
# ---------------------------------------------
# DB Name
echo -e "${FORMAT_QUESTION}\n  ➤  What's the Database Name${RESET_FORMATTING}"
read -p "== " DB_NAME
if [[ -z "$DB_NAME" ]]; then
  echo -e "${FORMAT_ERROR}  ⚠  You didn't provide a DB Name. You'll need to resolve this yourself.${RESET_FORMATTING}"
fi

# DB Username
echo -e "${FORMAT_QUESTION}\n  ➤  What's the Database Username${RESET_FORMATTING}"
read -p "== " DB_USER
if [[ -z "$DB_USER" ]]; then
  echo -e "${FORMAT_ERROR}  ⚠  You didn't provide a DB Username. You'll need to resolve this yourself.${RESET_FORMATTING}"
fi

# DB Password
echo -e "${FORMAT_QUESTION}\n  ➤  What's the Database Password${RESET_FORMATTING}"
read -p "== " DB_PW
if [[ -z "$DB_PW" ]]; then
  echo -e "${FORMAT_ERROR}  ⚠  You didn't provide a DB Password. You'll need to resolve this yourself.${RESET_FORMATTING}"
fi

sed -i 's/database_name/'"$DB_NAME"'/g' .env
sed -i 's/database_user/'"$DB_USER"'/g' .env
sed -i 's/database_password/'"$DB_PW"'/g' .env
sed -i "s/# DB_HOST='localhost'/DB_HOST='localhost'/g" .env


# Create a generic .htaccess file for permalinks (for convenience...user can FTP up a real one if needed)
# ---------------------------------------------
echo "
ErrorDocument 403 default

#### Password protect this directory (excl. PVTL office, Neon, Carbon)
# AuthType Basic
# AuthName 'restricted area'
# AuthUserFile ${DIR_NAME}/.htpasswd
# require valid-user
# Order allow,deny
# Allow from 122.199.1.6
# Allow from 2406:da1c:8ac:e100:fb67:658e:18a6:2cf4
# Allow from 52.63.123.241
# Allow from 2406:da1c:8ac:e102:86f9:3a30:d09:8ef9
# Allow from 13.238.205.33
# satisfy any

#### Block access to xml-rpc.php
#### It's usually how malicious actors brute force logins
RewriteRule ^(.+\/)?xmlrpc.php$ - [F,L]

#### Custom rules
<IfModule mod_rewrite.c>
  #### Access 404d Wordpress uploads from another site site (so that you do not need to download all assets)
  #### - If URL is not found AND the URL contains /app/uploads/ - check on live site
  # RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URI} !-f
  # RewriteCond %{REQUEST_URI} ^/app/uploads/.*$
  # RewriteRule ^(.*)$ https://livesite.com.au/$1 [QSA,L]

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

# Redirect everything while deploying
# NEEDS TO GO RIGHT AT THE BOTTOM to work
# <IfModule mod_rewrite.c>
#     RewriteEngine On
#     RewriteCond %{REQUEST_URI} !^/deploy.php
#     RewriteCond %{REQUEST_URI} !^/coming-soon.html
#     RewriteCond %{REQUEST_URI} !\.(gif|jpe?g|png|css|js)$
#     RewriteRule .* /coming-soon.html [L,R=302]
# </IfModule>
" >> web/.htaccess

echo '
pvtl:pvrgJ0QAegQSM
nbm:nbVh6lSiQJnlI
' >> web/.htpasswd

echo '
Coming soon...
' >> web/coming-soon.html


# Fix any file permissions
# eg. in case the script was operated by the wrong user
# ---------------------------------------------
CORRECT_USER=$(stat -c '%U' ../)
chown -R ${CORRECT_USER} .


# Output the next steps
# ---------------------------------------------
DEPLOY_SCRIPT_URL_W_KEY="${DEPLOY_SCRIPT_URL}?key=${DEPLOY_SECRET_KEY}"

echo -e "${FORMAT_SUCCESS}\n  ✓  Deployed Successfully!"
echo -e "     ${DEPLOY_SCRIPT_URL_W_KEY}"
echo -e " "
echo -e "     Next Steps:"
echo -e "       1. Upload any assets (images, files etc)"
echo -e "       2. Import the database"
echo -e "       3. Setup the CRON: '0,30 * * * * /usr/local/bin/php ${DIR_NAME}/wp/wp-cron.php >/dev/null 2>&1'"
echo -e "       4. Add the following webhook URL to your git repo, to trigger auto-deploys (Github: Settings > Webhooks)"
echo -e "          - ${DEPLOY_SCRIPT_URL_W_KEY}"
echo -e "            (OR https://pvtl:pvtl@... if password protected)"
echo -e "${RESET_FORMATTING}"
