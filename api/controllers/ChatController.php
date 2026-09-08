<?php
/**
 * SehatAI Pakistan - Chat Controller (REST Message Synchronization)
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth_middleware.php';

class ChatController {
    private PDO $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    /**
     * GET /api/consultations/{id}/messages
     * Fetches conversation history. Optionally filters by ?after_id=XX for fast polling.
     */
    public function getMessages(int $consultationId): void {
        $authUser = AuthMiddleware::authenticate();
        $afterId = isset($_GET['after_id']) ? (int)$_GET['after_id'] : 0;

        // Verify participant access (Patient or Doctor or Admin)
        $cStmt = $this->db->prepare("SELECT patient_id, doctor_id FROM consultations WHERE id = :id");
        $cStmt->execute([':id' => $consultationId]);
        $consultation = $cStmt->fetch();

        if (!$consultation) {
            sendError('Consultation not found.', 404);
        }

        if ($authUser['role'] !== 'admin' && 
            $authUser['id'] !== (int)$consultation['patient_id'] && 
            $authUser['id'] !== (int)$consultation['doctor_id']) {
            sendError('Access denied to this consultation thread.', 403);
        }

        $sql = "SELECT m.id, m.consultation_id, m.sender_id, m.sender_role, m.message, 
                       m.is_emergency_notice, m.created_at,
                       u.full_name as sender_name
                FROM chat_messages m
                JOIN users u ON m.sender_id = u.id
                WHERE m.consultation_id = :cid";

        if ($afterId > 0) {
            $sql .= " AND m.id > :after_id";
        }

        $sql .= " ORDER BY m.id ASC";

        $stmt = $this->db->prepare($sql);
        $params = [':cid' => $consultationId];
        if ($afterId > 0) {
            $params[':after_id'] = $afterId;
        }

        $stmt->execute($params);
        $messages = $stmt->fetchAll();

        // Format for Flutter ConsultationChatScreen
        $formatted = array_map(function ($msg) use ($authUser) {
            return [
                'id' => (int)$msg['id'],
                'consultation_id' => (int)$msg['consultation_id'],
                'sender_id' => (int)$msg['sender_id'],
                'sender_name' => $msg['sender_name'],
                'sender_role' => $msg['sender_role'],
                'message' => $msg['message'],
                'is_emergency_notice' => (bool)$msg['is_emergency_notice'],
                'is_me' => ((int)$msg['sender_id'] === (int)$authUser['id']),
                'created_at' => $msg['created_at'],
            ];
        }, $messages);

        sendSuccess('Messages retrieved.', $formatted);
    }

    /**
     * POST /api/consultations/{id}/messages
     * Sends a new chat message
     */
    public function sendMessage(int $consultationId): void {
        $authUser = AuthMiddleware::authenticate();
        $input = json_decode(file_get_contents('php://input'), true) ?? [];

        $message = trim($input['message'] ?? '');
        $isEmergency = isset($input['is_emergency_notice']) ? (int)(bool)$input['is_emergency_notice'] : 0;

        if (empty($message)) {
            sendError('Message content cannot be empty.');
        }

        // Verify participant access
        $cStmt = $this->db->prepare("SELECT patient_id, doctor_id FROM consultations WHERE id = :id");
        $cStmt->execute([':id' => $consultationId]);
        $consultation = $cStmt->fetch();

        if (!$consultation) {
            sendError('Consultation not found.', 404);
        }

        if ($authUser['role'] !== 'admin' && 
            $authUser['id'] !== (int)$consultation['patient_id'] && 
            $authUser['id'] !== (int)$consultation['doctor_id']) {
            sendError('Access denied to this consultation thread.', 403);
        }

        $insertStmt = $this->db->prepare(
            "INSERT INTO chat_messages (consultation_id, sender_id, sender_role, message, is_emergency_notice, created_at)
             VALUES (:cid, :sid, :role, :msg, :is_em, NOW())"
        );
        $insertStmt->execute([
            ':cid' => $consultationId,
            ':sid' => $authUser['id'],
            ':role' => $authUser['role'],
            ':msg' => $message,
            ':is_em' => $isEmergency
        ]);

        $messageId = (int)$this->db->lastInsertId();

        sendSuccess('Message sent.', [
            'id' => $messageId,
            'consultation_id' => $consultationId,
            'sender_id' => (int)$authUser['id'],
            'sender_name' => $authUser['full_name'],
            'sender_role' => $authUser['role'],
            'message' => $message,
            'is_emergency_notice' => (bool)$isEmergency,
            'is_me' => true,
            'created_at' => date('Y-m-d H:i:s')
        ], 201);
    }
}
