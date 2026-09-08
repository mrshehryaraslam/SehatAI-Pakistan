<?php
/**
 * SehatAI Pakistan - Standard JSON Response Utility
 */

declare(strict_types=1);

function sendResponse(string $status, string $message, mixed $data = null, int $httpCode = 200): void {
    http_response_code($httpCode);
    header('Content-Type: application/json; charset=utf-8');
    
    $payload = [
        'status' => $status,
        'message' => $message,
    ];

    if ($data !== null) {
        $payload['data'] = $data;
    }

    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

function sendSuccess(string $message, mixed $data = null, int $httpCode = 200): void {
    sendResponse('success', $message, $data, $httpCode);
}

function sendError(string $message, int $httpCode = 400, mixed $data = null): void {
    sendResponse('error', $message, $data, $httpCode);
}
