<?php
/**
 * SehatAI Pakistan - Admin Dashboard & Doctor Verification Controller
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth_middleware.php';
require_once __DIR__ . '/../middleware/role_middleware.php';

class AdminController {
    private PDO $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    /**
     * GET /api/admin/metrics
     * Overall system KPIs
     */
    public function getMetrics(): void {
        $authUser = AuthMiddleware::authenticate();
        RoleMiddleware::requireAdmin($authUser);

        $patientsCount = (int)$this->db->query("SELECT COUNT(*) FROM users WHERE role = 'patient'")->fetchColumn();
        $verifiedDocs = (int)$this->db->query("SELECT COUNT(*) FROM doctor_profiles WHERE verification_status = 'verified'")->fetchColumn();
        $pendingDocs = (int)$this->db->query("SELECT COUNT(*) FROM doctor_profiles WHERE verification_status = 'pending'")->fetchColumn();
        $totalConsultations = (int)$this->db->query("SELECT COUNT(*) FROM consultations")->fetchColumn();
        $activeConsultations = (int)$this->db->query("SELECT COUNT(*) FROM consultations WHERE status = 'in_progress'")->fetchColumn();
        $emergencyAlerts = (int)$this->db->query("SELECT COUNT(*) FROM emergency_alerts")->fetchColumn();
        $pendingEmergencies = (int)$this->db->query("SELECT COUNT(*) FROM emergency_alerts WHERE status = 'pending'")->fetchColumn();

        sendSuccess('Admin system metrics retrieved.', [
            'total_patients' => $patientsCount,
            'verified_doctors' => $verifiedDocs,
            'pending_verifications' => $pendingDocs,
            'total_consultations' => $totalConsultations,
            'active_consultations' => $activeConsultations,
            'total_emergency_alerts' => $emergencyAlerts,
            'pending_emergencies' => $pendingEmergencies,
        ]);
    }

    /**
     * GET /api/admin/doctors
     * List all doctors with their verification status
     */
    public function getDoctors(): void {
        $authUser = AuthMiddleware::authenticate();
        RoleMiddleware::requireAdmin($authUser);

        $status = $_GET['status'] ?? '';

        $sql = "SELECT u.id, u.full_name, u.email, u.phone, u.city,
                       d.specialization, d.qualification, d.experience_years, 
                       d.pmdc_number, d.verification_status, d.is_online, 
                       d.hospital_affiliation
                FROM users u
                JOIN doctor_profiles d ON u.id = d.user_id";

        $params = [];
        if (!empty($status)) {
            $sql .= " WHERE d.verification_status = :status";
            $params[':status'] = $status;
        }

        $sql .= " ORDER BY (d.verification_status = 'pending') DESC, d.user_id DESC";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $doctors = $stmt->fetchAll();

        sendSuccess('Doctors retrieved for admin.', $doctors);
    }

    /**
     * POST /api/admin/verify-doctor
     * Approve or reject doctor PMDC credentials
     */
    public function verifyDoctor(): void {
        $authUser = AuthMiddleware::authenticate();
        RoleMiddleware::requireAdmin($authUser);

        $input = json_decode(file_get_contents('php://input'), true) ?? [];
        $doctorId = isset($input['doctor_id']) ? (int)$input['doctor_id'] : 0;
        $status = strtolower(trim($input['status'] ?? ''));

        if ($doctorId <= 0) {
            sendError('Valid doctor_id is required.');
        }

        if (!in_array($status, ['verified', 'rejected', 'pending'], true)) {
            sendError('Status must be verified, rejected, or pending.');
        }

        $checkStmt = $this->db->prepare("SELECT user_id FROM doctor_profiles WHERE user_id = :id");
        $checkStmt->execute([':id' => $doctorId]);
        if (!$checkStmt->fetch()) {
            sendError('Doctor profile not found.', 404);
        }

        $updateStmt = $this->db->prepare("UPDATE doctor_profiles SET verification_status = :status WHERE user_id = :id");
        $updateStmt->execute([
            ':status' => $status,
            ':id' => $doctorId
        ]);

        sendSuccess("Doctor PMDC verification status updated to {$status}.", [
            'doctor_id' => $doctorId,
            'verification_status' => $status
        ]);
    }

    /**
     * GET /api/admin/emergency-logs
     */
    public function getEmergencyLogs(): void {
        $authUser = AuthMiddleware::authenticate();
        RoleMiddleware::requireAdmin($authUser);

        $stmt = $this->db->query(
            "SELECT a.*, u.full_name as patient_name, u.phone as patient_phone
             FROM emergency_alerts a
             JOIN users u ON a.patient_id = u.id
             ORDER BY a.created_at DESC"
        );
        $logs = $stmt->fetchAll();

        sendSuccess('Emergency logs retrieved.', $logs);
    }

    /**
     * POST /api/admin/emergency-alert-status
     * Acknowledge or resolve an emergency alert (admin only).
     * Allowed statuses: reviewed, resolved.
     */
    public function updateEmergencyAlertStatus(): void {
        $authUser = AuthMiddleware::authenticate();
        RoleMiddleware::requireAdmin($authUser);

        $input = json_decode(file_get_contents('php://input'), true) ?? [];
        $alertId = isset($input['alert_id']) ? (int)$input['alert_id'] : 0;
        $status = strtolower(trim($input['status'] ?? ''));

        if ($alertId <= 0) {
            sendError('Valid alert_id is required.');
        }

        if (!in_array($status, ['reviewed', 'resolved'], true)) {
            sendError('Status must be reviewed or resolved.');
        }

        $checkStmt = $this->db->prepare("SELECT id FROM emergency_alerts WHERE id = :id");
        $checkStmt->execute([':id' => $alertId]);
        if (!$checkStmt->fetch()) {
            sendError('Emergency alert not found.', 404);
        }

        $updateStmt = $this->db->prepare("UPDATE emergency_alerts SET status = :status WHERE id = :id");
        $updateStmt->execute([
            ':status' => $status,
            ':id' => $alertId,
        ]);

        sendSuccess("Emergency alert #{$alertId} status updated to {$status}.", [
            'alert_id' => $alertId,
            'status' => $status,
        ]);
    }
}
