FROM archlinux:base-devel

ENV \
    CCACHE_SIZE=50G \
    CCACHE_DIR=/srv/ccache \
    USE_CCACHE=1 \
    CCACHE_COMPRESS=1 \
    PATH=$PATH:/usr/local/bin/

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN pacman-key --init
RUN pacman-key --populate archlinux
RUN pacman -Syu --noconfirm

# RUN pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
# RUN pacman-key --lsign-key FBA220DFC880C036
# RUN pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
# RUN echo "[chaotic-aur]" >> /etc/pacman.conf
# RUN echo "Include = /etc/pacman.d/chaotic-mirrorlist" >> /etc/pacman.conf
# RUN pacman -Syu --noconfirm

# RUN pacman -S aosp-devel

RUN echo "[multilib]" >> /etc/pacman.conf
RUN echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
RUN pacman -Syu --noconfirm

RUN pacman -S git

RUN git clone https://aur.archlinux.org/aosp-devel.git
RUN cd aosp-devel
RUN makepkg -si --noconfirm
RUN cd ..
RUN rm -rf aosp-devel


ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
RUN chmod 777 $APP_HOME


RUN mkdir -p /opt/heroku

ADD ./webapp/requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -q -r /tmp/requirements.txt

ADD ./webapp /opt/webapp/
WORKDIR /opt/webapp




ENV LANG="en_US.UTF-8" LANGUAGE="en_US:en"

RUN useradd -m heroku
RUN usermod -d $APP_HOME heroku
RUN chown heroku $APP_HOME
USER heroku

ADD . $APP_HOME

ADD ./heroku-exec.sh /heroku-exec.sh
# Run the app.  CMD is required to run on Heroku
# $PORT is set by Heroku
CMD bash /heroku-exec.sh && gunicorn --bind 0.0.0.0:$PORT wsgi