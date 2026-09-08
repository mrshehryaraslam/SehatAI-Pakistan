<?php
/**
 * SehatAI Pakistan - Emergency SOS Controller
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth_middleware.php';
require_once __DIR__ . '/../middleware/role_middleware.php';

class EmergencyController {
    private PDO $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    /**
     * POST /api/emergency/sos
     * Log urgent emergency SOS request for the authenticated patient.
     *
     * - Only patients can trigger SOS; the alert is always bound to the
     *   authenticated patient (real patient, never fabricated).
     * - Coordinates are stored ONLY when the client supplies valid values —
     *   missing/invalid location is stored as NULL, never a fake position.
     */
    public function logSos(): void {
        $authUser = AuthMiddleware::authenticate();
        RoleMiddleware::requirePatient($authUser);

        $input = json_decode(file_get_contents('php://input'), true) ?? [];

        $patientId = (int)$authUser['id'];
        $symptoms = trim((string)($input['symptom_description'] ?? $input['symptoms'] ?? ''));
        if ($symptoms === '') {
            $symptoms = 'Urgent emergency SOS triggered';
        }

        $riskLevel = strtolower(trim((string)($input['risk_level'] ?? 'high')));
        if (!in_array($riskLevel, ['low', 'moderate', 'high'], true)) {
            // Safe default: an unclassifiable SOS is treated as an emergency.
            $riskLevel = 'high';
        }

        $latitude = $this->sanitizeCoordinate($input['latitude'] ?? null, -90.0, 90.0);
        $longitude = $this->sanitizeCoordinate($input['longitude'] ?? null, -180.0, 180.0);

        $city = trim((string)($input['city'] ?? ''));
        if ($city === '') {
            $city = $this->resolvePatientCity($patientId);
        }

        try {
            $stmt = $this->db->prepare(
                "INSERT INTO emergency_alerts (patient_id, symptom_description, risk_level, latitude, longitude, city, status, created_at)
                 VALUES (:pid, :sym, :risk, :lat, :lng, :city, 'pending', NOW())"
            );
            $stmt->execute([
                ':pid' => $patientId,
                ':sym' => $symptoms,
                ':risk' => $riskLevel,
                ':lat' => $latitude,
                ':lng' => $longitude,
                ':city' => $city,
            ]);
        } catch (Throwable $e) {
            error_log('[EmergencyController] SOS insert failed: ' . $e->getMessage());
            sendError('Emergency SOS could not be recorded. Please call Rescue 1122 directly.', 500);
        }

        $alertId = (int)$this->db->lastInsertId();

        sendSuccess('Emergency SOS alert registered in the regional healthcare network.', [
            'alert_id' => $alertId,
            'patient_id' => $patientId,
            'status' => 'pending',
            'city' => $city,
            'helpline' => '1122 (Rescue) / 1020 (Civil Emergency)',
            'recorded_at' => date('Y-m-d H:i:s'),
        ], 201);
    }

    /**
     * GET /api/emergency/alerts
     * Patients retrieve ONLY their own alerts. Admins retrieve all alerts.
     */
    public function getAlerts(): void {
        $authUser = AuthMiddleware::authenticate();
        $role = strtolower((string)($authUser['role'] ?? ''));

        if ($role === 'patient') {
            $stmt = $this->db->prepare(
                "SELECT a.*, u.full_name as patient_name, u.phone as patient_phone
                 FROM emergency_alerts a
                 JOIN users u ON a.patient_id = u.id
                 WHERE a.patient_id = :pid
                 ORDER BY a.created_at DESC"
            );
            $stmt->execute([':pid' => (int)$authUser['id']]);
            sendSuccess('Emergency alerts retrieved.', $stmt->fetchAll());
        }

        RoleMiddleware::requireAdmin($authUser);

        $stmt = $this->db->query(
            "SELECT a.*, u.full_name as patient_name, u.phone as patient_phone
             FROM emergency_alerts a
             JOIN users u ON a.patient_id = u.id
             ORDER BY a.created_at DESC"
        );
        $alerts = $stmt->fetchAll();

        sendSuccess('Emergency alerts retrieved.', $alerts);
    }

    /**
     * Returns the coordinate as float when it is a valid number inside the
     * given range, NULL otherwise (never fabricates a location).
     */
    private function sanitizeCoordinate(mixed $value, float $min, float $max): ?float {
        if (!is_numeric($value)) {
            return null;
        }
        $coordinate = (float)$value;
        if ($coordinate < $min || $coordinate > $max) {
            return null;
        }
        return $coordinate;
    }

    /**
     * Resolves the city from the real patient profile when the client did
     * not send one. Falls back to 'Unknown' — never invents a city.
     */
    private function resolvePatientCity(int $patientId): string {
        try {
            $stmt = $this->db->prepare("SELECT city FROM users WHERE id = :pid");
            $stmt->execute([':pid' => $patientId]);
            $row = $stmt->fetch();
            $city = trim((string)($row['city'] ?? ''));
            return $city !== '' ? $city : 'Unknown';
        } catch (Throwable $e) {
            return 'Unknown';
        }
    }
}
