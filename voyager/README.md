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
