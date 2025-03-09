# syntax=docker/dockerfile:1
ARG python_version=3.12
ARG webchanges_tag=v3.28.1

FROM python:${python_version}-slim-bookworm AS deploy
ARG webchanges_tag
ENV APP_USER=webchanges
ENV PYTHONUTF8=1

RUN apt-get update; \
    apt-get install -y \
            binutils \
	    rsyslog \
	    cron \
            tini

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
    python-dateutil \
    zstandard \
    vobject \
    webchanges[use_browser]

RUN playwright install chrome

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

RUN mv /webchanges/dist/webchanges /usr/local/bin/webchanges

WORKDIR /

RUN addgroup $APP_USER
RUN adduser --disabled-password --ingroup $APP_USER $APP_USER

RUN mkdir -p /data/webchanges \
  && chown -R $APP_USER:$APP_USER /data/webchanges \
  && chmod 0755 /data/webchanges

VOLUME /data/webchanges

COPY crontabfile ./crontabfile
COPY run.sh ./run.sh

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/bin/bash", "run.sh"]
