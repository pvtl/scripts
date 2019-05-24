# Voyager

## 🖼 Create a New Site

<details><summary>Prerequisites</summary>
<p>

- Unix
- Git
- Node & NPM
- PHP >= 7.1.3
- Composer
- Ideally using the [Pivotal Docker Dev environment](https://github.com/pvtl/docker-dev)

</p></details>

<details><summary>What does this do?</summary>

<p>

Installs a fresh version of Voyager with the following:

- Creates a new database for the install
- A randomly generated admin username and password
- A set of default modules
    - [Front-end](https://github.com/pvtl/voyager-frontend)
    - [Pages](https://github.com/pvtl/voyager-pages)
    - [Page Blocks](https://github.com/pvtl/voyager-page-blocks)
    - [Forms](https://github.com/pvtl/voyager-forms)
    - [Blog](https://github.com/pvtl/voyager-posts)
- A `README.md` with nice usage instructions
- A pre-configured `.gitignore`
- Some basic Voyager config:
    - Timezone set to Brisbane

</p></details>

### Usage

Whilst SSH'd into the Docker `php72` container (`docker exec -it php72 bash`), browsed to `/var/www/html`, simply run:

```bash
bash <(curl -s https://raw.githubusercontent.com/pvtl/install-scripts/master/voyager/create.sh -L)
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
- Access to `https://bitbucket.org/pvtl/deploy-script.git`
- Access to the Git repo you're wanting to clone
- The domain name you'll be using for the site, must be live and propagated (i.e. for the script to be able to reach it via a CURL request). To get around this, you could either:
    - Add the domain to the *server's* host file (eg. `127.0.0.1 example.com`)
    - Point another 'disposable' (eg. `justfordeploy.pvtl.io`) domain to it for setup, then once deployed, change the domain name in `deploy.json` and `.env`


</p></details>

<details><summary>What does this do?</summary>

<p>

In the past, deploying a Voyager site typically requires:

1. Finding, downloading, connecting to FTP, uploading, configuring `deploy.php` and the `deploy.json` config
1. Next, through the browser, filling out/submitting deploy.php
1. Next `Stage & deploy`
1. Next, through FTP, create, upload, configure a `.env` (and go to another site to generate WP Secrets custom to this site)
1. Next, through FTP, create, upload, configure a `.htaccess` for password protecting the directory

This script does all of the above with a single command:

- In a single place, provides step-by-step prompts for the required information
- Grabs the `deploy.php` script from Git (placing it on the server)
- Grabs the `deploy.laravel.json` (placing it on the server)
- Automatically (using user input) sets up the deploy script & deploys
- Configures Voyager:
    - Database credentials and URL
    - Generates secrets
- Sorts out file ownership

</p></details>

### Usage

SSH into the destination server and change to the correct user (`sudo su - -s /bin/bash <cPanel username>`)

```bash
curl https://raw.githubusercontent.com/pvtl/install-scripts/master/voyager/deploy.sh --output voyager-deploy.sh && bash voyager-deploy.sh && rm voyager-deploy.sh
```

---
