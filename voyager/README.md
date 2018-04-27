# Voyager

### 🤞 Prerequisites

- Unix
- Git
- Node & NPM
- Composer
- Ideally using the [Pivotal Docker Dev environment](https://github.com/pvtl/docker-dev)

---

##  `create.sh`

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

### 🚀 Usage

Whilst SSH'd into the Docker `web` container (`docker exec -it web bash`), browsed to `/var/www/html`, simply run:

```bash
bash <(curl -s https://raw.githubusercontent.com/pvtl/install-scripts/master/voyager/create.sh -L)
```

It will ask you for the project name (eg. voyager) which the script will use for various things like the directory name, MySQL database etc.

---
