#!/bin/bash

# Check if a configuration file was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <config-file>"
    exit 1
fi

# Get the configuration file from the command line argument
CONFIG_FILE="$1"

# Generate the base name from the config file (e.g., myFRITZBox from myFRITZBox.cnf)
BASENAME=$(basename "$CONFIG_FILE" .cnf)

# Generate a new private key
openssl genrsa -out "${BASENAME}.key" 2048
if [ $? -ne 0 ]; then
    echo "Error generating private key."
    exit 1
fi

# Create the Certificate Signing Request (CSR)
openssl req -new -key "${BASENAME}.key" -out "${BASENAME}.csr" -config "$CONFIG_FILE"
if [ $? -ne 0 ]; then
    echo "Error generating CSR."
    exit 1
fi

# Generate the self-signed certificate
openssl x509 -req -days 365 -in "${BASENAME}.csr" -signkey "${BASENAME}.key" -out "${BASENAME}.crt" -extensions v3_req -extfile "$CONFIG_FILE"
if [ $? -ne 0 ]; then
    echo "Error generating self-signed certificate."
    exit 1
fi

echo "Private Key, CSR, and Self-Signed Certificate have been generated:"
echo "  - ${BASENAME}.key"
echo "  - ${BASENAME}.csr"
echo "  - ${BASENAME}.crt"
