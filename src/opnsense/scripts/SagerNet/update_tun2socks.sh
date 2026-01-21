#!/bin/sh
# Update hev-socks5-tunnel binary to the latest version
# Downloads from GitHub releases

set -e

BINARY_PATH="/usr/local/bin/hev-socks5-tunnel"
TEMP_DIR=$(mktemp -d)
ARCH="freebsd-x86_64"

cleanup() {
    rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

echo "Fetching latest hev-socks5-tunnel release info..."

# Get latest release info from GitHub API
RELEASE_INFO=$(fetch -qo - "https://api.github.com/repos/heiher/hev-socks5-tunnel/releases/latest")
if [ -z "${RELEASE_INFO}" ]; then
    echo "Error: Failed to fetch release info"
    exit 1
fi

# Extract version tag
VERSION=$(echo "${RELEASE_INFO}" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
if [ -z "${VERSION}" ]; then
    echo "Error: Failed to parse version"
    exit 1
fi

echo "Latest version: ${VERSION}"

# Get current version
if [ -x "${BINARY_PATH}" ]; then
    CURRENT_VERSION=$("${BINARY_PATH}" --version 2>/dev/null | head -1 || echo "unknown")
    echo "Current version: ${CURRENT_VERSION}"
else
    echo "Current version: not installed"
fi

# Construct download URL (hev-socks5-tunnel releases are direct binaries, not zips)
DOWNLOAD_URL="https://github.com/heiher/hev-socks5-tunnel/releases/download/${VERSION}/hev-socks5-tunnel-${ARCH}"
echo "Downloading from: ${DOWNLOAD_URL}"

# Download the binary directly
NEW_BINARY="${TEMP_DIR}/hev-socks5-tunnel"
fetch -o "${NEW_BINARY}" "${DOWNLOAD_URL}"
if [ ! -f "${NEW_BINARY}" ]; then
    echo "Error: Failed to download binary"
    exit 1
fi

# Backup current binary if it exists
if [ -f "${BINARY_PATH}" ]; then
    echo "Backing up current binary..."
    cp "${BINARY_PATH}" "${BINARY_PATH}.bak"
fi

# Install new binary
echo "Installing new binary..."
cp "${NEW_BINARY}" "${BINARY_PATH}"
chmod +x "${BINARY_PATH}"

# Verify installation
NEW_VERSION=$("${BINARY_PATH}" --version 2>/dev/null | head -1 || echo "unknown")
echo "Installed version: ${NEW_VERSION}"

echo "Update complete!"
