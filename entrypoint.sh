#!/bin/bash
# Image entrypoint: passes every argument on to terrame.
set -e

# Allows --user "$(id -u):$(id -g)" (output files then belong to the calling user)
if [ ! -w "${HOME:-/nonexistent}" ]; then
    export HOME=/tmp/terrame-home
    mkdir -p "$HOME"
fi

export XDG_RUNTIME_DIR="/tmp/runtime-$(id -u)"
mkdir -p "$XDG_RUNTIME_DIR" && chmod 0700 "$XDG_RUNTIME_DIR"

if [ -z "$DISPLAY" ]; then
    # No display: virtual X server (servers, CI, batch runs)
    exec xvfb-run -a -s "-screen 0 1280x1024x24" /opt/terrame/bin/terrame "$@"
fi

# Host DISPLAY: regular graphical interface
exec /opt/terrame/bin/terrame "$@"
