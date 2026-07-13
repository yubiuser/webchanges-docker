#!/usr/bin/env sh

version=$(webchanges --version | head -n 1)
echo "$version started at $(date)"

# install crontabfile for the user
crontab -u "$APP_USER" ./crontabfile

# start crond in foreground (-f) and set logging to level 6)
crond -f -l 6
