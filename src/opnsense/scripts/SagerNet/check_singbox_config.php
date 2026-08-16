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
$returnCode = 1;

try {
    if (file_put_contents($tempConfig, $config) === false) {
        echo "Error: Failed to write temporary config file\n";
    } else {
        // Run singbox check and return its message to the UI.
        $output = [];
        exec("/usr/local/bin/singbox check -c " . escapeshellarg($tempConfig) . " 2>&1", $output, $returnCode);

        if ($returnCode !== 0) {
            echo "Error: sing-box rejected the configuration\n";
            echo implode("\n", $output) . "\n";
        } else {
            echo "Configuration is valid\n";
        }
    }
} finally {
    // exit() skips finally blocks, so leave the process only after this cleanup.
    if (file_exists($tempConfig)) {
        unlink($tempConfig);
    }
}

exit($returnCode);
