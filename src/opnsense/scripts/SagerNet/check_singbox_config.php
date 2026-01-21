<?php
/**
 * Check singbox configuration from base64-encoded parameter
 * Usage: php check_singbox_config.php <base64_encoded_config>
 */

if ($argc < 2) {
    echo "Error: No configuration provided\n";
    exit(1);
}

$encodedConfig = $argv[1];
$config = base64_decode($encodedConfig, true);

if ($config === false) {
    echo "Error: Invalid base64 encoding\n";
    exit(1);
}

// Create temp file for config
$tempDir = sys_get_temp_dir();
$tempConfig = tempnam($tempDir, 'singbox_config_');

try {
    if (file_put_contents($tempConfig, $config) === false) {
        echo "Error: Failed to write temporary config file\n";
        exit(1);
    }

    // Run singbox check
    $output = [];
    $returnCode = 0;
    exec("/usr/local/bin/singbox check -c " . escapeshellarg($tempConfig) . " 2>&1", $output, $returnCode);

    echo implode("\n", $output) . "\n";
    exit($returnCode);
} finally {
    // Cleanup temp file
    if (file_exists($tempConfig)) {
        unlink($tempConfig);
    }
}
