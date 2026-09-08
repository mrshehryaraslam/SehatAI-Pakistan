<?php
/**
 * SehatAI Pakistan - Role Verification Middleware
 */

declare(strict_types=1);

require_once __DIR__ . '/../utils/response.php';

class RoleMiddleware {
    public static function requireRole(array $user, array $allowedRoles): void {
        $userRole = strtolower($user['role'] ?? '');
        $allowed = array_map('strtolower', $allowedRoles);

        if (!in_array($userRole, $allowed, true)) {
            sendError('Forbidden: You do not have permission to access this resource.', 403);
        }
    }

    public static function requirePatient(array $user): void {
        self::requireRole($user, ['patient']);
    }

    public static function requireDoctor(array $user): void {
        self::requireRole($user, ['doctor']);
    }

    public static function requireAdmin(array $user): void {
        self::requireRole($user, ['admin']);
    }
}
