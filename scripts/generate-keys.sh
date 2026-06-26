#!/bin/bash
# Generate RSA 3072-bit JWT key pair for DysonNetwork
# Requires: openssl
# Run: bash scripts/generate-keys.sh

DIR="$(cd "$(dirname "$0")/.." && pwd)/keys"
mkdir -p "$DIR"

openssl genpkey -algorithm RSA -out "$DIR/private_key.pem" -pkeyopt rsa_keygen_bits:3072
openssl rsa -pubout -in "$DIR/private_key.pem" -out "$DIR/public_key.pem"

echo "Keys generated in $DIR"
echo "WARNING: Never commit private_key.pem to version control!"
