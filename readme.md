# TerraME + LuccME in Docker

A ready-to-run Docker image of **[TerraME](https://github.com/TerraME/terrame) 2.0.1** with the
**[LuccME](https://github.com/TerraME/luccme)** land use change modeling package installed.

TerraME's official Linux binary was built for Ubuntu 18.04 and no longer runs on current
distributions. This image packages that binary with everything it needs, so the same model
runs the same way on any machine with Docker.

- **Headless by default:** with no `DISPLAY`, TerraME runs on a virtual X server (Xvfb). This
  works on servers, in CI, and for batch runs.
- **Optional GUI:** with an X11 display from the host, the TerraME interface opens normally.
- **Reproducible:** the TerraME binary is checked against a SHA-256 hash and LuccME is pinned to
  a fixed commit.

## What's inside

| Component | Version |
|-----------|---------|
| TerraME   | 2.0.1 (official `ubuntu18` binary) |
| TerraLib  | 5.5.1 |
| Lua       | 5.3.4 |
| Qt        | 5.9.5 |
| LuccME    | 3.1 (commit `6244dd4`) |
| Packages  | `base`, `gis`, `luadoc`, `luccme` |

## Build

```bash
git clone https://github.com/LambdaGeo/terrame-docker
cd terrame-docker
docker build -t terrame-luccme .
```

## Run a model (headless)

Mount the folder that holds your model to `/work`, which is the container's working
directory. Output files are written there as well.

```bash
docker run --rm -v "$PWD":/work terrame-luccme my_model.lua
```

To make the output files belong to your own user instead of UID 1000:

```bash
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/work terrame-luccme my_model.lua
```

## Quick test: hello world

`models/hello_world.lua` is a minimal model with no charts or maps: a 10x10 cellular space
whose values decay for 10 steps. Use it to check that the image works:

```bash
docker run --rm terrame-luccme          # prints the versions (default command)
docker run --rm -v "$PWD/models":/work terrame-luccme hello_world.lua
```

Expected output:

```
TerraME 2.0.1 rodando no Docker
Soma inicial: 46.36
Soma após 10 passos: 16.16
OK!
```

The sums change from run to run because the initial values are random. To write your own
model, copy `hello_world.lua` to a folder, edit it, and mount that folder to `/work`.

## Run the LuccME test suite

```bash
echo 'directory = "functional"' > cfg.lua
docker run --rm -v "$PWD":/work terrame-luccme -package luccme -test cfg.lua
```

The 21 functional tests (`lab01` to `lab21`) finish in about 1.5 minutes. On a first run in an
empty folder the report lists "2 problems": these are the `Lab09Console.txt` and
`Lab18Console.txt` files that those tests create. They are not simulation failures.

## Graphical interface (Linux host with X11)

```bash
xhost +local:docker
docker compose up --build
xhost -local:docker    # revoke access when you are done
```

`docker-compose.yml` mounts `./models` to `/work` and passes your `DISPLAY` through. If your
host has a GPU, uncomment the `devices: /dev/dri` block.

## Project structure

```
.
├── dockerfile            # Image: Ubuntu 18.04 + TerraME 2.0.1 + LuccME
├── entrypoint.sh         # Uses Xvfb when there is no DISPLAY, the host X11 otherwise
├── docker-compose.yml    # GUI mode
├── luccme/               # LuccME 3.1, pinned copy of TerraME/luccme@6244dd4
└── models/               # hello_world.lua: minimal model to test the image
```

## Build options

| Build arg          | Default | Purpose |
|--------------------|---------|---------|
| `TERRAME_VERSION`  | `2.0.1` | TerraME release |
| `TERRAME_SHA256`   | hash of 2.0.1 | Checksum of the release tarball |

LuccME is not downloaded: it is kept in `luccme/` (unchanged copy of upstream commit `6244dd4`, see `luccme/UPSTREAM.md`) as the reference implementation for validating disslucc.

## Troubleshooting

- **The container hangs with no output:** do not replace the image entrypoint. It starts under
  `dumb-init` because `xvfb-run` hangs when it runs as PID 1.
- **`Could not connect to any X display`:** `DISPLAY` is set, but the container cannot reach
  the X server. Run `xhost +local:docker`, or unset `DISPLAY` to run headless.
- **Permission errors in `/work`:** use `--user "$(id -u):$(id -g)"`.

## License

TerraME and LuccME are distributed under LGPL-3.0 by INPE. See their repositories for details.

Maintained by the [LambdaGeo](https://github.com/LambdaGeo) research group (UFMA).
