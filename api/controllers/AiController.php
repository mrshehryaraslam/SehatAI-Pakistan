<?php
/**
 * SehatAI Pakistan - AI Medical Assistant & Triage Controller
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../utils/token_helper.php';
require_once __DIR__ . '/../services/GeminiService.php';

class AiController {
    private PDO $db;
    private GeminiService $geminiService;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
        $this->geminiService = new GeminiService();
    }

    /**
     * POST /api/ai/triage
     * Main endpoint for live AI triage conversation & analysis.
     */
    public function triage(): void {
        $input = json_decode(file_get_contents('php://input'), true) ?? [];

        $message = trim((string)($input['message'] ?? $input['text'] ?? $input['symptoms'] ?? ''));
        if (empty($message)) {
            sendError('Message or symptom description is required.', 422);
        }

        $sessionId = trim((string)($input['session_id'] ?? ''));
        if (empty($sessionId)) {
            $sessionId = 'sess_' . bin2hex(random_bytes(8)) . '_' . time();
        }

        $language = trim((string)($input['language'] ?? 'roman_urdu'));

        // 1. Identify User (Optional Auth - Supports both logged in and guest users)
        $userId = null;
        $authUser = $this->tryGetAuthUser();
        if ($authUser) {
            $userId = (int)$authUser['id'];
        }

        // 2. Fetch or prepare Patient Profile Context
        $patientProfile = $input['patient_profile'] ?? null;
        if (!is_array($patientProfile) || empty(array_filter($patientProfile))) {
            if ($userId) {
                $patientProfile = $this->getPatientProfileFromDb($userId);
            }
        }

        // 3. Prepare Conversation History
        $history = $input['conversation_history'] ?? [];
        if (!is_array($history) || empty($history)) {
            $history = $this->loadRecentHistoryForSession($sessionId);
        }

        // 4. Run Gemini / Triage Analysis
        $triageResult = $this->geminiService->triage($message, $language, $history, $patientProfile);

        // 5. Persist Assessment & Messages in MySQL
        $assessmentId = $this->persistTriage(
            $userId,
            $sessionId,
            $language,
            $message,
            $triageResult,
            $patientProfile
        );

        $responsePayload = [
            'session_id' => $sessionId,
            'assessment_id' => $assessmentId,
            'reply' => $triageResult['reply'],
            'detected_symptoms' => $triageResult['detected_symptoms'] ?? [],
            'risk_level' => $triageResult['risk_level'] ?? 'low',
            'requires_doctor' => (bool)($triageResult['requires_doctor'] ?? false),
            'emergency_warning' => $triageResult['emergency_warning'] ?? null,
            'disclaimer' => $triageResult['disclaimer'] ?? 'Preliminary guidance only.',
            'patient_context_applied' => !empty($patientProfile),
            'ai_configured' => !empty(GEMINI_API_KEY),
            'timestamp' => date('c'),
            '_source' => $triageResult['_source'] ?? 'gemini_engine',
        ];

        sendSuccess('AI triage assessment completed successfully.', $responsePayload);
    }

    /**
     * Optional JWT Auth extraction (returns null if unauthenticated).
     */
    private function tryGetAuthUser(): ?array {
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
        if (empty($authHeader) && isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
        }
        if (empty($authHeader) && isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
            $authHeader = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        }

        if (empty($authHeader) || !preg_match('/Bearer\s(\S+)/i', $authHeader, $matches)) {
            return null;
        }

        return TokenHelper::verifyToken($matches[1]);
    }

    /**
     * Fetch patient profile context from DB.
     */
    private function getPatientProfileFromDb(int $userId): ?array {
        try {
            $stmt = $this->db->prepare("
                SELECT u.full_name, u.city, p.age, p.gender, p.blood_group, p.allergies, p.chronic_conditions
                FROM users u
                LEFT JOIN patient_profiles p ON u.id = p.user_id
                WHERE u.id = :uid
            ");
            $stmt->execute([':uid' => $userId]);
            $row = $stmt->fetch();
            if ($row) {
                return [
                    'age' => $row['age'],
                    'gender' => $row['gender'],
                    'blood_group' => $row['blood_group'],
                    'allergies' => $row['allergies'],
                    'chronic_conditions' => $row['chronic_conditions'],
                    'city' => $row['city'],
                ];
            }
        } catch (Throwable $e) {
            error_log('[AiController] Error fetching patient profile: ' . $e->getMessage());
        }
        return null;
    }

    /**
     * Load recent conversation turns for session.
     */
    private function loadRecentHistoryForSession(string $sessionId): array {
        try {
            $stmt = $this->db->prepare("
                SELECT role, message
                FROM ai_triage_messages
                WHERE session_id = :sid
                ORDER BY id ASC
                LIMIT 20
            ");
            $stmt->execute([':sid' => $sessionId]);
            return $stmt->fetchAll() ?: [];
        } catch (Throwable $e) {
            error_log('[AiController] Error loading history: ' . $e->getMessage());
            return [];
        }
    }

    /**
     * Store assessment & messages into MySQL.
     */
    private function persistTriage(
        ?int $userId,
        string $sessionId,
        string $language,
        string $userMessage,
        array $triageResult,
        ?array $patientProfile
    ): int {
        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("
                INSERT INTO ai_triage_assessments 
                (user_id, session_id, language, primary_complaint, detected_symptoms, risk_level, requires_doctor, emergency_warning, ai_reply, disclaimer, patient_context)
                VALUES
                (:user_id, :session_id, :language, :primary_complaint, :detected_symptoms, :risk_level, :requires_doctor, :emergency_warning, :ai_reply, :disclaimer, :patient_context)
            ");

            $stmt->execute([
                ':user_id' => $userId,
                ':session_id' => $sessionId,
                ':language' => $language,
                ':primary_complaint' => $userMessage,
                ':detected_symptoms' => json_encode($triageResult['detected_symptoms'] ?? [], JSON_UNESCAPED_UNICODE),
                ':risk_level' => $triageResult['risk_level'] ?? 'low',
                ':requires_doctor' => (int)(bool)($triageResult['requires_doctor'] ?? false),
                ':emergency_warning' => $triageResult['emergency_warning'] ?? null,
                ':ai_reply' => $triageResult['reply'] ?? '',
                ':disclaimer' => $triageResult['disclaimer'] ?? '',
                ':patient_context' => $patientProfile ? json_encode($patientProfile, JSON_UNESCAPED_UNICODE) : null,
            ]);

            $assessmentId = (int)$this->db->lastInsertId();

            // Insert User Message
            $msgStmt = $this->db->prepare("
                INSERT INTO ai_triage_messages (assessment_id, session_id, user_id, role, message)
                VALUES (:assessment_id, :session_id, :user_id, :role, :message)
            ");
            $msgStmt->execute([
                ':assessment_id' => $assessmentId,
                ':session_id' => $sessionId,
                ':user_id' => $userId,
                ':role' => 'user',
                ':message' => $userMessage,
            ]);

            // Insert Model Response Message
            $msgStmt->execute([
                ':assessment_id' => $assessmentId,
                ':session_id' => $sessionId,
                ':user_id' => $userId,
                ':role' => 'model',
                ':message' => $triageResult['reply'] ?? '',
            ]);

            $this->db->commit();
            return $assessmentId;
        } catch (Throwable $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            error_log('[AiController] Error persisting triage: ' . $e->getMessage());
            return 0;
        }
    }
}
