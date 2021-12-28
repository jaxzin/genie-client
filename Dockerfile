#FROM --platform=linux/arm/v6 node:bullseye
FROM balenalib/raspberry-pi-debian-node:latest

#RUN dpkg --add-architecture armhf
RUN apt-get update -y

# Install runtime dependencies
RUN apt-get install -y --no-install-recommends \
        wget \
        curl \
        gnupg \
        pulseaudio \
        pulseaudio-utils \
        libpulse0 \
        libpulse-mainloop-glib0 \
        libasound2 \
        libjson-glib-1.0-0 \
        libevdev2 \
        libsoup2.4-1 \
        libspeexdsp1 \
        libwebrtc-audio-processing1 \
        sound-theme-freedesktop \
        unzip \
        sqlite3 \
        coreutils \
        ca-certificates \
        zip \
        gstreamer1.0-plugins-base-apps \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-pulseaudio

RUN apt-get install -y --no-install-recommends python3.9-minimal:armhf

#RUN curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key \
#        | apt-key add - \
#    && echo "deb [arch=armhf] https://deb.nodesource.com/node_12.x bullseye main" \
#        > /etc/apt/sources.list.d/nodesource.list \
#    \
#    && apt-get update -y \
#    && apt-get install -y --no-install-recommends \
#        nodejs

ARG GENIE_CLIENT_CPP_VERSION=c523e24d74a584a2d68649156f960c15264279cb

# Install genie-client
RUN \
    mkdir /src \
    && set -x \
    && apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        ninja-build \
        git \
        meson \
        libgstreamer1.0-dev \
        libasound2-dev \
        libglib2.0-dev \
        libjson-glib-dev \
        libsoup2.4-dev \
        libevdev-dev \
        libpulse-dev \
        libspeex-dev \
        libspeexdsp-dev \
        libwebrtc-audio-processing-dev \
        sound-theme-freedesktop \
    && git clone \
        "https://github.com/stanford-oval/genie-client-cpp" /src \
    && cd /src \
    && git checkout ${GENIE_CLIENT_CPP_VERSION} \
    && git submodule init \
    && git submodule update --recursive \
    && ./scripts/get-assets.sh ${BUILD_ARCH} \
    && meson build \
    && ninja -C build \
    && ninja -C build install \
    && apt-get purge -y --auto-remove \
        build-essential \
        pkg-config \
        ninja-build \
        git \
        meson \
        libgstreamer1.0-dev \
        libasound2-dev \
        libglib2.0-dev \
        libjson-glib-dev \
        libsoup2.4-dev \
        libevdev-dev \
        libpulse-dev \
        libspeex-dev \
        libspeexdsp-dev \
        libwebrtc-audio-processing-dev \
    && rm -rf /src

RUN echo "systemctl --user enable pulseaudio.socket && systemctl --user start pulseaudio.socket" >> /etc/pulse/default.pa
RUN echo "load-module module-echo-cancel source_name=echosrc sink_name=echosink aec_method=speex" >> /etc/pulse/default.pa

RUN apt-get install -y gstreamer1.0-alsa

COPY pulse-client.conf /etc/pulse/client.conf
COPY config.ini .
COPY .asoundrc .
USER root
ENV XDG_RUNTIME_DIR=/run/user/1000
ENV DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
RUN systemctl --user enable pulseaudio.service


EXPOSE 8000

ENTRYPOINT ["genie-client"]
