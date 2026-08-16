<?php
namespace SagerNet\Singbox\Api;

use OPNsense\Base\ApiControllerBase;
use OPNsense\Core\Backend;
use OPNsense\Core\Config;
use SagerNet\Singbox\Singbox;

class SettingsController extends ApiControllerBase
{
    public function getAction()
    {
        $mdl = new Singbox();
        $result = array();

        if ($mdl) {
            $general = array();
            $config = $mdl->getNodeByReference('general.config');
            if (!empty($config)) {
                $general['config'] = $config;
            }
            $enabled = $mdl->getNodeByReference('general.enabled');
            if ($enabled !== null) {
                $general['enabled'] = $enabled;
            }
            if (!empty($general)) {
                $mdl->setNodes(array('general' => $general));
            }
            $result['singbox'] = $mdl->getNodes();
        }
        return $result;
    }

    public function setAction()
    {
        $result = array("result" => "failed");

        if ($this->request->isPost()) {
            $mdl = new Singbox();
            $post_data = $this->request->getPost("singbox");

            if (is_array($post_data) && !empty($post_data)) {
                try {
                    $mdl->setNodes($post_data);
                    $mdl->serializeToConfig();
                    Config::getInstance()->save();

                    $backend = new Backend();
                    $enabled = (string) $mdl->getNodeByReference('general.enabled') === "1";

                    if (!$enabled) {
                        // Stop the TUN consumer first while the old rc.conf still enables both services.
                        $backend->configdRun("tun2socks stop");
                        $backend->configdRun("singbox stop");
                    }

                    $backend->configdRun("template reload SagerNet/Singbox");

                    if ($enabled) {
                        // sing-box must expose the local SOCKS listener before tun2socks starts.
                        $backend->configdRun("singbox restart");
                        // Avoid recreating proxytun0 on every ordinary configuration save.
                        $backend->configdRun("tun2socks start");
                    }

                    $result['result'] = "saved";
                } catch (\Exception $e) {
                    $result['error'] = '保存失败: ' . $e->getMessage();
                }
            } else {
                $result['error'] = '参数无效或为空';
            }
        } else {
            $result['error'] = '请求方法错误';
        }
        return $result;
    }

    /**
     * Test configuration without saving
     * Accepts config JSON in POST body and validates it
     */
    public function testAction()
    {
        $result = array("result" => "failed");

        if ($this->request->isPost()) {
            $config = $this->request->getPost("config");
            if (!empty($config)) {
                $backend = new Backend();
                // Pass config to check script via parameter (base64 encoded to avoid shell escaping issues)
                $encodedConfig = base64_encode($config);
                $response = trim($backend->configdpRun("singbox check", array($encodedConfig)));
                if ($response === '') {
                    $result['error'] = 'Configuration check returned no result';
                } elseif (strpos($response, 'Error:') === 0) {
                    $result['error'] = $response;
                } else {
                    $result['result'] = "ok";
                    $result['output'] = $response;
                }
            } else {
                $result['error'] = 'Configuration is empty';
            }
        } else {
            $result['error'] = 'POST method required';
        }
        return $result;
    }

    /**
     * Fetch recent log entries
     */
    public function logAction()
    {
        $backend = new Backend();
        $response = $backend->configdRun("singbox log");
        return array(
            "result" => "ok",
            "log" => $response
        );
    }

    /**
     * Get current binary versions
     */
    public function versionsAction()
    {
        $backend = new Backend();
        $singboxVersion = trim($backend->configdRun("singbox version"));
        $tun2socksVersion = trim($backend->configdRun("tun2socks version"));
        return array(
            "singbox" => $singboxVersion,
            "tun2socks" => $tun2socksVersion
        );
    }

    /**
     * Upload and install sing-box binary
     */
    public function uploadSingboxAction()
    {
        if (!$this->request->isPost()) {
            return array("result" => "failed", "error" => "POST method required");
        }
        if (empty($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
            return array("result" => "failed", "error" => "No file uploaded or upload error");
        }

        return $this->installUploadedBinary(
            $_FILES['file']['tmp_name'],
            "/usr/local/bin/singbox",
            "singbox version",
            "singbox restart",
            "singbox"
        );
    }

    /**
     * Upload and install tun2socks binary
     */
    public function uploadTun2socksAction()
    {
        if (!$this->request->isPost()) {
            return array("result" => "failed", "error" => "POST method required");
        }
        if (empty($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
            return array("result" => "failed", "error" => "No file uploaded or upload error");
        }

        return $this->installUploadedBinary(
            $_FILES['file']['tmp_name'],
            "/usr/local/bin/tun2socks",
            "tun2socks version",
            "tun2socks restart",
            "tun2socks"
        );
    }

    private function installUploadedBinary($tempPath, $binaryPath, $versionAction, $restartAction, $binaryName)
    {
        $candidatePath = $binaryPath . ".new";
        $backupPath = $binaryPath . ".bak";

        // Replace the path instead of writing over a binary that may still be running.
        if (!move_uploaded_file($tempPath, $candidatePath)) {
            return array("result" => "failed", "error" => "Failed to stage binary");
        }
        chmod($candidatePath, 0755);

        if (!$this->backupBinary($binaryPath, $backupPath)) {
            @unlink($candidatePath);
            return array("result" => "failed", "error" => "Failed to back up current binary");
        }
        if (!rename($candidatePath, $binaryPath)) {
            @unlink($candidatePath);
            return array("result" => "failed", "error" => "Failed to install binary");
        }

        $backend = new Backend();
        $version = trim($backend->configdRun($versionAction));
        if (!$this->isExpectedVersion($binaryName, $version)) {
            return $this->rejectUploadedBinary($binaryPath, $backupPath, $binaryName);
        }

        if ($this->isEnabled()) {
            $backend->configdRun($restartAction);
        }

        return array(
            "result" => "ok",
            "output" => "Binary uploaded successfully.\nVersion: " . $version
        );
    }

    private function isExpectedVersion($binaryName, $version)
    {
        if ($binaryName === "singbox") {
            return preg_match('/^[0-9]+\.[0-9]+(?:\.[0-9]+)?(?:[-+][^\s]+)?$/', $version) === 1;
        }

        return strpos($version, "tun2socks-") === 0;
    }

    private function backupBinary($binaryPath, $backupPath)
    {
        if (file_exists($binaryPath)) {
            return copy($binaryPath, $backupPath);
        }

        @unlink($backupPath);
        return !file_exists($backupPath);
    }

    private function rejectUploadedBinary($binaryPath, $backupPath, $binaryName)
    {
        if (!$this->restoreBinary($binaryPath, $backupPath)) {
            return array(
                "result" => "failed",
                "error" => "Uploaded file is invalid and the previous binary could not be restored"
            );
        }

        return array(
            "result" => "failed",
            "error" => "Uploaded file is not a valid " . $binaryName . " binary"
        );
    }

    private function restoreBinary($binaryPath, $backupPath)
    {
        if (file_exists($backupPath)) {
            return copy($backupPath, $binaryPath);
        }

        @unlink($binaryPath);
        return !file_exists($binaryPath);
    }

    private function isEnabled()
    {
        $mdl = new Singbox();
        return (string) $mdl->getNodeByReference('general.enabled') === "1";
    }
}
