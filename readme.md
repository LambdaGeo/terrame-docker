
# TerraME Dockerized

This project provides a Docker-based environment to run **TerraME 2.0.1** on modern Linux distributions. It uses a multi-stage build based on Ubuntu 18.04 to resolve legacy dependency issues (like `glibc` and `SWIG` errors) while keeping the final image as light as possible.

---

## 📋 Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- An X11 server (standard on most Linux desktop distributions)



## 📁 Project Structure

```
.
├── Dockerfile             # Optimized multi-stage build for TerraME
├── docker-compose.yml     # Handles volume mapping and GUI environment passthrough
├── models/                # Local folder for Lua scripts and data (synced with container)
│   └── hello_world.lua    # Example model to get you started
├── README.md              # This file
└── .gitignore             # Git ignore rules
```

---

## 🚀 Quick Start

### 1. Enable GUI Access
Before running the container, allow the Docker user to connect to your X11 server:

```bash
xhost +local:docker
```

> 💡 **Note:** This command grants local Docker processes access to your X server. For enhanced security, consider revoking access afterward with `xhost -local:docker`.

### 2. Build and Run
From the project root directory:

```bash
docker-compose up --build
```

The TerraME graphical interface should launch automatically.

---

## 📦 Working with Models

- Any file placed in the `./models` directory on your host machine will be available inside the container at `/opt/terrame/models`.
- We included a `hello_world.lua` example in that folder to help you get started.

### Example Workflow
```bash
# Edit your model locally
nano models/my_model.lua

# Run it inside the container (via TerraME GUI or CLI)
# Inside container path: /opt/terrame/models/my_model.lua
```

---

## 🔧 Troubleshooting

### GUI Not Showing?
1. Verify your `DISPLAY` environment variable is set:
   ```bash
   echo $DISPLAY
   ```
   Expected output: `:0` or similar.

2. If needed, explicitly pass the `DISPLAY` variable:
   ```bash
   export DISPLAY=:0
   docker-compose up --build
   ```

3. Ensure X11 forwarding is enabled (especially on SSH sessions):
   ```bash
   ssh -X user@host
   ```

### Permission Issues?
If you encounter permission errors when accessing mounted volumes:
```bash
# Adjust ownership of the models folder (if needed)
sudo chown -R $USER:$USER ./models
```

---

## 🧹 Cleanup

To stop the container and remove resources:
```bash
docker-compose down
```

To remove the built image (optional):
```bash
docker rmi terrame-dockerized_terrame
```

---

## 📄 License

[Specify your license here, e.g., MIT, Apache 2.0, or "Proprietary"]

---

> 💬 **Tip**: Keep your `models/` directory under version control separately if you want to track experiment history independently from the Docker setup.
