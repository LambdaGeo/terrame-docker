#!/bin/bash
# Ponto de entrada da imagem: repassa todos os argumentos ao terrame.
set -e

# Permite rodar com --user "$(id -u):$(id -g)" (arquivos de saída ficam com o seu dono)
if [ ! -w "${HOME:-/nonexistent}" ]; then
    export HOME=/tmp/terrame-home
    mkdir -p "$HOME"
fi

export XDG_RUNTIME_DIR="/tmp/runtime-$(id -u)"
mkdir -p "$XDG_RUNTIME_DIR" && chmod 0700 "$XDG_RUNTIME_DIR"

if [ -z "$DISPLAY" ]; then
    # Sem tela: X virtual (servidor, CI, execução em lote)
    exec xvfb-run -a -s "-screen 0 1280x1024x24" /opt/terrame/bin/terrame "$@"
fi

# Com DISPLAY do host: interface gráfica normal
exec /opt/terrame/bin/terrame "$@"
