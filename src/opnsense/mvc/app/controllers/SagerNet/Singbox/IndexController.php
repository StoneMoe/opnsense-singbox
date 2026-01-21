<?php
namespace SagerNet\Singbox;

class IndexController extends \OPNsense\Base\IndexController
{
    public function indexAction()
    {
        $this->view->generalForm = $this->getForm("general");
        $this->view->pick('SagerNet/Singbox/index');
    }
}