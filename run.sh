#!/usr/bin/env sh

date && echo "webchanges started"

# install crontabfile for the user
crontab -u $APP_USER ./crontabfile

# start crond in foreground (-f) and set logging to level 6)
crond -f -l 6
