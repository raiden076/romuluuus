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

RUN echo "[multilib]" >> /etc/pacman.conf
RUN echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
RUN pacman -Syu --noconfirm

RUN pacman -S --needed --noconfirm sudo git


RUN mkdir -p /opt/heroku

ADD ./webapp/requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -q -r /tmp/requirements.txt

ADD ./webapp /opt/webapp/
WORKDIR /opt/webapp




ENV LANG="en_US.UTF-8" LANGUAGE="en_US:en"

#SWITCH TO NONROOT USER
ENV APP_HOME /home/raiden
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
RUN chmod 777 $APP_HOME
RUN useradd -m raiden
RUN usermod -d $APP_HOME -m raiden
RUN chown raiden $APP_HOME
RUN passwd -d raiden
RUN echo "raiden ALL=(ALL:ALL) ALL" >> /etc/sudoers

#INSTALLING PACKAGE
USER raiden
RUN cd $APP_HOME
RUN git clone https://aur.archlinux.org/aosp-devel.git
RUN cd aosp-devel
RUN makepkg -si --noconfirm
RUN cd ..
RUN git clone https://aur.archlinux.org/lineageos-devel.git los
RUN cd lineageos-devel
RUN makepkg -si --noconfirm
RUN cd ~

ADD . $APP_HOME

ADD ./heroku-exec.sh /heroku-exec.sh
# Run the app.  CMD is required to run on Heroku
# $PORT is set by Heroku
CMD bash /heroku-exec.sh && gunicorn --bind 0.0.0.0:$PORT wsgi
