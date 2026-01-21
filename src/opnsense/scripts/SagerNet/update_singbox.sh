#!/bin/sh
# Update sing-box binary to the latest version
# Downloads from GitHub releases

set -e

BINARY_PATH="/usr/local/bin/singbox"
TEMP_DIR=$(mktemp -d)
ARCH="freebsd-amd64"

cleanup() {
    rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

echo "Fetching latest sing-box release info..."

# Get latest release info from GitHub API
RELEASE_INFO=$(fetch -qo - "https://api.github.com/repos/SagerNet/sing-box/releases/latest")
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
    CURRENT_VERSION=$("${BINARY_PATH}" version 2>/dev/null | head -1 | grep -o 'v[0-9.]*' || echo "unknown")
    echo "Current version: ${CURRENT_VERSION}"
else
    echo "Current version: not installed"
fi

# Extract version number without 'v' prefix for download URL
VERSION_NUM=$(echo "${VERSION}" | sed 's/^v//')

# Construct download URL
DOWNLOAD_URL="https://github.com/SagerNet/sing-box/releases/download/${VERSION}/sing-box-${VERSION_NUM}-${ARCH}.tar.gz"
echo "Downloading from: ${DOWNLOAD_URL}"

# Download the release
ARCHIVE_PATH="${TEMP_DIR}/singbox.tar.gz"
fetch -o "${ARCHIVE_PATH}" "${DOWNLOAD_URL}"
if [ ! -f "${ARCHIVE_PATH}" ]; then
    echo "Error: Failed to download archive"
    exit 1
fi

# Extract the binary
echo "Extracting..."
tar -xzf "${ARCHIVE_PATH}" -C "${TEMP_DIR}"

# Find the binary in extracted files
NEW_BINARY=$(find "${TEMP_DIR}" -name "sing-box" -type f | head -1)
if [ -z "${NEW_BINARY}" ] || [ ! -f "${NEW_BINARY}" ]; then
    echo "Error: Binary not found in archive"
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
NEW_VERSION=$("${BINARY_PATH}" version 2>/dev/null | head -1 || echo "unknown")
echo "Installed version: ${NEW_VERSION}"

echo "Update complete!"
