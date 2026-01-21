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
                    $backend->configdRun("template reload SagerNet/Singbox");

                    $enabled = (string) $mdl->getNodeByReference('general.enabled') === "1" ? "YES" : "NO";
                    $cmd = $enabled === "YES" ? "singbox restart" : "singbox stop";
                    $backend->configdRun($cmd);

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
                $response = trim($backend->configdRun("singbox check", array($encodedConfig)));
                $result['result'] = "ok";
                $result['output'] = $response;
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
     * Update sing-box binary
     */
    public function updateSingboxAction()
    {
        $result = array("result" => "failed");

        if ($this->request->isPost()) {
            $backend = new Backend();
            $response = $backend->configdRun("singbox update");
            $result['result'] = "ok";
            $result['output'] = $response;
        } else {
            $result['error'] = 'POST method required';
        }
        return $result;
    }

    /**
     * Update tun2socks binary
     */
    public function updateTun2socksAction()
    {
        $result = array("result" => "failed");

        if ($this->request->isPost()) {
            $backend = new Backend();
            $response = $backend->configdRun("tun2socks update");
            $result['result'] = "ok";
            $result['output'] = $response;
        } else {
            $result['error'] = 'POST method required';
        }
        return $result;
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
        $result = array("result" => "failed");

        if ($this->request->isPost()) {
            if ($this->request->hasFiles()) {
                $files = $this->request->getUploadedFiles();
                if (count($files) > 0) {
                    $file = $files[0];
                    $tempPath = $file->getTempName();
                    $binaryPath = "/usr/local/bin/singbox";

                    // Backup current binary
                    if (file_exists($binaryPath)) {
                        copy($binaryPath, $binaryPath . ".bak");
                    }

                    // Move uploaded file to binary location
                    if (move_uploaded_file($tempPath, $binaryPath)) {
                        chmod($binaryPath, 0755);

                        // Verify it's executable
                        $backend = new Backend();
                        $version = trim($backend->configdRun("singbox version"));

                        $result['result'] = "ok";
                        $result['output'] = "Binary uploaded successfully.\nVersion: " . $version;
                    } else {
                        $result['error'] = "Failed to install binary";
                    }
                } else {
                    $result['error'] = "No file uploaded";
                }
            } else {
                $result['error'] = "No file in request";
            }
        } else {
            $result['error'] = "POST method required";
        }
        return $result;
    }

    /**
     * Upload and install hev-socks5-tunnel binary
     */
    public function uploadTun2socksAction()
    {
        $result = array("result" => "failed");

        if ($this->request->isPost()) {
            if ($this->request->hasFiles()) {
                $files = $this->request->getUploadedFiles();
                if (count($files) > 0) {
                    $file = $files[0];
                    $tempPath = $file->getTempName();
                    $binaryPath = "/usr/local/bin/hev-socks5-tunnel";

                    // Backup current binary
                    if (file_exists($binaryPath)) {
                        copy($binaryPath, $binaryPath . ".bak");
                    }

                    // Move uploaded file to binary location
                    if (move_uploaded_file($tempPath, $binaryPath)) {
                        chmod($binaryPath, 0755);

                        // Verify it's executable
                        $backend = new Backend();
                        $version = trim($backend->configdRun("tun2socks version"));

                        $result['result'] = "ok";
                        $result['output'] = "Binary uploaded successfully.\nVersion: " . $version;
                    } else {
                        $result['error'] = "Failed to install binary";
                    }
                } else {
                    $result['error'] = "No file uploaded";
                }
            } else {
                $result['error'] = "No file in request";
            }
        } else {
            $result['error'] = "POST method required";
        }
        return $result;
    }
}