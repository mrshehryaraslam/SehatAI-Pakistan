<?php
/**
 * SehatAI Pakistan - Automated InfinityFree Cloud Deployment & Diagnostic Tool
 *
 * Visit this script in your web browser after uploading your files to InfinityFree:
 * Example: https://yourdomain.epizy.com/api/install_infinityfree.php
 */

declare(strict_types=1);

error_reporting(E_ALL);
ini_set('display_errors', '1');

// Load environment configurations
require_once __DIR__ . '/config/env_loader.php';

$host     = app_env('DB_HOST', 'sql113.infinityfree.com');
$port     = app_env('DB_PORT', '3306');
$dbName   = app_env('DB_NAME', 'if0_42859111_sehatai');
$username = app_env('DB_USER', 'if0_42859111');
$password = app_env('DB_PASS', 'YHFa0M2hXRamLEC');

$action = $_GET['action'] ?? 'status';
$error = null;
$success = null;
$tableStats = [];
$dbConnected = false;

try {
    $dsn = "mysql:host={$host};port={$port};dbname={$dbName};charset=utf8mb4";
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_TIMEOUT => 10,
    ]);
    $dbConnected = true;

    if ($action === 'migrate') {
        $sqlPath = __DIR__ . '/database/infinityfree_setup.sql';
        if (!file_exists($sqlPath)) {
            throw new Exception("SQL setup file not found at: {$sqlPath}");
        }
        $sql = file_get_contents($sqlPath);
        
        // Execute queries
        $pdo->exec($sql);
        $success = "Database schema and seed data successfully initialized in {$dbName}!";
    }

    // Retrieve existing tables & count
    $stmt = $pdo->query("SHOW TABLES");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    foreach ($tables as $table) {
        $cntStmt = $pdo->query("SELECT COUNT(*) FROM `{$table}`");
        $tableStats[$table] = (int)$cntStmt->fetchColumn();
    }
} catch (Throwable $e) {
    $error = $e->getMessage();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SehatAI Pakistan - InfinityFree Cloud Installer</title>
    <style>
        :root {
            --primary: #0F766E;
            --primary-dark: #115E59;
            --bg: #0B0F19;
            --card: #161F30;
            --text: #F3F4F6;
            --text-muted: #9CA3AF;
            --success: #10B981;
            --danger: #EF4444;
            --border: #2D3748;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
        body { background: var(--bg); color: var(--text); padding: 40px 20px; display: flex; justify-content: center; }
        .container { max-width: 800px; width: 100%; }
        .header { text-align: center; margin-bottom: 30px; }
        .header h1 { font-size: 26px; color: #38BDF8; font-weight: 700; margin-bottom: 8px; }
        .header p { color: var(--text-muted); font-size: 14px; }
        .card { background: var(--card); border: 1px solid var(--border); border-radius: 12px; padding: 24px; margin-bottom: 24px; box-shadow: 0 10px 25px -5px rgba(0,0,0,0.5); }
        .badge { display: inline-block; padding: 4px 10px; border-radius: 20px; font-size: 12px; font-weight: 600; text-transform: uppercase; }
        .badge-success { background: rgba(16, 185, 129, 0.2); color: var(--success); border: 1px solid var(--success); }
        .badge-danger { background: rgba(239, 68, 68, 0.2); color: var(--danger); border: 1px solid var(--danger); }
        .param-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-top: 15px; }
        .param-item { background: rgba(255,255,255,0.03); padding: 12px; border-radius: 8px; border: 1px solid rgba(255,255,255,0.05); }
        .param-label { font-size: 11px; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px; }
        .param-val { font-size: 14px; font-weight: 600; color: #FFF; margin-top: 4px; font-family: monospace; }
        .alert { padding: 14px 18px; border-radius: 8px; margin-bottom: 20px; font-size: 14px; line-height: 1.5; }
        .alert-danger { background: rgba(239, 68, 68, 0.15); border: 1px solid var(--danger); color: #FCA5A5; }
        .alert-success { background: rgba(16, 185, 129, 0.15); border: 1px solid var(--success); color: #6EE7B7; }
        .btn { display: inline-block; background: var(--primary); color: white; padding: 12px 24px; border-radius: 8px; text-decoration: none; font-weight: 600; font-size: 14px; transition: 0.2s; border: none; cursor: pointer; }
        .btn:hover { background: var(--primary-dark); }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { text-align: left; padding: 10px 14px; border-bottom: 1px solid var(--border); font-size: 13px; }
        th { color: var(--text-muted); text-transform: uppercase; font-size: 11px; }
        td.count { text-align: right; font-weight: 600; color: #38BDF8; font-family: monospace; }
        .footer-note { font-size: 12px; color: var(--text-muted); line-height: 1.6; margin-top: 15px; }
        code { background: rgba(255,255,255,0.1); padding: 2px 6px; border-radius: 4px; font-size: 12px; color: #FBBF24; }
    </style>
</head>
<body>
<div class="container">
    <div class="header">
        <h1>SehatAI Pakistan - Cloud Deployment</h1>
        <p>InfinityFree Production Setup & Diagnostic Dashboard</p>
    </div>

    <?php if ($error): ?>
        <div class="alert alert-danger">
            <strong>Database Connection Error:</strong><br>
            <?= htmlspecialchars($error) ?>
        </div>
    <?php endif; ?>

    <?php if ($success): ?>
        <div class="alert alert-success">
            <strong>Success:</strong> <?= htmlspecialchars($success) ?>
        </div>
    <?php endif; ?>

    <div class="card">
        <div style="display: flex; justify-content: space-between; align-items: center;">
            <h2 style="font-size: 18px;">MySQL Connection Status</h2>
            <?php if ($dbConnected): ?>
                <span class="badge badge-success">Connected</span>
            <?php else: ?>
                <span class="badge badge-danger">Offline</span>
            <?php endif; ?>
        </div>

        <div class="param-grid">
            <div class="param-item">
                <div class="param-label">Database Host</div>
                <div class="param-val"><?= htmlspecialchars($host) ?></div>
            </div>
            <div class="param-item">
                <div class="param-label">Database Name</div>
                <div class="param-val"><?= htmlspecialchars($dbName) ?></div>
            </div>
            <div class="param-item">
                <div class="param-label">Database User</div>
                <div class="param-val"><?= htmlspecialchars($username) ?></div>
            </div>
            <div class="param-item">
                <div class="param-label">Server Port</div>
                <div class="param-val"><?= htmlspecialchars($port) ?></div>
            </div>
        </div>

        <div style="margin-top: 24px; display: flex; gap: 12px;">
            <?php if ($dbConnected): ?>
                <a href="?action=migrate" class="btn" onclick="return confirm('Initialize database schema and seed default verified accounts?');">
                    Initialize / Seed Database
                </a>
                <a href="index.php" class="btn" style="background: #3B82F6;" target="_blank">
                    Open API Health Check
                </a>
            <?php endif; ?>
        </div>
    </div>

    <?php if ($dbConnected): ?>
    <div class="card">
        <h2 style="font-size: 18px; margin-bottom: 12px;">Database Tables & Records</h2>
        <?php if (empty($tableStats)): ?>
            <p style="color: var(--text-muted); font-size: 14px;">No tables found yet. Click <strong>"Initialize / Seed Database"</strong> above to run migrations.</p>
        <?php else: ?>
            <table>
                <thead>
                    <tr>
                        <th>Table Name</th>
                        <th style="text-align: right;">Total Records</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($tableStats as $tbl => $cnt): ?>
                        <tr>
                            <td><code><?= htmlspecialchars($tbl) ?></code></td>
                            <td class="count"><?= $cnt ?></td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        <?php endif; ?>

        <div class="footer-note">
            <strong>Default Test Credentials Installed:</strong><br>
            - Admin: <code>admin@sehat.ai</code> | Password: <code>Admin@123</code><br>
            - Doctor: <code>ayesha.siddiqui@sehat.ai</code> | Password: <code>Doctor@123</code><br>
            - Patient: <code>ahmed.khan@gmail.com</code> | Password: <code>Patient@123</code>
        </div>
    </div>
    <?php endif; ?>
</div>
</body>
</html>
