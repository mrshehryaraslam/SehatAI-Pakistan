<?php
/**
 * SehatAI Pakistan - Token Authentication Helper (HMAC SHA256 Signed Tokens)
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/constants.php';

class TokenHelper {
    public static function generateToken(array $user): string {
        $payload = [
            'id' => (int)$user['id'],
            'email' => $user['email'] ?? '',
            'role' => $user['role'],
            'full_name' => $user['full_name'],
            'exp' => time() + TOKEN_EXPIRY_SECONDS
        ];

        $encodedPayload = base64_encode(json_encode($payload));
        $signature = hash_hmac('sha256', $encodedPayload, JWT_SECRET);

        return $encodedPayload . '.' . $signature;
    }

    public static function verifyToken(string $token): ?array {
        $parts = explode('.', $token);
        if (count($parts) !== 2) {
            return null;
        }

        [$encodedPayload, $providedSignature] = $parts;
        $expectedSignature = hash_hmac('sha256', $encodedPayload, JWT_SECRET);

        if (!hash_equals($expectedSignature, $providedSignature)) {
            return null;
        }

        $decodedJson = base64_decode($encodedPayload, true);
        if ($decodedJson === false) {
            return null;
        }

        $payload = json_decode($decodedJson, true);
        if (!is_array($payload) || !isset($payload['id'], $payload['role'], $payload['exp'])) {
            return null;
        }

        if ($payload['exp'] < time()) {
            return null; // Expired
        }

        return $payload;
    }
}
