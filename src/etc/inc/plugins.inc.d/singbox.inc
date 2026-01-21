<?php
function singbox_services()
{
    $services = array();
    $services[] = array(
        'name' => 'singbox',
        'description' => gettext('singbox'),
        'configd' => array(
            'restart' => array('singbox restart'),
            'start' => array('singbox start'),
            'stop' => array('singbox stop'),
        ),
        'pidfile' => '/var/run/singbox.pid'
    );
    return $services;
}
