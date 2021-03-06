FROM debian:jessie

RUN apt-get update \ 
 && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils \
       debconf-utils \ 
 && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure apt-utils \
 
 ### Install JAVA 8
 && echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" \
 | tee /etc/apt/sources.list.d/webupd8team-java.list \
 && echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" \
 | tee -a /etc/apt/sources.list.d/webupd8team-java.list \
 && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 \
 && echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections \
 && DEBIAN_FRONTEND=noninteractive apt-get update -y \
 ### END Install JAVA8
 
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        automake \
        cmake \
        curl \
        fakeroot \
        g++ \
        pkg-config \
        git \
        make \
        runit \
        oracle-java8-installer \
        oracle-java8-set-default \
        ant \
        sudo \
        xz-utils

# Here is where we hardcode the toolchain decision.
ENV HOST=arm-linux-gnueabihf \
    TOOLCHAIN=gcc-linaro-arm-linux-gnueabihf-raspbian-x64 \
    RPXC_ROOT=/rpxc

#    TOOLCHAIN=arm-rpi-4.9.3-linux-gnueabihf \
#    TOOLCHAIN=gcc-linaro-arm-linux-gnueabihf-raspbian-x64 \

WORKDIR $RPXC_ROOT
RUN curl -L https://github.com/raspberrypi/tools/tarball/master \
  | tar --wildcards --strip-components 3 -xzf - "*/arm-bcm2708/$TOOLCHAIN/"

ENV ARCH=arm \
    CROSS_COMPILE=$RPXC_ROOT/bin/$HOST- \
    PATH=$RPXC_ROOT/bin:$PATH \
    QEMU_PATH=/usr/bin/qemu-arm-static \
    QEMU_EXECVE=1 \
    SYSROOT=$RPXC_ROOT/sysroot

WORKDIR $SYSROOT
RUN curl -Ls https://github.com/sdhibit/docker-rpi-raspbian/raw/master/raspbian.2015.05.05.tar.xz \
    | tar -xJf - \
 && curl -Ls https://github.com/resin-io-projects/armv7hf-debian-qemu/raw/master/bin/qemu-arm-static \
    > $SYSROOT/$QEMU_PATH \
 && chmod +x $SYSROOT/$QEMU_PATH \
 && mkdir -p $SYSROOT/build \
 && chroot $SYSROOT $QEMU_PATH /bin/sh -c '\
        echo "deb http://archive.raspbian.org/raspbian jessie firmware" \
            >> /etc/apt/sources.list \
        && apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils \
        && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure apt-utils \
        && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
        && DEBIAN_FRONTEND=noninteractive apt-get install -y \
                libc6-dev \
                build-essential \
                symlinks \
                xorg-dev \
                libgtk-3-dev \
                libxrandr-dev \
                libxinerama-dev \
                libxcursor-dev \
                libxi-dev \
                libpulse-dev \
                portaudio19-dev \
                libasound2-dev \
                libjack-dev \
                libraspberrypi-dev \
        && symlinks -cors /'

COPY image/ /

WORKDIR /build
ENTRYPOINT [ "/rpxc/entrypoint.sh" ]
