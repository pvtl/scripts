# Wordpress Scripts

## 🖼 Create a New Site

<details><summary>Prerequisites</summary>
<p>

- Unix
- Git
- Node & NPM
- PHP
- MySQL
- Composer
- WP-cli
- Github access to the PVTL theme (it'll prompt you for a password, which is a [Github personal access token](https://github.com/settings/tokens) with *all repo permissions*)
- Ideally using the [Pivotal Docker Dev environment](https://github.com/pvtl/docker-dev)

</p></details>

<details><summary>What does this do?</summary>

<p>

Installs a fresh version of Wordpress with the following:

- Creates a new database for the install
- [Bedrock](https://roots.io/bedrock/) setup with the latest Wordpress core
- A randomly generated admin username and password
- (Optional) The [Pivotal Boilerplate Theme](https://bitbucket.org/pvtl/wordpress-theme-boilerplate/overview) installed and activated
- A set of default plugins (* comes pre-activated):
    - [Advanced Custom Fields Pro*](https://www.advancedcustomfields.com/pro/)
    - [Button Shortcode*](https://github.com/pvtl/wp-button-shortcode)
    - [Duplicate Post*](https://wordpress.org/plugins/duplicate-post)
    - [Gravity Forms*](https://www.gravityforms.com/)
    - [Simple Custom Post Order*](https://wordpress.org/plugins/simple-custom-post-order/)
    - [Smush Image Compression and Optimization*](https://wordpress.org/plugins/wp-smushit/)
    - [Yoast SEO*](https://wordpress.org/plugins/wordpress-seo/)
    - [Admin Menu Editor](https://wordpress.org/plugins/admin-menu-editor/)
    - [Google Analytics Dashboard](https://wordpress.org/plugins/google-analytics-dashboard-for-wp/)
    - [Better WP Security](https://wordpress.org/plugins/better-wp-security/)
    - [Campaign Monitor for Gravity Forms](https://www.gravityforms.com/add-ons/campaign-monitor/)
    - [Disable Gutenburg](https://wordpress.org/plugins/disable-gutenberg/)
    - [Update Watcher](https://bitbucket.org/pvtl/wp-update-watcher)
    - [W3 Total Cache](https://wordpress.org/plugins/w3-total-cache/)
    - [WP Migrate DB](https://wordpress.org/plugins/wp-migrate-db/)
- A `README.md` with nice usage instructions
- A pre-configured `.gitignore`
- Some basic Wordpress config:
    - Default home and blog pages created
    - Permalinks set as `/%category%/%postname%/`
    - Header and Footer menus setup with menu items
    - Timezone set to Brisbane
    - ACF default config imported (if the Pivotal theme is installed)

</p></details>

### Usage

Whilst SSH'd into the Docker `php74` container (`docker exec -it php74 bash`), browsed to `/var/www/html`, simply run:

```bash
bash <(curl -s https://raw.githubusercontent.com/pvtl/install-scripts/master/wordpress/create.sh -L)
```

---

## 🚀 Deploy a Site to production

<details><summary>Prerequisites</summary>
<p>

- Unix
- Git
- PHP
- MySQL
- Composer
- Access to `https://github.com/pvtl/deploy-script.git` (it'll prompt you for a password, which is a [Github personal access token](https://github.com/settings/tokens))
- Access to the Git repo you're wanting to clone
- The domain name you'll be using for the site, must be live and propagated (i.e. for the script to be able to reach it via a CURL request). To get around this, you could either:
    - Add the domain to the *server's* host file (eg. `127.0.0.1 example.com`)
    - Point another 'disposable' (eg. `justfordeploy.pvtl.io`) domain to it for setup, then once deployed, change the domain name in `deploy.json` and `.env`


</p></details>

<details><summary>What does this do?</summary>

<p>

In the past, deploying a Wordpress site typically requires:

1. Finding, downloading, connecting to FTP, uploading, configuring `deploy.php` and the `deploy.json` config
1. Next, through the browser, filling out/submitting deploy.php
1. Next `Stage & deploy`
1. Next, through FTP, create, upload, configure a `.env` (and go to another site to generate WP Secrets custom to this site)
1. Next, through FTP, create, upload, configure a `.htaccess`

This script does all of the above with a single command:

- In a single place, provides step-by-step prompts for the required information
- Grabs the `deploy.php` script from Git (placing it on the server)
- Grabs the `deploy.wordpress.json` (placing it on the server)
- Automatically (using user input) sets up the deploy script & deploys
- Configures Wordpress:
    - Database credentials and URL
    - Generates WP secrets/keys/salts
    - A default `.htaccess` for permalinks
- Sorts out file ownership

</p></details>

### Usage

SSH into the destination server and change to the correct user (`sudo su - -s /bin/bash <cPanel username>`)

```bash
curl https://raw.githubusercontent.com/pvtl/install-scripts/master/wordpress/deploy.sh --output wordpress-deploy.sh && bash wordpress-deploy.sh && rm wordpress-deploy.sh
```

---

## 👷‍♂️ Setup the site locally

<details><summary>Prerequisites</summary>
<p>

- Unix
- Git
- Node, NPM & Yarn
- PHP
- MySQL
- Composer
- Ideally using the [Pivotal Docker Dev environment](https://github.com/pvtl/docker-dev)

</p></details>

<details><summary>What does this do?</summary>

<p>

Setting up a site on your local machine takes time. What if it could be done through a (almost) single command?

This script does all of the above with a single command:

- In a single place, provides step-by-step prompts for the required information
- Creates a directory and Clones the repo into it
- Automatically installs PHP (composer) and build (npm) dependencies
- Symlinks the correct directories
- Configures Wordpress:
    - Database credentials and URL
    - Generates WP secrets/keys/salts
    - A default `.htaccess` for permalinks

</p></details>

### Usage

Whilst SSH'd into the Docker `php74` container (`docker exec -it php74 bash`), browsed to `/var/www/html`, simply run:

```bash
bash <(curl -s https://raw.githubusercontent.com/pvtl/install-scripts/master/wordpress/setup.sh -L)
```

---

## 🔦 Stage on Dev Server

<details><summary>Prerequisites</summary>
<p>

- Unix
- Git
- Node, NPM & Yarn
- PHP
- MySQL
- Composer

</p></details>

<details><summary>What does this do?</summary>

<p>

Setting up a site for staging does take time. What if it could be done through a (almost) single command?

This script does all of the above with a single command:

- In a single place, provides step-by-step prompts for the required information
- Creates a directory and Clones the repo into it
- Automatically installs PHP (composer) and build (npm) dependencies
- Symlinks the correct directories
- Configures Wordpress:
    - Database credentials and URL
    - Generates WP secrets/keys/salts
    - A default `.htaccess` for permalinks
- Downloads and sets up the `stage.php` script 

</p></details>

### Usage

Whilst SSH'd into the Dev Server, `php71` container (`sudo docker exec -it services_php71-fpm_1 bash`), browsed to `/var/www/html`, simply run:

```bash
bash <(curl -s https://raw.githubusercontent.com/pvtl/install-scripts/master/wordpress/setup.sh -L) -s
```
