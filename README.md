# Cloud-1 — Automated deployment of Inception

Ansible playbook that deploys an [Inception](https://github.com)-style WordPress
stack (WordPress, MariaDB, phpMyAdmin, nginx) to a remote Ubuntu 22.04 server,
one process per Docker container, fully automated with no manual steps on the
target host beyond SSH + Python.

## Architecture

```
                 ┌────────────────────────────────────────┐
 Internet ──80/443──▶  nginx (TLS termination)             │
                 │  ├─ /            → wordpress:9000 (fpm) │
                 │  └─ /phpmyadmin/ → phpmyadmin:80         │
                 │                                          │
                 │  wordpress ──▶ db (mariadb)              │
                 │  phpmyadmin ──▶ db (mariadb)              │
                 └────────────────────────────────────────┘
                        docker network: my-net (bridge)
```

Only `nginx` publishes ports to the host (`80`, `443`). `wordpress`,
`phpmyadmin` and `db` are reachable only from other containers on the internal
`my-net` network. The host firewall (`ufw`) allows only `22`, `80`, `443`
inbound, denying everything else — matching the subject's "no direct DB
access from the internet" requirement.

Data persistence: named volumes `wordpress` and `mariadb` are bind-mounted to
`/data/wp` and `/data/db` on the host, so WordPress files and the database
survive a container/server reboot (`restart: always` on every service brings
everything back up automatically).

## Repository layout

```
ansible/
├── ansible.cfg              # inventory path + SSH private key path
├── inventory.ini            # [cloud_servers] target host(s)
├── deploy.yml                # single play, applies roles in order
└── roles/
    ├── common/               # base OS setup: apt update/upgrade, locale, timezone, base packages
    ├── docker/                # installs Docker CE + compose plugin, adds ansible user to docker group
    ├── firewall/              # ufw: deny all inbound except 22/80/443
    ├── mariadb/               # stages Dockerfile for the db image
    ├── wordpress/             # stages Dockerfile + entrypoint script for the wordpress image
    ├── nginx/                 # stages Dockerfile + vhost config (TLS termination, routing)
    └── application/           # stages docker-compose.yml + .env, runs `docker compose up --build -d`
```

Each role's `files/` directory is copied to `/app/srcs/requirements/<role>/`
on the target host; the `application` role assembles them all under
`/app/srcs/` and brings the stack up with Docker Compose.

## Prerequisites

- A target server running Ubuntu 22.04 (or compatible), reachable over SSH,
  with Python installed (required by Ansible).
- Ansible installed on your control machine.
- An SSH keypair whose private half matches the path configured in
  `ansible/ansible.cfg` (`private_key_file = ~/.ssh/ansible` by default).

## Setup

1. **Point Ansible at your server** — edit `ansible/inventory.ini`:
   ```ini
   [cloud_servers]
   YOUR_SERVER_IP ansible_user=YOUR_SSH_USER
   ```
   > ⚠️ The committed `inventory.ini` currently contains a real IP and
   > username. Replace these with your own before deploying, and avoid
   > committing real server identifiers to a public repo (see the subject's
   > Focus Points chapter).

2. **Create the environment file** at
   `ansible/roles/application/files/.env` (not committed — Compose needs it
   for every service):
   ```env
   SQL_DATABASE=wordpress
   MSQL_USER=wp_user
   MSQL_PASSWORD=change_me
   WP_TITLE=My WordPress Site
   WP_ADMIN_USER=admin
   WP_ADMIN_PASSWORD=change_me
   WP_ADMIN_EMAIL=admin@example.com
   WP_URL=https://your-domain.example
   WORDP_USER=author
   WORDP_USER_EMAIL=author@example.com
   USER_PASSWORD=change_me
   ```

3. **Set your domain (optional)** — `ansible/roles/nginx/files/conf/default`
   hardcodes `server_name alagmiri.42.fr;` on the HTTP→HTTPS redirect block.
   Replace it with your own domain or `_` to match any hostname.

4. **Deploy**:
   ```bash
   cd ansible
   ansible-playbook deploy.yml
   ```

The play runs `common → docker → firewall → mariadb → wordpress → nginx →
application`, staging every service's build context before `application`
runs `docker compose up --build -d`, and prints a deployment summary plus
`docker ps` output at the end.

## Running against multiple servers

Add more entries under `[cloud_servers]` in `inventory.ini` — the same
playbook deploys independently to every host in the group.

## Known limitations

These are worth understanding (and are good defense talking points) rather
than hidden:

- **Self-signed TLS only.** `nginx`'s Dockerfile generates a self-signed
  cert at build time (`CN=localhost`, 365-day validity) — there's no
  certbot/Let's Encrypt integration. Fine for a NAT'd school VM without a
  real public domain; browsers will warn on first visit.
- **MariaDB credentials are hardcoded in the image**, not sourced from
  `.env` — `roles/mariadb/files/Dockerfile` bootstraps a fixed
  `amal`/`12345` user against a `wordpress` database at build time. Align
  this with your `.env` values (e.g. via build args) if you change them.
- **`wordpress/files/script.sh`** passes `--dbhost=$localhost`, an unset
  shell variable rather than the `db` container's hostname — double-check
  this resolves correctly for your Compose service name before relying on
  it.
- **No secrets management.** There's no Ansible Vault; `.env` is the only
  place secrets live and must never be committed. Add it to `.gitignore`.

## Security

- Only ports `22`, `80`, and `443` are open on the host firewall; all
  container-to-container traffic (DB, PHP-FPM, phpMyAdmin) stays on the
  internal Docker network.
- Do not commit `.env`, private keys, or real server IPs/usernames to a
  public repository.
