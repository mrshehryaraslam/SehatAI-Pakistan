<?php
/**
 * SehatAI Pakistan — Minimal .env File Loader
 * Reads .env from project root and sets environment variables via putenv().
 * No Composer / external library required.
 */

declare(strict_types=1);

function loadDotEnv(string $envPath): void {
    if (!is_file($envPath)) {
        return;
    }

    $lines = file($envPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    if ($lines === false) {
        return;
    }

    foreach ($lines as $line) {
        $line = trim($line);
        // Skip comments
        if ($line === '' || $line[0] === '#' || $line[0] === ';') {
            continue;
        }
        // Parse KEY=VALUE
        $eqPos = strpos($line, '=');
        if ($eqPos === false) {
            continue;
        }
        $key   = trim(substr($line, 0, $eqPos));
        $value = trim(substr($line, $eqPos + 1));
        // Strip surrounding quotes
        if (strlen($value) >= 2) {
            $first = $value[0];
            $last  = $value[strlen($value) - 1];
            if (($first === '"' && $last === '"') || ($first === "'" && $last === "'")) {
                $value = substr($value, 1, -1);
            }
        }
        
        // Always populate in $_ENV and $_SERVER
        if (!isset($_ENV[$key])) {
            $_ENV[$key] = $value;
        }
        if (!isset($_SERVER[$key])) {
            $_SERVER[$key] = $value;
        }
        // Also putenv if function exists
        if (function_exists('putenv') && getenv($key) === false) {
            @putenv("{$key}={$value}");
        }
    }
}

/**
 * Universal environment variable accessor
 */
function app_env(string $key, string $default = ''): string {
    $val = getenv($key);
    if ($val !== false && $val !== '') {
        return (string)$val;
    }
    if (isset($_ENV[$key]) && $_ENV[$key] !== '') {
        return (string)$_ENV[$key];
    }
    if (isset($_SERVER[$key]) && $_SERVER[$key] !== '') {
        return (string)$_SERVER[$key];
    }
    return $default;
}

// Search order for .env files:
// 1. Root .env
// 2. api/.env
// 3. Root .env.production
// 4. api/.env.production
$possiblePaths = [
    dirname(__DIR__, 2) . '/.env',
    dirname(__DIR__, 1) . '/.env',
    dirname(__DIR__, 2) . '/.env.production',
    dirname(__DIR__, 1) . '/.env.production',
];

foreach ($possiblePaths as $path) {
    if (is_file($path)) {
        loadDotEnv($path);
        break; // stop at first matched active file
    }
}

