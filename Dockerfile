FROM archlinux:base-devel

# Set up build env #1

ENV \
    CCACHE_SIZE=50G \
    CCACHE_DIR=/srv/ccache \
    USE_CCACHE=1 \
    CCACHE_COMPRESS=1 \
    PATH=$PATH:/usr/local/bin/

# Set up bash

RUN rm /bin/sh && ln -s /bin/bash /bin/sh


# Set up pacman


RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Syu --noconfirm && \
    echo "[multilib]" >> /etc/pacman.conf && \
    echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf && \
    pacman -Syu --noconfirm && \
    pacman -S --needed --noconfirm git


# Create and switch to non-root user
RUN useradd -m raiden && \
    mkdir
    echo "raiden ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/raiden
USER raiden
WORKDIR /home/raiden


# Auto-fetch GPG keys and install Paru:
RUN mkdir .gnupg && \
    touch .gnupg/gpg.conf && \
    echo "keyserver-options auto-key-retrieve" > .gnupg/gpg.conf && \
    git clone https://aur.archlinux.org/paru-bin.git && \
    cd paru-bin && \
    makepkg --noconfirm --syncdeps --rmdeps --install --clean


# Set up build env #2

RUN paru -S lineageos-devel


# # setup the webapp and a different user
USER root
WORKDIR /

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
RUN chmod 777 $APP_HOME && \
    mkdir -p /opt/heroku && \
    pacman -S --needed --noconfirm python python-pip

ADD ./webapp/requirements.txt /tmp/requirements.txt

RUN pip3 install --no-cache-dir -q -r /tmp/requirements.txt

ADD ./webapp /opt/webapp/
WORKDIR /opt/webapp

RUN useradd -m webapp && \
    usermod -d $APP_HOME webapp && \
    chown webapp $APP_HOME

USER webapp

ADD . $APP_HOME




# ADD ./webapp/requirements.txt /tmp/requirements.txt
# RUN pip3 install --no-cache-dir -q -r /tmp/requirements.txt

# ADD ./webapp /opt/webapp/
# WORKDIR /opt/webapp




# ENV LANG="en_US.UTF-8" LANGUAGE="en_US:en"

# RUN usermod -d $APP_HOME raiden
# RUN chown raiden $APP_HOME
# USER raiden

# ADD . $APP_HOME

ADD ./heroku-exec.sh /heroku-exec.sh
# Run the app.  CMD is required to run on Heroku
# $PORT is set by Heroku
CMD bash /heroku-exec.sh && gunicorn --bind 0.0.0.0:$PORT wsgi
