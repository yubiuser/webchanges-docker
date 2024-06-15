# syntax=docker/dockerfile:1
ARG alpine_version=3.20
ARG python_version=3.12
ARG webchanges_tag=v3.24.1

FROM python:${python_version}-alpine${alpine_version} as builder
ARG webchanges_tag
ENV PYTHONUTF8=1

RUN apk add --no-cache \
    binutils \
    gcc \
    libc-dev \
    libffi-dev \
    upx

# Update pip, setuptools and wheel, install pyinstaller
RUN python3 -m pip install --upgrade \
    pip \
    setuptools \
    wheel \
    && python3 -m pip install pyinstaller

# Get latest webchanges source, checkout tag
ADD https://github.com/mborsetti/webchanges.git#${webchanges_tag} /webchanges
WORKDIR /webchanges

# Install requirements and webchanges from source
RUN python3 -m pip install -r requirements.txt \
    && python3 -m pip install .

# Install some additional packages used by webchanges (optional)
# see https://webchanges.readthedocs.io/en/stable/dependencies.html
RUN python3 -m pip install \
    html5lib \
    beautifulsoup4 \
    jsbeautifier \
    cssbeautifier \
    jq \
    chump \
    pyopenssl \
    minidb \
    python-dateutil
# Copy entrypoint script
COPY webchanges.py webchanges.py

# Monkeypatch to avoid cli output refering to "webchanges" as "webchanges.__init__"
RUN sed -i 's/__project_name__ = __package__/__project_name__ = "webchanges"/g' ./webchanges/__init__.py

# Build the executable file (-F) and strip debug symbols
# Use pythons optimize flag (-OO) to remove doc strings, assert statements, sets __debug__ to false
# (not possible with webchanges, no cli output otherwise)
RUN python3 -m PyInstaller -F --strip webchanges.py

# Debug: list warnings
# RUN cat build/cli/warn-cli.txt



FROM alpine:${alpine_version} as deploy
ENV APP_USER webchanges
ENV PYTHONUTF8=1
RUN apk add --no-cache tini

COPY --from=builder /webchanges/dist/webchanges /usr/local/bin/webchanges

RUN addgroup $APP_USER
RUN adduser --disabled-password --ingroup $APP_USER $APP_USER

RUN mkdir -p /data/webchanges \
  && chown -R $APP_USER:$APP_USER /data/webchanges \
  && chmod 0755 /data/webchanges

VOLUME /data/webchanges

RUN rm /var/spool/cron/crontabs/root

COPY crontabfile ./crontabfile
COPY run.sh ./run.sh

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/bin/sh", "run.sh"]
