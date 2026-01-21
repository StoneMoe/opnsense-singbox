#!/bin/sh
# Check singbox configuration from base64-encoded parameter
# Usage: check_singbox_config.sh <base64_encoded_config>

set -e

TEMP_DIR=$(mktemp -d)
TEMP_CONFIG="${TEMP_DIR}/config.json"

cleanup() {
    rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

# Decode config from base64 parameter
if [ -z "$1" ]; then
    echo "Error: No configuration provided"
    exit 1
fi

echo "$1" | b64decode > "${TEMP_CONFIG}"

# Run singbox check
/usr/local/bin/singbox check -c "${TEMP_CONFIG}" 2>&1

exit 0
