FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates \
    liblua5.3-0 \
    libstdc++6 \
    libsqlite3-0 \
    libpq5 \
    libgl1-mesa-glx \
    libx11-6 libxext6 libxrender1 libx11-xcb1 \
    libfontconfig1 \
    libdbus-1-3 \
    libfreetype6 \
    libpng16-16 \
    libglib2.0-0 \
    libxcb1 libxcb-glx0 libxcb-util1 \
    libxkbcommon0 libxkbcommon-x11-0 \
    libharfbuzz0b \
    libgraphite2-3 \
    libxi6 \
    libsm6 \
    libice6 \
    libxcb-render-util0 \
    libxcb-render0 \
    libxcb-xfixes0 \
    libxcb-randr0 \
    libxcb-image0 \
    libxcb-shm0 \
    libxcb-keysyms1 \
    libxcb-icccm4 \
    libxcb-shape0 \
    libtiff5 \
    libxml2 \
    libnss3 \
    libnspr4 \
    locales \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

RUN mkdir -p /opt/terrame && \
    wget -q https://github.com/TerraME/terrame/releases/download/2.0.1/terrame-2.0.1-ubuntu18.tar.gz -O /tmp/terrame.tar.gz && \
    tar -xf /tmp/terrame.tar.gz -C /opt/terrame --strip-components=1 && \
    rm /tmp/terrame.tar.gz

RUN ln -sf /opt/terrame/bin/lua /opt/terrame/lua

ENV TME_PATH=/opt/terrame/bin
ENV LD_LIBRARY_PATH=/opt/terrame/bin:/usr/lib/x86_64-linux-gnu:/usr/lib

RUN echo '#!/bin/bash\n\
export XDG_RUNTIME_DIR=/tmp/runtime-root\n\
mkdir -p /tmp/runtime-root && chmod 0700 /tmp/runtime-root\n\
cd /root\n\
exec /opt/terrame/bin/terrame "$@"' > /entrypoint.sh && chmod +x /entrypoint.sh

WORKDIR /root

ENTRYPOINT ["/entrypoint.sh"]
CMD ["-version"]