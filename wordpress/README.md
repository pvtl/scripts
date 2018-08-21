# Wordpress

### 🤞 Prerequisites

- Unix
- Git
- Node & NPM
- PHP
- Composer
- WP-cli
- The Pivotal WP theme requires `gulp-cli` NPM module installed globally
- Ideally using the [Pivotal Docker Dev environment](https://github.com/pvtl/docker-dev)

---

##  `create.sh`

Installs a fresh version of Wordpress with the following:

- Creates a new database for the install
- [Bedrock](https://roots.io/bedrock/) setup with the latest Wordpress core
- A randomly generated admin username and password
- The [Pivotal Boilerplate Theme](https://bitbucket.org/pvtl/wordpress-theme-boilerplate/overview) installed and activated
- A set of default plugins (* comes pre-activated):
    - [Yoast SEO*](https://wordpress.org/plugins/wordpress-seo/)
    - [Advanced Custom Fields Pro*](https://www.advancedcustomfields.com/pro/)
    - [Gravity Forms*](https://www.gravityforms.com/)
    - [Campaign Monitor for Gravity Forms](https://www.gravityforms.com/add-ons/campaign-monitor/)
    - [W3 Total Cache](https://wordpress.org/plugins/w3-total-cache/)
    - [WP Migrate DB](https://wordpress.org/plugins/wp-migrate-db/)
    - [Admin Menu Editor](https://wordpress.org/plugins/admin-menu-editor/)
    - [Better WP Security](https://wordpress.org/plugins/better-wp-security/)
- A `README.md` with nice usage instructions
- A pre-configured `.gitignore`
- Some basic Wordpress config:
    - Default home and blog pages created
    - Permalinks set as `/%category%/%postname%/`
    - Header and Footer menus setup with menu items
    - Timezone set to Brisbane
    - ACF default config imported

### 🚀 Usage

Whilst SSH'd into the Docker `web` container (`docker exec -it web bash`), browsed to `/var/www/html`, simply run:

```bash
bash <(curl -s https://raw.githubusercontent.com/pvtl/install-scripts/master/wordpress/create.sh -L)
```

It will provide a few basic prompts for you to configure your new build.
