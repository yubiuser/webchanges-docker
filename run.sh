#!/usr/bin/env sh

version=$(webchanges --version | head -n 1)
date && echo "$version started"

# install crontabfile for the user
crontab -u "$APP_USER" ./crontabfile

rsyslogd -n &
service cron start
tail -f /var/log/syslog
