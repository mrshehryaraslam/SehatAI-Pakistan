<?php
/**
 * SehatAI Pakistan - Authentication Middleware
 */

declare(strict_types=1);

require_once __DIR__ . '/../utils/token_helper.php';
require_once __DIR__ . '/../utils/response.php';

class AuthMiddleware {
    public static function authenticate(): array {
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

        // Fallback: PHP-CGI / XAMPP Apache may forward the header under these keys
        if (empty($authHeader) && isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
        }
        if (empty($authHeader) && isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
            $authHeader = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        }

        if (empty($authHeader)) {
            sendError('Authorization token is required.', 401);
        }

        if (!preg_match('/Bearer\s(\S+)/i', $authHeader, $matches)) {
            sendError('Invalid Authorization header format. Expected Bearer token.', 401);
        }

        $token = $matches[1];
        $user = TokenHelper::verifyToken($token);

        if (!$user) {
            sendError('Invalid or expired authorization token.', 401);
        }

        return $user;
    }
}
