<?php
/**
 * SehatAI Pakistan - App Constants & Configurations
 */

declare(strict_types=1);

define('APP_NAME', 'SehatAI Pakistan API');
define('APP_VERSION', '2.0.0');

require_once __DIR__ . '/env_loader.php';

// JWT Secret — MUST be set via environment variable in production
// Fallback only for local XAMPP development; never commit a real secret here.
define('JWT_SECRET', app_env('JWT_SECRET', 'sehat_ai_pakistan_super_secure_key_2026_jwt_token_auth_remote_healthcare'));
define('TOKEN_EXPIRY_SECONDS', 86400 * 30); // 30 days

// Gemini API Configuration
if (!defined('GEMINI_API_KEY')) {
    define('GEMINI_API_KEY', app_env('GEMINI_API_KEY', ''));
}
if (!defined('GEMINI_MODEL')) {
    define('GEMINI_MODEL', app_env('GEMINI_MODEL', 'gemini-3.5-flash'));
}

