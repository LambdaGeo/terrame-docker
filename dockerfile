FROM ubuntu:18.04 as builder
RUN apt-get update && apt-get install -y wget ca-certificates
RUN mkdir /tme_extract && \
    wget https://github.com/TerraME/terrame/releases/download/2.0.1/terrame-2.0.1-ubuntu18.tar.gz && \
    tar -xf terrame-2.0.1-ubuntu18.tar.gz -C /tme_extract --strip-components=1

FROM ubuntu:18.04

COPY --from=builder /tme_extract /opt/terrame

# Instalamos o básico + o pacote 'libstdc++6' explicitamente
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx libglib2.0-0 libfontconfig1 libxrender1 libdbus-1-3 \
    libx11-6 libxext6 libice6 libsm6 libxt6 libxi6 libxcursor1 \
    libxrandr2 libxinerama1 libxkbcommon-x11-0 libsqlite3-0 \
    libxcb-xfixes0 libxcb-shape0 libxcb-render-util0 libxcb-icccm4 \
    libxcb-image0 libxcb-keysyms1 libxcb-randr0 libxcomposite1 \
    liblua5.3-0 libharfbuzz0b libfreetype6 libpng16-16 \
    locales ca-certificates libstdc++6 \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TME_PATH=/opt/terrame/bin

# --- O SEGREDO DO ISOLAMENTO ---
# 1. Definimos o LD_LIBRARY_PATH para ser APENAS a pasta bin do TerraME primeiro
ENV LD_LIBRARY_PATH=/opt/terrame/bin:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu
# 2. Apontamos o QT_PLUGIN_PATH para o lugar certo
ENV QT_PLUGIN_PATH=/opt/terrame/bin/platforms
ENV QT_QPA_PLATFORM_PLUGIN_PATH=/opt/terrame/bin/platforms

WORKDIR /opt/terrame/bin

# Criamos um pequeno script wrapper para garantir que o binário rode no contexto certo
RUN echo '#!/bin/bash\nexport LD_LIBRARY_PATH=/opt/terrame/bin:$LD_LIBRARY_PATH\n./terrame "$@"' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/opt/terrame/models/hello_world.lua"]