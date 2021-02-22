#!/usr/bin/env bash

#
#
# Helps converts a standard Wordpress site, into Bedrock for git tracking
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
# @copyright Copyright (c) 2021 by Pivotal Agency
# @license   http://www.gnu.org/licenses/
#

# ########################################################################
# Variables
# ########################################################################

RESET_FORMATTING="\e[49m\e[39m"
FORMAT_QUESTION="\e[44m\e[30m"
FORMAT_MESSAGE="\e[43m\e[30m"
FORMAT_SUCCESS="\e[102m\e[30m"
FORMAT_ERROR="\e[41m\e[30m"

INIT_DIR=$( pwd )
UPLOADS=()
THEMES=()
GITIGNORE=()
COMPOSERJSON=()

# Directory
echo -e "${FORMAT_QUESTION}\n  ➤  Which Wordpress directory would you like to run this on? ${RESET_FORMATTING}"
echo -e "     Default: ${INIT_DIR} ${RESET_FORMATTING}"
read -p "== " DIR_NAME
if [[ -z "$DIR_NAME" ]]; then
  DIR_NAME="${INIT_DIR}"
fi

if [ ! -f "${DIR_NAME}/wp-login.php" ]; then
  echo -e "${FORMAT_ERROR}  ⚠  Please enter valid a Wordpress directory...${RESET_FORMATTING}"
  exit 1
fi

# ########################################################################
# Setup
# ########################################################################

# Create /src/ and /dest/, and move everything into /source
# mkdir ./src && mv -f ./{.,}* ./src
# mkdir ./dest

# ########################################################################
# Theme/s
# ########################################################################
cd $INIT_DIR

if [ -d "${DIR_NAME}/wp-content/themes/" ]; then
  cd "${DIR_NAME}/wp-content/themes/"

  for THEME_DIR in */; do
    THEME=$( echo "$THEME_DIR" | sed 's/.$//' ) # Strip last char ('twentyten/' to 'twentyten')

    if [[ $THEME != twenty* ]]; then
      THEMES+=($THEME)
    fi
  done
fi

# ########################################################################
# Plugin/s
# ########################################################################

cd $INIT_DIR

if [ -d "${DIR_NAME}/wp-content/plugins/" ]; then
  cd "${DIR_NAME}/wp-content/plugins/"

  # Loop over all plugin dirs
  for PLUGIN_DIR in */; do
    PLUGIN=$( echo "$PLUGIN_DIR" | sed 's/.$//' ) # Strip last char ('akismet/' to 'akismet')

    # Check if each plugin exists @ https://wordpress.org/plugins/DIRNAME
    RESPONSE=$( curl --write-out '%{http_code}' --silent --output /dev/null "https://wordpress.org/plugins/${PLUGIN}/" )

    # HTTP 2xx response - go to composer
    if [[ $RESPONSE == 2* ]]; then
      COMPOSERJSON+=($PLUGIN)

    # Otherwise add to .gitignore
    else
      GITIGNORE+=($PLUGIN)
    fi
  done
fi

# ########################################################################
# Uploads
# ########################################################################

cd $INIT_DIR

if [ -d "${DIR_NAME}/wp-content/uploads/" ]; then
  cd "${DIR_NAME}/wp-content/uploads/"

  for UPLOADS_DIR in */; do
    UPLOAD=$( echo "$UPLOADS_DIR" | sed 's/.$//' ) # Strip last char ('2020/' to '2020')

    UPLOADS+=($UPLOAD)
  done
fi

# ########################################################################
# Output results
# ########################################################################

cd $INIT_DIR

echo -e "${FORMAT_SUCCESS}\n  ✓  Finished!"
echo -e "${RESET_FORMATTING}"

if [ ${#THEMES[@]} -gt 0 ]; then
  echo -e "${FORMAT_SUCCESS}\n THEMES // Manually copy across these themes:"

  for THEME in "${THEMES[@]}"; do
    echo -e "    - ${THEME}"
  done

  echo -e "\n ${RESET_FORMATTING}"
fi

if [ ${#COMPOSERJSON[@]} -gt 0 ]; then
  echo -e "${FORMAT_SUCCESS}\n PLUGINS // Composer require these plugins:"

  for PLUGIN in "${COMPOSERJSON[@]}"; do
    echo -e "    - ${PLUGIN}"
  done

  echo -e "\n ${RESET_FORMATTING}"
fi

if [ ${#GITIGNORE[@]} -gt 0 ]; then
  echo -e "${FORMAT_SUCCESS}\n PLUGINS // Manually copy across these plugins + add them to .gitignore:"

  for PLUGIN in "${GITIGNORE[@]}"; do
    echo -e "    - ${PLUGIN}"
  done

  echo -e "\n ${RESET_FORMATTING}"
fi

if [ ${#UPLOADS[@]} -gt 0 ]; then
  echo -e "${FORMAT_SUCCESS}\n UPLOADS // Copy across these upload dirs:"

  for UPLOAD in "${UPLOADS[@]}"; do
    echo -e "    - ${UPLOAD}"
  done

  echo -e "\n ${RESET_FORMATTING}"
fi
