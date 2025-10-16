<?php
header('Content-Type: text/plain; charset=UTF-8');

echo "=== Environment Variables Test ===\n\n";

echo "User: " . get_current_user() . "\n";
echo "UID: " . getmyuid() . "\n";
echo "GID: " . getmygid() . "\n";
echo "PHP Version: " . phpversion() . "\n\n";

echo "--- Environment Variables (getenv) ---\n";
echo "DB_HOST: '" . getenv("DB_HOST") . "'\n";
echo "DB_PORT: '" . getenv("DB_PORT") . "'\n";
echo "DB_USERNAME: '" . getenv("DB_USERNAME") . "'\n";
echo "DB_PASSWORD: '" . (getenv("DB_PASSWORD") ? '[SET-'.strlen(getenv("DB_PASSWORD")).'chars]' : '[EMPTY]') . "'\n";
echo "DB_DATABASE: '" . getenv("DB_DATABASE") . "'\n";
echo "DB_PERSONAL_DATABASE: '" . getenv("DB_PERSONAL_DATABASE") . "'\n";

echo "\n--- \$_ENV ---\n";
echo "DB_HOST: " . (isset($_ENV["DB_HOST"]) ? $_ENV["DB_HOST"] : "NOT SET") . "\n";
echo "DB_PORT: " . (isset($_ENV["DB_PORT"]) ? $_ENV["DB_PORT"] : "NOT SET") . "\n";
echo "DB_USERNAME: " . (isset($_ENV["DB_USERNAME"]) ? $_ENV["DB_USERNAME"] : "NOT SET") . "\n";

echo "\n--- \$_SERVER ---\n";
echo "DB_HOST: " . (isset($_SERVER["DB_HOST"]) ? $_SERVER["DB_HOST"] : "NOT SET") . "\n";
echo "DB_PORT: " . (isset($_SERVER["DB_PORT"]) ? $_SERVER["DB_PORT"] : "NOT SET") . "\n";
echo "DB_USERNAME: " . (isset($_SERVER["DB_USERNAME"]) ? $_SERVER["DB_USERNAME"] : "NOT SET") . "\n";

// Try loading .env
echo "\n--- Trying to load .env file ---\n";
$env_file = __DIR__ . "/.env";
echo ".env file path: " . $env_file . "\n";
echo ".env file exists: " . (file_exists($env_file) ? "YES" : "NO") . "\n";

if (file_exists($env_file)) {
    echo ".env file readable: " . (is_readable($env_file) ? "YES" : "NO") . "\n";
    echo ".env file size: " . filesize($env_file) . " bytes\n";
}

require __DIR__ . "/vendor/autoload.php";
try {
    $dotenv = new Dotenv\Dotenv(__DIR__);
    $dotenv->load();  // ใช้ safeLoad() แทน load() เพื่อไม่ error ถ้าไม่มีไฟล์ .env
    echo ".env load: SUCCESS\n";

    echo "\n--- After loading .env ---\n";
    echo "DB_HOST: '" . getenv("DB_HOST") . "'\n";
    echo "DB_PORT: '" . getenv("DB_PORT") . "'\n";
    echo "DB_USERNAME: '" . getenv("DB_USERNAME") . "'\n";
    echo "DB_PASSWORD: '" . (getenv("DB_PASSWORD") ? '[SET-'.strlen(getenv("DB_PASSWORD")).'chars]' : '[EMPTY]') . "'\n";
    echo "DB_DATABASE: '" . getenv("DB_DATABASE") . "'\n";
    echo "DB_PERSONAL_DATABASE: '" . getenv("DB_PERSONAL_DATABASE") . "'\n";
} catch (Exception $e) {
    echo ".env load: FAILED\n";
    echo "Error: " . $e->getMessage() . "\n";
}

echo "\n=== Test Complete ===\n";
?>
