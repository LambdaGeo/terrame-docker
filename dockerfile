# TerraME 2.0.1 + LuccME, pronto para rodar em qualquer Linux/macOS/Windows com Docker.
#
#   docker run --rm -v "$PWD":/work ghcr.io/lambdageo/terrame meu_modelo.lua
#
# Sem DISPLAY o TerraME roda sobre um X virtual (Xvfb): serve para servidor, CI e
# execução em lote. Com DISPLAY (ver docker-compose.yml) abre a interface gráfica.
#
# O binário oficial do TerraME foi compilado para Ubuntu 18.04, por isso a base.

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
    xvfb xauth \
    dumb-init \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

# --- TerraME (binário oficial, verificado por SHA-256) ---------------------------
ARG TERRAME_VERSION=2.0.1
ARG TERRAME_SHA256=846fa303a6e9dbe1869456e7a525186618595789eec276164b8afbb0ca7e33ed
ARG TERRAME_URL=https://github.com/TerraME/terrame/releases/download/${TERRAME_VERSION}/terrame-${TERRAME_VERSION}-ubuntu18.tar.gz
RUN mkdir -p /opt/terrame \
    && wget -q "${TERRAME_URL}" -O /tmp/terrame.tar.gz \
    && echo "${TERRAME_SHA256}  /tmp/terrame.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/terrame.tar.gz -C /opt/terrame --strip-components=1 \
    && rm /tmp/terrame.tar.gz

# --- LuccME (cópia fixada em ./luccme, ver luccme/UPSTREAM.md) -------------------
COPY luccme/ /opt/terrame/bin/packages/luccme/
# os testes do TerraME gravam logs e saídas dentro da pasta do pacote
RUN chmod -R a+rwX /opt/terrame/bin/packages

ENV TME_PATH=/opt/terrame/bin \
    PATH=/opt/terrame/bin:$PATH \
    LD_LIBRARY_PATH=/opt/terrame/bin

COPY entrypoint.sh /usr/local/bin/terrame-entrypoint
RUN chmod 0755 /usr/local/bin/terrame-entrypoint \
    && useradd --create-home --uid 1000 terrame \
    && mkdir -p /work && chown terrame:terrame /work

LABEL org.opencontainers.image.title="TerraME + LuccME" \
      org.opencontainers.image.description="TerraME 2.0.1 com o pacote LuccME, execução headless ou com interface" \
      org.opencontainers.image.source="https://github.com/LambdaGeo/terrame-docker" \
      org.opencontainers.image.licenses="LGPL-3.0"

USER terrame
WORKDIR /work

# dumb-init como PID 1: sem ele o xvfb-run fica travado dentro do container
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/usr/local/bin/terrame-entrypoint"]
CMD ["-version"]
