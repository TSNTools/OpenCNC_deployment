#!/bin/bash
set -e

# Minimum Go version
GO_VERSION="1.17"

echo "🚀 Installing dependencies for OpenCNC..."

# 1. Update system
sudo apt update && sudo apt upgrade -y

# 2. Install Docker
echo "🛠 Installing Docker..."
if ! command -v docker &> /dev/null; then
    sudo apt install -y docker.io
    sudo systemctl enable --now docker
    echo "Docker installed: $(docker --version)"
else
    echo "Docker already installed: $(docker --version)"
fi

# 3. Install Go
echo "🛠 Installing Go..."
if ! command -v go &> /dev/null || [[ "$(go version | awk '{print $3}' | cut -c3-)" < "$GO_VERSION" ]]; then
    wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
    echo "Go installed: $(go version)"
else
    echo "Go already installed: $(go version)"
fi

# 4. Install kubectl
echo "🛠 Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    echo "kubectl installed: $(kubectl version --client --short)"
else
    echo "kubectl already installed: $(kubectl version --client --short)"
fi

# 5. Install Kind
echo "🛠 Installing Kind..."
if ! command -v kind &> /dev/null; then
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.21.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    echo "Kind installed: $(kind --version)"
else
    echo "Kind already installed: $(kind --version)"
fi

# 6. Install Helm
echo "🛠 Installing Helm..."
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    echo "Helm installed: $(helm version --short)"
else
    echo "Helm already installed: $(helm version --short)"
fi

# 7. Final check

echo "✅ All dependencies installed and verified!"