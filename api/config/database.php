<?php
/**
 * SehatAI Pakistan - Database Connection Configuration (PDO)
 */

declare(strict_types=1);

require_once __DIR__ . '/env_loader.php';

class Database {
    private string $host;
    private string $port;
    private string $dbName;
    private string $username;
    private string $password;
    private ?PDO $conn = null;

    public function __construct() {
        $this->host     = app_env('DB_HOST', '127.0.0.1');
        $this->port     = app_env('DB_PORT', '3306');
        $this->dbName   = app_env('DB_NAME', 'sehatai_pakistan');
        $this->username = app_env('DB_USER', 'root');
        $this->password = app_env('DB_PASS', '');
    }

    public function getConnection(): PDO {
        if ($this->conn === null) {
            try {
                $dsn = "mysql:host={$this->host};port={$this->port};dbname={$this->dbName};charset=utf8mb4";
                $this->conn = new PDO($dsn, $this->username, $this->password, [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false,
                ]);
            } catch (PDOException $e) {
                http_response_code(500);
                echo json_encode([
                    'status' => 'error',
                    'message' => 'Database connection failed: ' . $e->getMessage()
                ]);
                exit;
            }
        }
        return $this->conn;
    }
}
