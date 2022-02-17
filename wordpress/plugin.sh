#!/usr/bin/env bash

#
#
# Generates a new WordPress plugin "the Pivotal Way"
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


# Plugin Config
# ---------------------------------------------
# Public Directory
echo -e "${QUESTION_PREFIX} What's the public directory path of the WordPress website you want to generate the plugin for? [~/Sites/wordpress/web] "
read -p "${ANSWER_PREFIX}" PUBLIC_DIR
echo -e "${ANSWER_SUFFIX}"

if [[ -z "$PUBLIC_DIR" ]]; then
  PUBLIC_DIR="~/Sites/wordpress/web"
fi

HOME_DIR=$(echo $HOME | sed 's/\//\\\//g')
PUBLIC_DIR=$(echo $PUBLIC_DIR | sed 's/~/'$HOME_DIR'/g')


# Plugin Name
echo -e "${QUESTION_PREFIX} What's the plugin name? [PVTL Plugin] "
read -p "${ANSWER_PREFIX}" PLUGIN_NAME
echo -e "${ANSWER_SUFFIX}"

if [[ -z "$PLUGIN_NAME" ]]; then
  PLUGIN_NAME="PVTL Plugin"
fi

PLUGIN_SLUG=$(echo $PLUGIN_NAME | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

PLUGIN_PACKAGE=$(echo $PLUGIN_NAME | tr ' ' '_')

PLUGIN_PACKAGE_LC=$(echo $PLUGIN_PACKAGE | tr '[:upper:]' '[:lower:]')

PLUGIN_ROOT="${PUBLIC_DIR}/app/plugins/${PLUGIN_SLUG}"


# Create the directory
# ---------------------------------------------
mkdir $PLUGIN_ROOT && cd $PLUGIN_ROOT

if [[ ! "$PWD" == $PLUGIN_ROOT ]]; then
  echo -e "Not in plugin root. Exiting."
  exit 1
fi


# Download the plugin boilerplate
# ---------------------------------------------
git clone --depth 1 git@github.com:pvtl/wordpress-plugin-boilerplate.git .
rm -rf .git


# Rename plugin entry file
# ---------------------------------------------
mv wp-plugin-boilerplate.php ${PLUGIN_SLUG}.php


# Rewrite plugin description
# ---------------------------------------------
grep -rl "WordPress Plugin Boilerplate" . | xargs sed -i '' 's/WordPress Plugin Boilerplate/'"$PLUGIN_NAME"'/g'
grep -rl "wordpress-plugin-boilerplate" . | xargs sed -i '' 's/wordpress-plugin-boilerplate/'"$PLUGIN_SLUG"'/g'
grep -rl "WP_Plugin_Boilerplate" . | xargs sed -i '' 's/WP_Plugin_Boilerplate/'"$PLUGIN_PACKAGE"'/g'
grep -rl "wp_plugin_boilerplate" . | xargs sed -i '' 's/wp_plugin_boilerplate/'"$PLUGIN_PACKAGE_LC"'/g'
grep -rl "wp-plugin-boilerplate" . | xargs sed -i '' 's/wp-plugin-boilerplate/'"$PLUGIN_SLUG"'/g'


# Output the next steps
# ---------------------------------------------
echo -e "${QUESTION_PREFIX} ✓  Generated Successfully!"
echo -e " | "
echo -e " |     Plugin has been installed at: ${PLUGIN_ROOT}"
echo -e " | "
echo -e "${ANSWER_SUFFIX}"
