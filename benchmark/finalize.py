"""Finaliza o golden de um lab: comprime o CSV, confere contra a saída original
do lab e grava manifest.json. Usa só a biblioteca padrão.

Chamado por generate.sh:
    python3 finalize.py <lab> <workdir> <destino> <imagem>
"""
from __future__ import annotations

import csv
import gzip
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import sys
from pathlib import Path

TOL = 1e-9  # o CSV tem 12 casas decimais


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_dbf(path: Path) -> list[dict]:
    """Leitor mínimo de DBF (dBase III), suficiente para as saídas do TerraME."""
    data = path.read_bytes()
    n_records, header_len, record_len = struct.unpack("<xxxxIHH", data[:12])
    fields, pos = [], 32
    while data[pos] != 0x0D:
        name = data[pos:pos + 11].split(b"\0")[0].decode()
        ftype, flen = chr(data[pos + 11]), data[pos + 16]
        fields.append((name, ftype, flen))
        pos += 32
    rows = []
    for i in range(n_records):
        rec = data[header_len + i * record_len: header_len + (i + 1) * record_len]
        if rec[:1] == b"*":
            continue
        off, row = 1, {}
        for name, ftype, flen in fields:
            raw = rec[off:off + flen].decode("latin-1").strip()
            off += flen
            if ftype in "NF":
                row[name] = float(raw) if raw else None
            else:
                row[name] = raw
        rows.append(row)
    return rows


def engine_info(image: str) -> dict:
    version = subprocess.run(["docker", "run", "--rm", image], capture_output=True, text=True, check=True).stdout
    upstream = subprocess.run(
        ["docker", "run", "--rm", "--entrypoint", "cat", image,
         "/opt/terrame/bin/packages/luccme/UPSTREAM.md"],
        capture_output=True, text=True, check=True).stdout
    tv = re.search(r"Version:\s*(\S+)", version)
    tl = re.search(r"TerraLib\s+(\S+)", version)
    lc = re.search(r"Commit:\s*([0-9a-f]{40})", upstream)
    return {
        "image": image,
        "terrame": tv.group(1) if tv else None,
        "terralib": tl.group(1) if tl else None,
        "luccme_commit": lc.group(1) if lc else None,
    }


def main() -> None:
    lab, work, dest, image = sys.argv[1], Path(sys.argv[2]), Path(sys.argv[3]), sys.argv[4]
    out = work / "out" / lab
    dest.mkdir(parents=True, exist_ok=True)
    shutil.copy(work / f"{lab}.log", dest / "terrame.log")

    # GOLDEN_SOURCES: scripts do repositório usados no modo SCRIPT (caminhos relativos à raiz)
    repo = Path(__file__).resolve().parents[1]
    sources = os.environ.get("GOLDEN_SOURCES")
    if sources:
        source = [{"script": s, "sha256": sha256(repo / s)} for s in sources.split()]
    else:
        source = {"script": f"luccme/tests/functional/{lab}.lua",
                  "sha256": sha256(work / f"{lab}.script.lua")}
    manifest: dict = {
        "lab": lab,
        "source": source,
        "engine": engine_info(image),
        "generator": {"script": "benchmark/harness.lua",
                      "sha256": sha256(Path(__file__).resolve().parent / "harness.lua")},
    }

    csv_path = out / f"{lab}.csv"
    if not csv_path.exists():
        log_tail = (work / f"{lab}.log").read_text(errors="replace").strip().splitlines()[-5:]
        manifest["status"] = "failed"
        manifest["error"] = log_tail
        (dest / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
        print(f"   {lab}: FALHOU -> {' | '.join(log_tail)}")
        return

    with csv_path.open() as f:
        rows = list(csv.DictReader(f))
    columns = [c for c in rows[0] if c not in ("year", "id", "col", "row")]
    years = sorted({int(r["year"]) for r in rows})
    final = {r["id"]: r for r in rows if int(r["year"]) == years[-1]}

    # Verificação cruzada: último ano do CSV x shapefile salvo pelo próprio lab
    crosscheck = {}
    dbfs = sorted(out.glob("*.dbf"))
    for dbf in dbfs:
        for rec in read_dbf(dbf):
            key = rec.get("object_id0") or rec.get("object_id_") or rec.get("id")
            for attr, value in rec.items():
                if attr in columns and value is not None and key in final:
                    diff = abs(float(final[key][attr]) - value)
                    crosscheck.setdefault(f"{dbf.name}:{attr}", 0.0)
                    crosscheck[f"{dbf.name}:{attr}"] = max(crosscheck[f"{dbf.name}:{attr}"], diff)
    ok = bool(crosscheck) and all(v <= TOL for v in crosscheck.values())

    gz = dest / f"{lab}.csv.gz"
    with csv_path.open("rb") as src, gzip.GzipFile(filename="", mode="wb", fileobj=gz.open("wb"), mtime=0) as dst:
        shutil.copyfileobj(src, dst)

    log = (work / f"{lab}.log").read_text(errors="replace")
    # contínuo: "Demand allocated correctly in 2014.  Number of iterations: 17"
    iterations = {y: int(n) for y, n in re.findall(
        r"allocated correctly in (\d{4})\.\s*Number of iterations: (\d+)", log)}
    # discreto: uma linha "Year: 2004 Iteration -> n" por passada (n começa em 0)
    for y, n in re.findall(r"Year: (\d{4}) Iteration -> (\d+)", log):
        iterations[y] = max(iterations.get(y, 0), int(n))
    manifest.update({
        "status": "ok" if ok else "crosscheck_failed",
        "years": [years[0], years[-1]],
        "n_cells": len(final),
        "columns": columns,
        "file": {"name": gz.name, "rows": len(rows), "sha256": sha256(gz)},
        "crosscheck_vs_original_output": {
            "tolerance": TOL,
            "max_abs_diff": crosscheck,
            "note": "último ano do CSV comparado com os .dbf da pasta de saída: a saída do próprio script e, nas referências, a saída original do TerraME",
        },
        "iterations_per_year": iterations,
        "iterations_note": "contínuo: 'Number of iterations' do LuccME; discreto: maior n de 'Iteration -> n' (0 = aceito na 1ª passada)",
    })
    (dest / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    size_kb = gz.stat().st_size // 1024
    print(f"   {lab}: {manifest['status']}, anos {years[0]}-{years[-1]}, {len(final)} células, "
          f"{', '.join(columns)}, {size_kb} KB")


if __name__ == "__main__":
    main()
