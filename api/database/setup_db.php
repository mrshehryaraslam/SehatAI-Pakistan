<?php
/**
 * SehatAI Pakistan - Database Initializer & Migration Script
 * Runs schema and seeds the database with verified credentials.
 */

declare(strict_types=1);

// Load .env for database credentials (two levels above /api/database)
require_once __DIR__ . '/../config/env_loader.php';
// env_loader.php resolves .env from project root automatically

$host = getenv('DB_HOST') ?: '127.0.0.1';
$port = getenv('DB_PORT') ?: '3306';
$user = getenv('DB_USER') ?: 'root';
$pass = getenv('DB_PASS') ?: '';
$dbName = getenv('DB_NAME') ?: 'sehatai_pakistan';

echo "=== SehatAI Pakistan Database Initializer ===\n";

try {
    // 1. Connect without database to create DB if not exists
    $pdo = new PDO("mysql:host={$host};port={$port};charset=utf8mb4", $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);

    echo "[1/4] Creating database `{$dbName}` if not exists...\n";
    $pdo->exec("CREATE DATABASE IF NOT EXISTS `{$dbName}` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;");
    $pdo->exec("USE `{$dbName}`;");

    // 2. Run Schema
    echo "[2/4] Executing schema.sql...\n";
    $schemaSql = file_get_contents(__DIR__ . '/schema.sql');
    // Strip multi queries or execute directly
    $pdo->exec($schemaSql);
    echo "      Tables created successfully.\n";

    // 3. Run Seeds
    echo "[3/4] Executing seed.sql...\n";
    $seedSql = file_get_contents(__DIR__ . '/seed.sql');
    $pdo->exec($seedSql);
    echo "      Seed data populated successfully.\n";

    // 4. Update Password Hashes with clean standard test passwords
    echo "[4/4] Setting secure password hashes for standard accounts...\n";
    $passwords = [
        1 => 'Admin@123',     // admin
        2 => 'Doctor@123',    // Dr. Ayesha
        3 => 'Doctor@123',    // Dr. Bilal
        4 => 'Doctor@123',    // Dr. Fatima
        5 => 'Doctor@123',    // Dr. Tariq (Pending)
        6 => 'Patient@123',   // Ahmed Khan
        7 => 'Patient@123',   // Zainab Bibi
    ];

    $stmt = $pdo->prepare("UPDATE `users` SET `password_hash` = :hash WHERE `id` = :id");
    foreach ($passwords as $id => $plain) {
        $hash = password_hash($plain, PASSWORD_BCRYPT);
        $stmt->execute([':hash' => $hash, ':id' => $id]);
    }

    echo "\n=== Database Setup Complete! ===\n";
    echo "Accounts ready (see .env.example for default test credentials):\n";
    echo " - Admin:   admin@sehat.ai\n";
    echo " - Doctors: ayesha.siddiqui@sehat.ai (Verified)\n";
    echo "            tariq.mehmood@sehat.ai   (Pending PMDC)\n";
    echo " - Patient: ahmed.khan@gmail.com\n";
} catch (PDOException $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    exit(1);
}
