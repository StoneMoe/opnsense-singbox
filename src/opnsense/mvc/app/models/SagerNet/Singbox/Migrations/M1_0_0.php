<?php

namespace SagerNet\Singbox\Migrations;

use OPNsense\Base\BaseModelMigration;
use OPNsense\Core\Config;
use SagerNet\Singbox\Singbox;

class M1_0_0 extends BaseModelMigration
{
    /**
     * Migrate from old OPNsense/singbox config to new SagerNet/singbox config
     * - If new config exists: just delete old config
     * - If new config doesn't exist: migrate data from old to new, then delete old
     * @param $model
     */
    public function run($model)
    {
        if ($model instanceof Singbox) {
            $config = Config::getInstance()->object();

            // Check if old config exists
            if (empty($config->OPNsense->singbox)) {
                parent::run($model);
                return;
            }

            $oldConfig = $config->OPNsense->singbox;

            // Check if new config already exists
            $newConfigExists = !empty($config->SagerNet->singbox->general);

            // If new config doesn't exist, migrate data from old config
            if (!$newConfigExists) {
                if (!empty($oldConfig->general->enabled)) {
                    $model->general->enabled->setValue((string) $oldConfig->general->enabled);
                }
                if (!empty($oldConfig->general->config)) {
                    $model->general->config->setValue((string) $oldConfig->general->config);
                }
            }

            // Remove old config key
            unset($config->OPNsense->singbox);

            parent::run($model);
        }
    }
}
