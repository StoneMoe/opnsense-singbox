<?php
/**
 * Update sing-box binary to the latest version
 * Downloads from GitHub releases
 */

define('BINARY_PATH', '/usr/local/bin/singbox');
define('ARCH', 'freebsd-amd64');
define('GITHUB_API_URL', 'https://api.github.com/repos/StoneMoe/sing-box-freebsd/releases/latest');

function cleanup($tempDir)
{
    if (is_dir($tempDir)) {
        $files = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($tempDir, RecursiveDirectoryIterator::SKIP_DOTS),
            RecursiveIteratorIterator::CHILD_FIRST
        );
        foreach ($files as $file) {
            if ($file->isDir()) {
                rmdir($file->getRealPath());
            } else {
                unlink($file->getRealPath());
            }
        }
        rmdir($tempDir);
    }
}

function fetchUrl($url)
{
    $context = stream_context_create([
        'http' => [
            'header' => "User-Agent: OPNsense-Singbox-Updater\r\n",
            'timeout' => 30
        ]
    ]);
    return @file_get_contents($url, false, $context);
}

function downloadFile($url, $destination)
{
    $context = stream_context_create([
        'http' => [
            'header' => "User-Agent: OPNsense-Singbox-Updater\r\n",
            'timeout' => 300,
            'follow_location' => true
        ]
    ]);
    $content = @file_get_contents($url, false, $context);
    if ($content === false) {
        return false;
    }
    return file_put_contents($destination, $content) !== false;
}

// Create temp directory
$tempDir = sys_get_temp_dir() . '/singbox_update_' . uniqid();
if (!mkdir($tempDir, 0755, true)) {
    echo "Error: Failed to create temp directory\n";
    exit(1);
}

register_shutdown_function('cleanup', $tempDir);

echo "Fetching latest sing-box release info...\n";

// Get latest release info from GitHub API
$releaseInfo = fetchUrl(GITHUB_API_URL);
if ($releaseInfo === false) {
    echo "Error: Failed to fetch release info\n";
    exit(1);
}

$release = json_decode($releaseInfo, true);
if (!$release || !isset($release['tag_name'])) {
    echo "Error: Failed to parse release info\n";
    exit(1);
}

$version = $release['tag_name'];
echo "Latest version: {$version}\n";

// Get current version
if (is_executable(BINARY_PATH)) {
    $currentVersion = trim(shell_exec(BINARY_PATH . " version 2>/dev/null | head -1 | grep -o 'v[0-9.]*'") ?: 'unknown');
    echo "Current version: {$currentVersion}\n";
} else {
    echo "Current version: not installed\n";
}

// Extract version number without 'v' prefix for download URL
$versionNum = ltrim($version, 'v');

// Construct download URL
$downloadUrl = "https://github.com/StoneMoe/sing-box-freebsd/releases/download/{$version}/sing-box-" . ARCH;
echo "Downloading from: {$downloadUrl}\n";

// Download the release
$downloadedBinary = "{$tempDir}/sing-box";
if (!downloadFile($downloadUrl, $downloadedBinary)) {
    echo "Error: Failed to download binary\n";
    exit(1);
}

$newBinary = $downloadedBinary;
chmod($newBinary, 0755);

// Backup current binary if it exists
if (file_exists(BINARY_PATH)) {
    echo "Backing up current binary...\n";
    if (!copy(BINARY_PATH, BINARY_PATH . '.bak')) {
        echo "Warning: Failed to backup current binary\n";
    }
}

// Install new binary
echo "Installing new binary...\n";
if (!copy($newBinary, BINARY_PATH)) {
    echo "Error: Failed to install binary\n";
    exit(1);
}
chmod(BINARY_PATH, 0755);

// Verify installation
$newVersion = trim(shell_exec(BINARY_PATH . " version 2>/dev/null | head -1") ?: 'unknown');
echo "Installed version: {$newVersion}\n";

echo "Update complete!\n";
