# Changelog

## [0.1.0] -- 2026-09-23

First tagged version.

### Image
- TerraME 2.0.1 (official Ubuntu 18.04 binary, SHA-256 checked) with LuccME 3.1
  (`luccme/`, unchanged copy of TerraME/luccme@6244dd4).
- Runs headless by default (Xvfb, under `dumb-init`); uses the host X11 when
  `DISPLAY` is set. Non-root user, working directory `/work`.
- `models/hello_world.lua`: minimal model to check the image.

### Benchmark
- `benchmark/goldens/`: year-by-year reference outputs (every cell, every year,
  `<lu>_out`, `<lu>_pot`, TerraME log and iteration counts) for the 21 functional
  labs of the LuccME package and two reference scripts (`lab01_md1643`,
  `lab15_md10`) that exercise the convergence loop.
- `benchmark/references/`: the reference scripts, unchanged, with the original
  TerraME outputs they produced.
- `benchmark/generate.sh`: regenerates all goldens in the image.
- Documented: LuccME's `correctCellChange` (CClueLike) never runs, because of a
  `regionregionAloc` typo; saving intermediate years through `save.saveYears`
  changes the simulation.
