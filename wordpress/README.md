# Wordpress Scripts

## Create a New Site

### 🤞 Prerequisites

- Unix
- Git
- Node & NPM
- PHP
- MySQL
- Composer
- WP-cli
- The Pivotal WP theme requires `gulp-cli` NPM module installed globally
- Ideally using the [Pivotal Docker Dev environment](https://github.com/pvtl/docker-dev)

### 🤔 What does this do?

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
    - [Yoast SEO*](https://wordpress.org/plugins/wordpress-seo/)
    - [Admin Menu Editor](https://wordpress.org/plugins/admin-menu-editor/)
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

### 🚀 Usage

Whilst SSH'd into the Docker `php71` container (`docker exec -it php71 bash`), browsed to `/var/www/html`, simply run:

```bash
bash <(curl -s https://raw.githubusercontent.com/pvtl/install-scripts/master/wordpress/create.sh -L)
```

It will provide a few basic prompts for you to configure your new build.

---

## Deploy a Site

### 🤞 Prerequisites

- Unix
- Git
- PHP
- MySQL
- Composer
- Access to `https://bitbucket.org/pvtl/deploy-script.git`
- Access to the Git repo you're wanting to clone

### 🤔 What does this do?

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
    - A default `.htaccess`
- Sorts out file ownership

### 🚀 Usage

SSH into the destination server and change to the correct user (`sudo su - -s /bin/bash <cPanel username>`)

```bash
curl https://raw.githubusercontent.com/pvtl/install-scripts/feature/deploy-wp/wordpress/deploy.sh --output wordpress-deploy.sh && bash wordpress-deploy.sh && rm wordpress-deploy.sh
```

_It will provide a few basic prompts for everything._
