<?php

chdir(__DIR__);
if ($_SERVER['argc'] != 2) {
    exit(1);
}

$composerDir    = $_SERVER['argv'][1];
$composer       = $composerDir . DIRECTORY_SEPARATOR . 'composer.phar';
$eol            = array('');
$main           = array('[main]');
$names          = array("[names]");
$versions       = array("[versions]");
$descriptions   = array("[descriptions]");

if (!file_exists($composer)) {
    exit(2);
}

// Add composer to the PATH
putenv("PATH=$composerDir" . PATH_SEPARATOR . getenv("PATH", true));
require("phar://$composer/vendor/autoload.php");
use Composer\Semver\Constraint\Constraint;

/**
 * Compare 2 versions.
 *
 * This function is used to sort the various available versions
 * of a package. It takes branches into account.
 */
function compare($a, $b)
{
    $ca1 = new Constraint('>', $a);
    $ca2 = new Constraint('==', $a);
    $cb  = new Constraint('==', $b);

    if ($ca1->matchSpecific($cb, true)) {
        return 1;
    }
    return $ca2->matchSpecific($cb, true) ? 0 : -1;
}

function sanitize($s)
{
    $subs = array();
    for ($i = 0; $i < 32; $i++) {
        $subs[chr($i)] = '';
    }
    return addcslashes(strtr($s, $subs), '\\"');
}

function get_metadata($pkg)
{
    $json           = json_decode(file_get_contents("https://packagist.org/p/$pkg.json"), true);
    $json           = array_pop($json["packages"]);
    $candidates     = array_keys($json);

    // Sort versions in descending order,
    // with stable releases appearing first.
    usort($candidates, "compare");
    $version        = current($candidates);
    $description    = $json[$version]['description'];
    return array(
        'name'          => sanitize($pkg),
        'version'       => sanitize($version),
        'description'   => sanitize($description),
    );
}


// Call Composer to retrieve the list of available modules
`composer init -n`;
$modules = explode("\n", trim(`composer show -n --no-ansi -a "erebot/*-module"`));
$modules = array_map("trim", $modules);
$skeleton = array_search("erebot/skeleton-module", $modules, true);
if ($skeleton !== false) {
    unset($modules[$skeleton]);
}
// Reindex the array
$modules = array_values($modules);

// Register the metadata for the core & modules
$metadata = get_metadata('erebot/erebot');
$names[]        = "core=" . '"' . $metadata['name'] . '"';
$versions[]     = "core=" . '"' . $metadata['version'] . '"';
$descriptions[] = "core=" . '"' . $metadata['description'] . '"';
foreach ($modules as $i => $name) {
    $metadata       = get_metadata($name);
    $names[]        = "module_$i=" . '"' . $metadata['name'] . '"';
    $versions[]     = "module_$i=" . '"' . $metadata['version'] . '"';
    $descriptions[] = "module_$i=" . '"' . $metadata['description'] . '"';
}
$main[]         = 'modules=' . count($modules);

$ini = array_merge($main, $eol, $names, $eol, $versions, $eol, $descriptions, $eol);
file_put_contents("./modules.ini", implode(PHP_EOL, $ini) . PHP_EOL);
exit(0);

