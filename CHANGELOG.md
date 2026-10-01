# Changelog

## [Unreleased]

### Added
- `docker-compose.yml` headless service (`terrame`) as default: running `docker compose up` now runs a working model out of the box.
- Support for interactive shell (`bash` / `sh`) directly via entrypoint without `File '/work/bash' does not exist` error.
- Support for `WORK_DIR` environment variable in `docker-compose.yml` to run models from external directories.
- `models/luccme_sample.lua`: self-contained LuccME simulation example model using bundled test dataset.
- Dedicated `terrame-gui` profile for GUI runs via Docker Compose.

- `.github/workflows/docker-publish.yml`: builds and smoke-tests the image on pull requests; on a version tag (`1.2.3` or `v1.2.3`) it also pushes `profsergiocosta/terrame-luccme` to Docker Hub and syncs the repository description.

### Removed
- `benchmark/` (LuccME goldens, reference scripts and generator): not needed to use the image.

### Changed
- Image name is now `profsergiocosta/terrame-luccme` (compose, README, model usage comments) for Docker Hub.
- `dockerfile` renamed to `Dockerfile`.
- `luccme/UPSTREAM.md` no longer mentions the benchmark use.
- `.dockerignore`/`.gitignore`: dropped benchmark and Python entries.
- `readme.md`: comprehensive overhaul with quickstart, Docker Compose examples, model descriptions, and troubleshooting.

## [0.1.1] -- 2026-09-23

### Fixed
- `docker compose up` opens the TerraME launcher: the compose file now redeclares the
  image entrypoint, which drops the default `CMD` (`-version`) that made the container
  print the version and exit.
- README: headless runs of models with a `Chart` or `Map` need `-autoclose`, or they
  never end.
- `dockerfile`: the usage comment pointed to an image that is not published
  (`ghcr.io/profsergiocosta/terrame`); it now builds and runs the local `terrame-luccme` tag.

### Changed
- Everything is in English: READMEs, comments, messages of `harness.lua`,
  `generate.sh` and `finalize.py`, the notes in `manifest.json`, and the
  `hello_world.lua` output.
- Goldens regenerated: `terrame.log` and `manifest.json` carry the English messages;
  the CSVs agree with 0.1.0 within 1e-12 (rounding of the 12th decimal place).
- `benchmark/README.md` no longer says disslucc copies every golden.

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
