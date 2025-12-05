# OpenCNC Deployment Guide

This guide explains how to install, run, and uninstall OpenCNC using the provided scripts.

## Tested With:

- Operating System: Ubuntu 24.04.3 LTS (Noble Numbat)

- Docker: version 28.x

- kubectl: version compatible with Kubernetes 1.29.x

- Helm: version 3.x

- kind: version 1.29.x

⚠️ **While the scripts may work on other systems, they are officially tested only on Ubuntu 24.04 LTS.**

## Prerequisites

Before starting the deployment, ensure your system has:

- A supported Linux distribution (tested with Ubuntu 24.04 LTS)
- Internet connection (for downloading dependencies)
- **Make sure your user is in the sudoers group.**
---

## Installation Steps

### 1. Install dependencies

Run the dependencies installation script:

```bash
./install_dependencies.sh
```

The install_dependencies.sh script installs required tools like Docker, Go, kind, helm, kubectl, and any other dependencies. it will automatically configure your user for Docker access.


> ⚠️ **IMPORTANT — DO THIS BEFORE CONTINUING**
>
> After running `install_dependencies.sh`, **you MUST close your terminal completely and open a new one.**
>
> This is required so:
> - your Docker group permissions activate  
> - your updated PATH (Go, kubectl, kind, Helm) becomes available  
>
> If you skip this step, **`deploy.sh` will fail** even if everything was installed correctly. 

---

### 2. Deploy OpenCNC

In a new terminal, run the deployment script:

```bash
./deploy.sh
```

This script will:

- Generate TLS certificates (if missing)
- Create a local Kubernetes cluster using kind
- Load Docker images into the cluster
- Install Helm charts for etcd and all OpenCNC microservices
- Create the required Kubernetes namespace and secrets

✅ **After this script finishes, your OpenCNC deployment will be ready.**  
You can now interact with the cluster using `kubectl` or access the deployed services.

---

## Uninstall OpenCNC

To uninstall OpenCNC and clean up resources, run:

```bash
./undeploy.sh
```

This script will:

- Delete the OpenCNC namespace
- Delete the kind cluster (if applicable)
- Remove generated TLS certificates (if requested)
- Remove deployed Helm releases and secrets

---

## Notes

- If you previously ran `deploy.sh` with `sudo` without closing the terminal and opening a new one, you may need to copy the kubeconfig to your user home to avoid running `kubectl` as root:

  ```bash
  mkdir -p ~/.kube
  sudo cp /root/.kube/config ~/.kube/config
  sudo chown $(id -u):$(id -g) ~/.kube/config
  ```

- It is recommended to run the scripts as a normal user (not root) once Docker access is set up.

- **TLS certificates** are stored in:

  ```
  certs/
  ```

  You can safely back them up or remove them during uninstallation.

---

## Summary of Commands

```bash
# Install dependencies
./install_dependencies.sh

# Close terminal, open a new one

# Deploy OpenCNC
./deploy.sh

# Uninstall OpenCNC
./undeploy.sh
```
