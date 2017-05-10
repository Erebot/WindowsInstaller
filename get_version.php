<?php

if (!file_exists("./composer.lock")) {
    exit(1);
}

$found  = false;
$json   = json_decode(file_get_contents("./composer.lock"), true);
foreach ($json['packages'] as &$package) {
    if ($package['name'] === 'erebot/erebot') {
        $found = true;
        echo $package['version'] . PHP_EOL;
        break;
    }
}
unset($package);

exit($found ? 0 : 2);

