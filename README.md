# OpenCNC Deployment

This repository contains the files needed to deploy **OpenCNC**. Other related repositories can be found within the organization **TSNTools**. OpenCNC automatically manages elements of a Time Sensitive Network (TSN) according to the IEEE 802.1Q standard and its amendments.

This is the best starting point for using OpenCNC, providing links to its microservices, an installation guide, deployment scripts, and all required dependencies.

---

## Introduction to OpenCNC (Open Centralized Network Configurator)

OpenCNC is designed as a **microservice-based system**. Each microservice is implemented in a separate repository to allow easier use, extension, and maintenance of the tool. The main microservices are:

- **Main Service**
- **TSN Service**
- **Config Service**

---

## Dependencies

To run OpenCNC's services, the following must be installed. For convenience, there is an **installation script for Ubuntu/Linux**: `install_dependencies.sh` (which also performs a quick check if the dependencies are properly installed).

- **Docker** ([Installation Guide](https://docs.docker.com/get-docker/))
- **Go** (version 1.17 or higher) ([Installation Guide](https://golang.org/doc/install))
- **Kubernetes** ([Installation Guide](https://kubernetes.io/docs/tasks/tools/))
- **Kind** ([Installation Guide](https://kind.sigs.k8s.io/))
- **Helm** ([Installation Guide](https://helm.sh/docs/intro/install/))

The script will install missing dependencies and verify that Docker, Go, kubectl, Kind, and Helm are correctly installed and available in your PATH.

---

## Deployment


### Step 1: Install Dependencies
Run the installation script (Ubuntu/Linux):
```bash
./install_dependencies.sh
```


### Step 2: Build Docker Images
Before deploying OpenCNC into Kubernetes, you need to **build the Docker images** for the three microservices. Run these commands from the root of the repository:


```bash
# Build Main Service image
docker build -t opencnc-main:latest ./openc-main-service


# Build TSN Service image
docker build -t opencnc-tsn:latest ./openc-tsn-service


# Build Config Service image
docker build -t opencnc-config:latest ./openc-config-service
```


Verify images with:
```bash
docker images
```


### Step 3: Deploy OpenCNC
Once the images are built, deploy using the provided script:
```bash
./deploy_opencnc.sh
```


---


## Possible Issues


If running the script on Linux, make sure the installation file has execution permissions:
```bash
chmod +x install_dependencies.sh
```


Then run it with:
```bash
./install_dependencies.sh
```
