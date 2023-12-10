# webchanges-docker

This repo provides a small docker image for running [webchanges](https://github.com/mborsetti/webchanges) without installing a whole python ecosystem. The image is rather small (~30 MB) and `alpine`-based.

The following optional dependencies of `webchanges` are included (see [Dependencies](https://webchanges.readthedocs.io/en/stable/dependencies.html#dependencies))

|   | Comment  |
|---|---|
| `minidb` | to allow uimporting legacy `urlwatch` databases |
|  `html5lib` |  parser for the bs4 method of the html2text filter |
| `beautifulsoup4`  |  `beautify` filter |
|  `jsbeautifier` | `beautify` filter  |
|  `cssbeautifier` |  `beautify` filter |
|  `jq` |   |
|  `chump` |  for `pushover` reporter |
|  `pyopenssl` | |

## Setup

1. add URLs to `data/jobs.yaml` (take a look at the [Jobs section](https://webchanges.readthedocs.io/en/stable/jobs.html) in the *webchanges* documentation for all details)
1. setup `data/config.yaml` as required and configure at least one reporter (e.g. SMTP account details)
1. run *webchanges*:

```shell
docker-compose up -d

# watch log output
docker-compose logs -f

# stop webchanges
docker-compose down
```

### Run Without Docker Compose

If you don't want to use *Docker Compose*, you can run the container with *Docker*:

```shell
# run once
docker run --rm --interactive --tty \
    --volume "$(pwd)/data":/data/webchanges \
    --volume /etc/localtime:/etc/localtime:ro \
    ghcr.io/yubiuser/webchanges

# run in background and restart automatically
docker run --tty --detach --restart unless-stopped \
    --name webchanges \
    --volume "$(pwd)/data":/data/webchanges \
    --volume /etc/localtime:/etc/localtime:ro \
    ghcr.io/yubiuser/webchanges

# watch log output
docker logs --follow webchanges
```

### Change *cron* interval

*webchanges* runs once every 15 minutes with the provided default settings. It's possible to adjust that interval by editing the provided `crontab` file and mount in into the container.

For running every hour instead of the default 15 minutes, change `crontab` as following:

```crontab
0 * * * * cd /data/webchanges && webchanges --urls jobs.yaml --config config.yaml --cache cache.db
```

Addtionally, each day at 08:00 `webchanges --error` runs to check the jobs for errors or empty data.

Tip: use [crontabguru](https://crontab.guru/) to change the cron intervals. 

Mount `crontab` into the container:

```shell
docker-compose run --rm --volume "$(pwd)/crontabfile:/crontabfile:ro" --volume "$(pwd):/data" --volume /etc/localtime:/etc/localtime:ro webchanges
```

or add the mount to `docker-compose.yml`:

```yaml
networks:
  webchanges:

services:
  webchanges:
    image: ghcr.io/yubiuser/webchanges:latest
    container_name: webchanges
    volumes:
      - ./crontabfile:/crontabfile:ro
      - ./data:/data/webchanges
      - /etc/localtime:/etc/localtime:ro
    restart: "unless-stopped"
    networks:
      - webchangess
```

## Build Locally

- clone repository: `git clone git@github.com:yubiuser/webchanges-docker.git`
- adjust interval in crontab if needed (webchanges is started every 15 minutes with the provided default)
- build the image and run *webchanges*
