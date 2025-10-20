Этот докерфайл отработал - [user@centos9 asterisk-docker]$ cat dockerfile 
# =============================
#  Asterisk 13 LTS + DAHDI + MP3 + meetme
# =============================
FROM rockylinux:8

LABEL maintainer="Your Name <you@example.com>"

ENV ASTERISK_VERSION=13.38.3
ENV PJPROJECT_VERSION=2.15
ENV JANSSON_VERSION=2.13
ENV LAME_VERSION=3.100
ENV DAHDI_VERSION=2.11.1+2.11.1

WORKDIR /usr/src

# Установка зависимостей
RUN dnf -y install 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled powertools && \
    dnf -y install epel-release && \
    dnf -y update && \
    dnf -y install dnf-plugins-core wget vim tar bzip2 make gcc gcc-c++ git \
        lynx bison mariadb-server psmisc php php-mysqlnd php-pear \
        php-mbstring tftp-server httpd ncurses-devel sendmail \
        sendmail-cf sox newt-devel libxml2-devel libtiff-devel audiofile-devel \
        gtk2-devel subversion kernel-devel php-process cronie cronie-anacron \
        libtool sqlite-devel libuuid-devel man-pages \
        mod_ssl php-xml which patch autoconf automake libedit-devel openssl-devel \
        net-tools hostname procps-ng chkconfig \
    && dnf clean all

# ---------------------
# pjproject
# ---------------------
RUN wget https://github.com/pjsip/pjproject/archive/refs/tags/${PJPROJECT_VERSION}.tar.gz && \
    tar -xzf ${PJPROJECT_VERSION}.tar.gz && \
    cd pjproject-${PJPROJECT_VERSION} && \
    ./configure --prefix=/usr --enable-shared --disable-sound --disable-resample --disable-video --libdir=/usr/lib64 && \
    make dep && make && make install && ldconfig

# ---------------------
# jansson
# ---------------------
RUN wget http://www.digip.org/jansson/releases/jansson-${JANSSON_VERSION}.tar.gz && \
    tar xzf jansson-${JANSSON_VERSION}.tar.gz && \
    cd jansson-${JANSSON_VERSION} && \
    ./configure --prefix=/usr && make && make install && ldconfig

# ---------------------
# lame
# ---------------------
RUN wget https://downloads.sourceforge.net/project/lame/lame/${LAME_VERSION}/lame-${LAME_VERSION}.tar.gz && \
    tar xzf lame-${LAME_VERSION}.tar.gz && \
    cd lame-${LAME_VERSION} && \
    ./configure && make && make install

# ---------------------
# DAHDI (для meetme)
# ---------------------
RUN dnf -y install dahdi-tools

# ---------------------
# Asterisk
# ---------------------
RUN wget http://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${ASTERISK_VERSION}.tar.gz && \
    tar xzf asterisk-${ASTERISK_VERSION}.tar.gz && \
    cd asterisk-${ASTERISK_VERSION} && \
    contrib/scripts/get_mp3_source.sh && \
    ./configure --libdir=/usr/lib64 && \
    make menuselect.makeopts && \
    menuselect/menuselect --enable format_mp3 menuselect.makeopts && \
    menuselect/menuselect --enable app_meetme menuselect.makeopts && \
    make && make install && make samples && make config && ldconfig

# ---------------------
# Пользователь и права
# ---------------------
RUN groupadd asterisk && \
    useradd -g asterisk asterisk -s /sbin/nologin && \
    chown asterisk.asterisk /var/run/asterisk && \
    chown -R asterisk.asterisk /etc/asterisk && \
    chown -R asterisk.asterisk /var/{lib,log,spool}/asterisk && \
    chown -R asterisk.asterisk /usr/lib64/asterisk

# ---------------------
# Сервис
# ---------------------
EXPOSE 5060/udp 5060/tcp 8088/tcp 10000-20000/udp

CMD ["/usr/sbin/asterisk", "-f", "-U", "asterisk", "-G", "asterisk"]
