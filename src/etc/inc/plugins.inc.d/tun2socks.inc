<?php
function tun2socks_services()
{
    $services = array();
    $services[] = array(
        'name' => 'tun2socks',
        'description' => gettext('tun2socks gVisor TCP/IP stack'),
        'configd' => array(
            'restart' => array('tun2socks restart'),
            'start' => array('tun2socks start'),
            'stop' => array('tun2socks stop'),
        ),
        'pidfile' => '/var/run/tun2socks.pid'
    );
    return $services;
}
