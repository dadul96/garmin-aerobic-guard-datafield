FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dbus-x11 \
        fish \
        git \
        libasound2 \
        libcanberra-gtk-module \
        libgbm1 \
        libgl1 \
        libgl1-mesa-dri \
        libgtk-3-0 \
        libusb-1.0 \
        libnss3 \
        libwebkit2gtk-4.0-37 \
        libx11-xcb1 \
        libxcomposite1 \
        libxdamage1 \
        libxkbcommon0 \
        libxrandr2 \
        libxss1 \
        libxtst6 \
        mesa-utils \
        openjdk-17-jre \
        openssl \
        procps \
        unzip \
        x11-apps \
        xauth \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["fish"]
