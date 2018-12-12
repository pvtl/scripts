# Wordpress

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
