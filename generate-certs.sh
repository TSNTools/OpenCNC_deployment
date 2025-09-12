#!/bin/bash

set -e

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

mkdir -p "$SCRIPT_DIR/certs"

echo "🔐 Generating Certificate Authority (CA)..."
openssl genrsa -out "$SCRIPT_DIR/certs/ca.key" 4096
openssl req -x509 -new -nodes -key "$SCRIPT_DIR/certs/ca.key" -sha256 -days 3650 -out "$SCRIPT_DIR/certs/ca.crt" \
  -subj "/C=DE/ST=Berlin/L=Berlin/O=OpenCNC/OU=CA/CN=opencnc-ca"

echo "🔐 Generating server private key and CSR..."
openssl genrsa -out "$SCRIPT_DIR/certs/opencnc.key" 4096
openssl req -new -key "$SCRIPT_DIR/certs/opencnc.key" -out "$SCRIPT_DIR/certs/opencnc.csr" \
  -subj "/C=DE/ST=Berlin/L=Berlin/O=OpenCNC/OU=Microservices/CN=opencnc"

echo "📝 Writing certificate extensions to certs/opencnc.ext..."
cat > "$SCRIPT_DIR/certs/opencnc.ext" <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names

[alt_names]
DNS.1 = opencnc
DNS.2 = *.opencnc.svc
DNS.3 = *.opencnc.svc.cluster.local
EOF

echo "✅ Signing certificate with CA..."
openssl x509 -req -in "$SCRIPT_DIR/certs/opencnc.csr" -CA "$SCRIPT_DIR/certs/ca.crt" -CAkey "$SCRIPT_DIR/certs/ca.key" -CAcreateserial \
  -out "$SCRIPT_DIR/certs/opencnc.crt" -days 365 -sha256 -extfile "$SCRIPT_DIR/certs/opencnc.ext"

echo "🎉 Certificates generated in certs/: opencnc.crt, opencnc.key, ca.crt"

