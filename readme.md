# TerraME + LuccME in Docker

A ready-to-run Docker image of **[TerraME](https://github.com/TerraME/terrame) 2.0.1** with the
**[LuccME](https://github.com/TerraME/luccme)** land use change modeling package installed.

TerraME's official Linux binary was built for Ubuntu 18.04 and no longer runs on current
distributions. This image packages that binary with everything it needs, so the same model
runs the same way on any machine with Docker.

- **Headless by default:** runs on a virtual X server (Xvfb) when no display is attached. Works on Linux, macOS, Windows, remote servers, and CI.
- **Optional GUI:** opens the graphical interface with host X11 display forwarding.
- **Shell access:** open an interactive `bash` shell to inspect files and test scripts directly.
- **Reproducible:** the TerraME binary is checked against a SHA-256 hash and LuccME is pinned to a fixed commit.

## What's inside

| Component | Version |
|-----------|---------|
| TerraME   | 2.0.1 (official `ubuntu18` binary) |
| TerraLib  | 5.5.1 |
| Lua       | 5.3.4 |
| Qt        | 5.9.5 |
| LuccME    | 3.1 (commit `6244dd4`) |
| Packages  | `base`, `gis`, `luadoc`, `luccme` |

---

## Quick Start (Docker Compose - Recommended)

Docker Compose is the simplest way to run models without typing long volume mounts and user flags.

### 1. Get the image

Pull the published image:

```bash
docker pull profsergiocosta/terrame-luccme
```

or build it from source:

```bash
git clone https://github.com/profsergiocosta/terrame-docker
cd terrame-docker
docker compose build
```

### 2. Run the quick test

```bash
docker compose up
```

This runs the default `hello_world.lua` model in `./models` headlessly and prints the output:
```text
TerraME 2.0.1 running in Docker
Initial sum: 49.83
Sum after 10 steps: 17.37
OK!
```

### 3. Run a LuccME model

```bash
docker compose run --rm terrame luccme_sample.lua
```

This runs a 3-year land use simulation (forest vs. deforestation) in Acre using the bundled `luccme` dataset.

### 4. Run your own model

#### A. Running models placed inside `./models/`
Place your `.lua` script (and data) inside the `./models/` directory, then run:

```bash
docker compose run --rm terrame my_model.lua
```

#### B. Running models from an external folder (outside `./models`)
If your model and datasets are located in another directory on your machine (e.g. `/home/user/my_project`), you don't need to move or copy them into `./models`:

**With Docker Compose:**
```bash
WORK_DIR="/path/to/my_project" docker compose run --rm terrame my_model.lua
```

> **Tip:** If running multiple times in the same terminal, you can set `export WORK_DIR="/path/to/my_project"` once, or create a `.env` file containing `WORK_DIR=/path/to/my_project`.

**With Docker CLI (`docker run`) directly from your project folder:**
Navigate to your project's directory and mount `$PWD` to `/work`:
```bash
cd /path/to/my_project
docker run --rm -v "$PWD":/work profsergiocosta/terrame-luccme my_model.lua
```

> **Tip:** If your model opens a `Chart` or `Map`, pass `-autoclose` so it exits when finished:
> ```bash
> docker compose run --rm terrame -autoclose my_model.lua
> ```

### 5. Open an interactive shell (Bash)

To inspect files, check installed packages, or run commands interactively:

```bash
docker compose run --rm terrame bash
```

---

## Running with Docker CLI (`docker run`)

If you prefer using `docker run` directly:

### Get the image

```bash
docker pull profsergiocosta/terrame-luccme
# or, from a clone of this repository:
docker build -t profsergiocosta/terrame-luccme .
```

### Check version

```bash
docker run --rm profsergiocosta/terrame-luccme
```

### Run a model (headless)

Mount the directory containing your model to `/work` (the container's working directory). Outputs are written there as well:

```bash
docker run --rm -v "$PWD/models":/work profsergiocosta/terrame-luccme hello_world.lua
docker run --rm -v "$PWD/models":/work profsergiocosta/terrame-luccme luccme_sample.lua
```

To run models from your current directory and ensure created files belong to your host user:

```bash
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/work profsergiocosta/terrame-luccme -autoclose my_model.lua
```

### Interactive shell

```bash
docker run --rm -it -v "$PWD/models":/work profsergiocosta/terrame-luccme bash
```

---

## Example Models (`models/`)

The repository includes ready-to-run examples in [`models/`](models):

- **[`models/hello_world.lua`](models/hello_world.lua):** Minimal CellularSpace model. A 10x10 grid with random initial values that decay 10% each step for 10 steps.
- **[`models/luccme_sample.lua`](models/luccme_sample.lua):** A self-contained LuccME simulation model. Demonstrates loading GIS layers (`csAC.shp`), setting up land use categories (`f`, `d`, `outros`), calculating demand, potential linear regression, clue-like allocation, and stepping through time.

---

## Graphical Interface (GUI / X11 on Linux)

To use TerraME's graphical launcher or display maps and charts interactively on a Linux host with X11:

```bash
# 1. Authorize local docker containers to connect to host X server
xhost +local:docker

# 2. Launch the GUI
docker compose --profile gui run --rm terrame-gui

# 3. Revoke access when finished
xhost -local:docker
```

Or using `docker run`:

```bash
xhost +local:docker
docker run --rm -it \
  -e DISPLAY="$DISPLAY" \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "$PWD/models":/work \
  --network host \
  profsergiocosta/terrame-luccme
xhost -local:docker
```

---

## Run the LuccME Test Suite

```bash
echo 'directory = "functional"' > cfg.lua
docker compose run --rm terrame -package luccme -test cfg.lua
```

The 21 functional tests (`lab01` to `lab21`) complete in about 1.5 minutes. On a first run in an empty directory, the report lists "2 problems": these are the `Lab09Console.txt` and `Lab18Console.txt` log files generated by those tests and are not simulation failures.

---

## Project Structure

```
.
├── Dockerfile            # Image: Ubuntu 18.04 + TerraME 2.0.1 + LuccME
├── entrypoint.sh         # Headless Xvfb / host X11 detection + shell execution support
├── docker-compose.yml    # Headless (default) and GUI profiles
├── luccme/               # LuccME 3.1, pinned copy of TerraME/luccme@6244dd4
├── CHANGELOG.md
└── models/               # Sample models
    ├── hello_world.lua   # Minimal CellularSpace test model
    └── luccme_sample.lua # Complete LuccME simulation example
```

---

## Troubleshooting

- **`File '/work/bash' does not exist`:** The entrypoint now automatically supports running `bash` or `sh`. Rebuild your image (`docker compose build`) if you see this error.
- **`Could not connect to any X display`:**
  - If you intended to run **headless**, use the default `terrame` service: `docker compose run --rm terrame <model.lua>` (it uses virtual Xvfb automatically).
  - If you intended to run **GUI**, remember to run `xhost +local:docker` on your host before starting `terrame-gui`.
- **A headless run never ends:** The model opens a `Chart` or a `Map` that waits for a user to close the window. Add `-autoclose` to your command:
  ```bash
  docker compose run --rm terrame -autoclose my_model.lua
  ```
- **Permission errors in `/work`:** Files created by the container in mounted volumes may be owned by UID 1000. If your host user has a different UID/GID, pass `--user "$(id -u):$(id -g)"` to `docker run`.
- **The container hangs with no output:** Do not override the image entrypoint with custom wrappers unless necessary; `dumb-init` is required because `xvfb-run` hangs when run directly as PID 1.

---

## Publishing (maintainers)

Pushing a version tag publishes the image through GitHub Actions (build, smoke test with both sample models, push, Docker Hub description sync):

```bash
git tag 0.2.0 && git push origin 0.2.0
```

Required repository secrets: `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` (access token with Read, Write, Delete scope). Tags pushed: `0.2.0`, `0.2` and `latest`.

---

## License

TerraME and LuccME are distributed under LGPL-3.0 by INPE. See their repositories for details.

Maintained by the [LambdaGeo](https://github.com/LambdaGeo) research group (UFMA).
