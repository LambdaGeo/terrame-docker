#!/usr/bin/env bash
# Gera os goldens anuais em benchmark/goldens/<nome>/ na imagem terrame-luccme.
#
#   benchmark/generate.sh                        # todos: lab01..lab21 + references/*
#   benchmark/generate.sh lab01 lab15_md10       # só alguns
#
# <nome> é um lab do pacote (lab01..lab21, luccme/tests/functional/<nome>.lua)
# ou uma pasta de benchmark/references/ (com reference.conf).
# Antes: docker build -t terrame-luccme .   (IMAGE=... para usar outra tag)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
IMAGE="${IMAGE:-terrame-luccme}"
GOLDENS="$HERE/goldens"

NAMES=("$@")
if [ ${#NAMES[@]} -eq 0 ]; then
    NAMES=($(seq -f "lab%02g" 1 21))
    for d in "$HERE"/references/*/; do NAMES+=("$(basename "$d")"); done
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cp "$HERE/harness.lua" "$WORK/"
# As referências leem ../data/<DATA>/: usa os dados de teste do próprio pacote
mkdir -p "$WORK/references/data/cs_ac" "$WORK/references/data/cs_moju"
cp "$ROOT"/luccme/data/test/csAC.* "$WORK/references/data/cs_ac/"
cp "$ROOT"/luccme/data/test/cs_moju.* "$WORK/references/data/cs_moju/"
chmod -R a+rwX "$WORK"

for name in "${NAMES[@]}"; do
    echo "== $name"
    start=$(date +%s)
    ref="$HERE/references/$name"
    if [ -f "$ref/reference.conf" ]; then
        # shellcheck disable=SC1091
        ( source "$ref/reference.conf"
          cp -r "$ref" "$WORK/references/$name"
          chmod -R a+rwX "$WORK/references/$name"
          docker run --rm -e SCRIPT="/work/references/$name/$MAIN" -e NAME="$name" \
              -e OUT="/work/out/$name" -v "$WORK":/work "$IMAGE" -autoclose /work/harness.lua \
              > "$WORK/$name.log" 2>&1 || echo "   FALHOU"
          mkdir -p "$WORK/out/$name"
          cp "$WORK/references/data/$DATA/$OUTPUT".* "$WORK/out/$name/" 2>/dev/null || true
          rm -f "$WORK/references/data/$DATA/$OUTPUT".*
          unzip -q -p "$ref/$ORIGINAL" "$ORIGINAL_MEMBER" > "$WORK/out/$name/original_$ORIGINAL_MEMBER"
          sources=$(cd "$ROOT" && ls benchmark/references/"$name"/*.lua | tr '\n' ' ')
          GOLDEN_SOURCES="$sources" python3 "$HERE/finalize.py" "$name" "$WORK" "$GOLDENS/$name" "$IMAGE" )
    else
        docker run --rm -e LAB="$name" -e OUT="/work/out/$name" -v "$WORK":/work \
            "$IMAGE" -autoclose /work/harness.lua > "$WORK/$name.log" 2>&1 || echo "   FALHOU"
        docker run --rm --entrypoint cat "$IMAGE" \
            "/opt/terrame/bin/packages/luccme/tests/functional/$name.lua" > "$WORK/$name.script.lua"
        python3 "$HERE/finalize.py" "$name" "$WORK" "$GOLDENS/$name" "$IMAGE"
    fi
    echo "   $(( $(date +%s) - start ))s"
done
