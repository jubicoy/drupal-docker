if (file_exists(__DIR__ . '/settings.local.php')) {
   include __DIR__ . '/settings.local.php';
 }
$settings['trusted_host_patterns'] = array('.*',);

