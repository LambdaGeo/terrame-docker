#!/usr/bin/env bash
# Gera os goldens dos labs do pacote LuccME (tests/functional/labNN.lua) na
# imagem terrame-luccme (github.com/LambdaGeo/terrame-docker).
#
#   benchmark/luccme/generate_goldens.sh              # todos os labs (lab01..lab21)
#   benchmark/luccme/generate_goldens.sh lab01 lab15  # só alguns
#
# Variáveis: IMAGE (padrão terrame-luccme).
# Resultado em benchmark/luccme/goldens/<lab>/:
#   <lab>.csv.gz   estado de cada célula ao fim de cada ano (<classe>_out, <classe>_pot)
#   terrame.log    saída do TerraME (iterações e erro máximo por ano)
#   manifest.json  imagem, versões, hashes e a verificação cruzada com a saída original
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="${IMAGE:-terrame-luccme}"
GOLDENS="$HERE/goldens"
LABS=("$@")
if [ ${#LABS[@]} -eq 0 ]; then
    LABS=($(seq -f "lab%02g" 1 21))
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cp "$HERE/harness.lua" "$WORK/"
chmod -R a+rwX "$WORK"

for lab in "${LABS[@]}"; do
    echo "== $lab"
    start=$(date +%s)
    if ! docker run --rm -e LAB="$lab" -e OUT="/work/out/$lab" -v "$WORK":/work \
            "$IMAGE" -autoclose harness.lua > "$WORK/$lab.log" 2>&1; then
        echo "   FALHOU (log em $GOLDENS/$lab/terrame.log)"
    fi
    elapsed=$(( $(date +%s) - start ))
    docker run --rm --entrypoint cat "$IMAGE" \
        "/opt/terrame/bin/packages/luccme/tests/functional/$lab.lua" > "$WORK/$lab.script.lua"
    python3 "$HERE/finalize.py" "$lab" "$WORK" "$GOLDENS/$lab" "$IMAGE"
    echo "   ${elapsed}s"
done
