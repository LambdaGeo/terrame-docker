FROM ubuntu:18.04 as builder
RUN apt-get update && apt-get install -y wget ca-certificates
RUN mkdir /tme_extract && \
    wget https://github.com/TerraME/terrame/releases/download/2.0.1/terrame-2.0.1-ubuntu18.tar.gz && \
    tar -xf terrame-2.0.1-ubuntu18.tar.gz -C /tme_extract --strip-components=1

FROM ubuntu:18.04

COPY --from=builder /tme_extract /opt/terrame

# Dependências mínimas de sistema para garantir que o X11 e Qt funcionem
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

# --- REMOÇÃO DE PLUGINS CONFLITANTES ---
# O erro SWIG no TerraME geralmente é causado por estes módulos tentando carregar
# bibliotecas de sistema incompatíveis durante o boot.
RUN cd /opt/terrame/bin && \
    rm -f libterralib_mod_postgis.so* libterralib_mod_ogr.so* libpq* libmysql* libterralib_mod_gdal.so*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TME_PATH=/opt/terrame/bin

# Criamos o diretório de runtime com permissão total
RUN mkdir -p /tmp/runtime-root && chmod 777 /tmp/runtime-root
ENV XDG_RUNTIME_DIR=/tmp/runtime-root

WORKDIR /opt/terrame/bin

# CONFIGURAÇÃO DE LIGAÇÃO DE BIBLIOTECAS (CRÍTICO)
# Forçamos o carregamento prioritário das libs do TerraME
ENV LD_LIBRARY_PATH=/opt/terrame/bin:/usr/lib/x86_64-linux-gnu

# Criamos um script de entrada que limpa variáveis que podem "sujar" o ambiente
RUN echo '#!/bin/bash\n\
unset LD_PRELOAD\n\
export LD_LIBRARY_PATH=/opt/terrame/bin\n\
./terrame "$@"' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["-v"]