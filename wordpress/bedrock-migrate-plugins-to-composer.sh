#!/bin/sh

# Create a list of current plugin folder names
find "web/app/plugins" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' > pluginlist.txt
echo "STEP 1/3. $(wc -l pluginlist.txt | awk '{ print $1 }') plugins found in the web/app/plugins directory."

# Loop through the plugin list
echo "STEP 2/3. Beginning plugin installation via Composer"
printf "\n\n# Manually Installed Plugins\n" >> .gitignore
count=1
while read plugin; do
  composer_include_succeeded=1
  composer require "wpackagist-plugin/$plugin" >> composerlog.txt 2>&1
  grep -q "InvalidArgumentException" composerlog.txt && composer_include_succeeded=0
  if [ $composer_include_succeeded -eq 1 ]
  then
    echo "$count. $plugin - Added via Composer"
  else
    echo "!web/app/plugins/$plugin" >> .gitignore;
    echo "$count. $plugin - Added manually"
  fi
  rm composerlog.txt
  count=$((count+1))
done <pluginlist.txt

rm pluginlist.txt
echo "STEP 3/3. Plugin installation complete."