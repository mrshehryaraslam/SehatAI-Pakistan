<?php
/**
 * SehatAI Pakistan - Consultation Controller
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth_middleware.php';
require_once __DIR__ . '/../middleware/role_middleware.php';
require_once __DIR__ . '/HealthContinuityController.php';

class ConsultationController {
    private PDO $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    /**
     * POST /api/consultations/request
     * Patient initiates a consultation
     */
    public function requestConsultation(): void {
        $authUser = AuthMiddleware::authenticate();
        RoleMiddleware::requirePatient($authUser);

        $input = json_decode(file_get_contents('php://input'), true) ?? [];
        $doctorId = isset($input['doctor_id']) ? (int)$input['doctor_id'] : null;
        $symptoms = trim($input['symptoms'] ?? '');
        $riskLevel = strtolower(trim($input['risk_level'] ?? 'moderate'));

        if (empty($symptoms)) {
            sendError('Symptoms description is required.');
        }

        if (!in_array($riskLevel, ['low', 'moderate', 'high'], true)) {
            $riskLevel = 'moderate';
        }

        // If no doctor specified, auto-assign to first online verified doctor
        if (!$doctorId) {
            $stmt = $this->db->query("SELECT user_id FROM doctor_profiles WHERE verification_status = 'verified' AND is_online = 1 LIMIT 1");
            $doc = $stmt->fetch();
            if ($doc) {
                $doctorId = (int)$doc['user_id'];
            } else {
                // Pick any verified doctor
                $stmt = $this->db->query("SELECT user_id FROM doctor_profiles WHERE verification_status = 'verified' LIMIT 1");
                $doc = $stmt->fetch();
                $doctorId = $doc ? (int)$doc['user_id'] : 2; // fallback to Dr. Ayesha
            }
        }

        $insertStmt = $this->db->prepare(
            "INSERT INTO consultations (patient_id, doctor_id, symptoms, risk_level, status, requested_at)
             VALUES (:patient_id, :doctor_id, :symptoms, :risk_level, 'pending', NOW())"
        );
        $insertStmt->execute([
            ':patient_id' => $authUser['id'],
            ':doctor_id' => $doctorId,
            ':symptoms' => $symptoms,
            ':risk_level' => $riskLevel
        ]);

        $consultationId = (int)$this->db->lastInsertId();

        // Add initial system message in chat
        $chatStmt = $this->db->prepare(
            "INSERT INTO chat_messages (consultation_id, sender_id, sender_role, message, is_emergency_notice)
             VALUES (:cid, :sid, 'patient', :msg, :is_emergency)"
        );
        $chatStmt->execute([
            ':cid' => $consultationId,
            ':sid' => $authUser['id'],
            ':msg' => "Patient Consultation Request: " . $symptoms,
            ':is_emergency' => ($riskLevel === 'high') ? 1 : 0
        ]);

        sendSuccess('Consultation request submitted successfully.', [
            'consultation_id' => $consultationId,
            'doctor_id' => $doctorId,
            'status' => 'pending',
            'risk_level' => $riskLevel
        ], 201);
    }

    /**
     * GET /api/consultations/doctor
     * Doctor fetches assigned or pending consultations
     */
    public function getDoctorConsultations(): void {
        $authUser = AuthMiddleware::authenticate();
        RoleMiddleware::requireDoctor($authUser);

        $status = $_GET['status'] ?? '';

        $sql = "SELECT c.*, 
                       u.full_name as patient_name, u.phone as patient_phone, u.city as patient_city,
                       p.age as patient_age, p.gender as patient_gender, p.blood_group as patient_blood_group,
                       p.allergies as patient_allergies, p.chronic_conditions as patient_chronic_conditions
                FROM consultations c
                JOIN users u ON c.patient_id = u.id
                LEFT JOIN patient_profiles p ON u.id = p.user_id
                WHERE c.doctor_id = :doctor_id";

        $params = [':doctor_id' => $authUser['id']];
        if (!empty($status)) {
            $sql .= " AND c.status = :status";
            $params[':status'] = $status;
        }

        $sql .= " ORDER BY c.requested_at DESC";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $consultations = $stmt->fetchAll();

        sendSuccess('Doctor consultations retrieved.', $consultations);
    }

    /**
     * GET /api/consultations/patient
     * Patient fetches their consultations
     */
    public function getPatientConsultations(): void {
        $authUser = AuthMiddleware::authenticate();
        RoleMiddleware::requirePatient($authUser);

        $stmt = $this->db->prepare(
            "SELECT c.*, 
                    u.full_name as doctor_name, u.phone as doctor_phone,
                    d.specialization as doctor_specialization, d.hospital_affiliation as doctor_hospital
             FROM consultations c
             JOIN users u ON c.doctor_id = u.id
             JOIN doctor_profiles d ON u.id = d.user_id
             WHERE c.patient_id = :patient_id
             ORDER BY c.requested_at DESC"
        );
        $stmt->execute([':patient_id' => $authUser['id']]);
        $consultations = $stmt->fetchAll();

        sendSuccess('Patient consultations retrieved.', $consultations);
    }

    /**
     * POST /api/consultations/{id}/accept
     * Doctor accepts a consultation request (Checks PMDC verification status!)
     */
    public function acceptConsultation(int $id): void {
        $authUser = AuthMiddleware::authenticate();
        RoleMiddleware::requireDoctor($authUser);

        // 1. Check Doctor PMDC Verification Status
        $docStmt = $this->db->prepare("SELECT verification_status FROM doctor_profiles WHERE user_id = :id");
        $docStmt->execute([':id' => $authUser['id']]);
        $docProfile = $docStmt->fetch();

        if (!$docProfile || $docProfile['verification_status'] !== 'verified') {
            sendError('Forbidden: Unverified doctors cannot accept consultations until PMDC credentials are approved by Admin.', 403);
        }

        // 2. Fetch Consultation
        $cStmt = $this->db->prepare("SELECT * FROM consultations WHERE id = :id");
        $cStmt->execute([':id' => $id]);
        $consultation = $cStmt->fetch();

        if (!$consultation) {
            sendError('Consultation not found.', 404);
        }

        // 3. Update status to in_progress
        $updateStmt = $this->db->prepare(
            "UPDATE consultations 
             SET status = 'in_progress', doctor_id = :doctor_id 
             WHERE id = :id"
        );
        $updateStmt->execute([
            ':doctor_id' => $authUser['id'],
            ':id' => $id
        ]);

        // Send chat notification
        $chatStmt = $this->db->prepare(
            "INSERT INTO chat_messages (consultation_id, sender_id, sender_role, message)
             VALUES (:cid, :sid, 'doctor', :msg)"
        );
        $chatStmt->execute([
            ':cid' => $id,
            ':sid' => $authUser['id'],
            ':msg' => "Dr. " . $authUser['full_name'] . " has accepted your consultation request and is now connected."
        ]);

        // Health Continuity Engine: Auto-generate AI Patient Brief for the doctor
        // Must run BEFORE sendSuccess() because sendSuccess() calls exit().
        try {
            $continuity = new HealthContinuityController();
            $continuity->generatePatientBriefInternal($id, 'english');
        } catch (Throwable $e) {
            error_log('[Consultation] Auto brief generation failed: ' . $e->getMessage());
        }

        sendSuccess('Consultation accepted successfully.', [
            'consultation_id' => $id,
            'status' => 'in_progress'
        ]);
    }

    /**
     * POST /api/consultations/{id}/reject
     * Doctor rejects (declines) a consultation request.
     */
    public function rejectConsultation(int $id): void {
        $authUser = AuthMiddleware::authenticate();
        RoleMiddleware::requireDoctor($authUser);

        // 1. Fetch Consultation
        $cStmt = $this->db->prepare("SELECT * FROM consultations WHERE id = :id");
        $cStmt->execute([':id' => $id]);
        $consultation = $cStmt->fetch();

        if (!$consultation) {
            sendError('Consultation not found.', 404);
        }

        if ($consultation['status'] !== 'pending') {
            sendError('Only pending consultations can be rejected.', 422);
        }

        // 2. Update status to cancelled
        $updateStmt = $this->db->prepare(
            "UPDATE consultations SET status = 'cancelled' WHERE id = :id"
        );
        $updateStmt->execute([':id' => $id]);

        // 3. Add system chat message
        $chatStmt = $this->db->prepare(
            "INSERT INTO chat_messages (consultation_id, sender_id, sender_role, message)
             VALUES (:cid, :sid, 'system', :msg)"
        );
        $chatStmt->execute([
            ':cid' => $id,
            ':sid' => $authUser['id'],
            ':msg' => "Dr. " . $authUser['full_name'] . " has declined this consultation request.",
        ]);

        sendSuccess('Consultation rejected.', [
            'consultation_id' => $id,
            'status' => 'cancelled',
        ]);
    }

    /**
     * POST /api/consultations/{id}/status
     * Update consultation status (e.g. completed, cancelled).
     * Allowed: assigned doctor, assigned patient, or admin.
     */
    public function updateStatus(int $id): void {
        $authUser = AuthMiddleware::authenticate();

        // 1. Fetch consultation
        $cStmt = $this->db->prepare("SELECT * FROM consultations WHERE id = :id");
        $cStmt->execute([':id' => $id]);
        $consultation = $cStmt->fetch();

        if (!$consultation) {
            sendError('Consultation not found.', 404);
        }

        // 2. Enforce authorization: assigned doctor, assigned patient, or admin
        $isAssignedDoctor = ($authUser['role'] === 'doctor' && (int)$consultation['doctor_id'] === (int)$authUser['id']);
        $isAssignedPatient = ($authUser['role'] === 'patient' && (int)$consultation['patient_id'] === (int)$authUser['id']);
        $isAdmin = ($authUser['role'] === 'admin');

        if (!$isAssignedDoctor && !$isAssignedPatient && !$isAdmin) {
            sendError('Forbidden: Only the assigned doctor, assigned patient, or an administrator can update consultation status.', 403);
        }

        $input = json_decode(file_get_contents('php://input'), true) ?? [];

        // 3. Patients may only cancel pending or end (complete) active consultations
        if ($isAssignedPatient && !$isAdmin) {
            $allowedForPatient = ['cancelled', 'completed'];
            $requestedStatus = strtolower(trim($input['status'] ?? ''));
            if (!in_array($requestedStatus, $allowedForPatient, true)) {
                sendError('Patients can only cancel or complete consultations.', 403);
            }
        }

        $status = strtolower(trim($input['status'] ?? 'completed'));
        $notes = trim($input['doctor_notes'] ?? '');

        if (!in_array($status, ['pending', 'in_progress', 'completed', 'cancelled'], true)) {
            sendError('Invalid consultation status.');
        }

        $stmt = $this->db->prepare(
            "UPDATE consultations 
             SET status = :status, doctor_notes = IF(:notes != '', :notes2, doctor_notes) 
             WHERE id = :id"
        );
        $stmt->execute([
            ':status' => $status,
            ':notes' => $notes,
            ':notes2' => $notes,
            ':id' => $id
        ]);

        // Health Continuity Engine: Auto-generate AI Care Plan when consultation is completed
        // Must run BEFORE sendSuccess() because sendSuccess() calls exit().
        if ($status === 'completed') {
            try {
                $prescCheck = $this->db->prepare("SELECT id FROM prescriptions WHERE consultation_id = :cid LIMIT 1");
                $prescCheck->execute([':cid' => $id]);
                if ($prescCheck->fetch()) {
                    $continuity = new HealthContinuityController();
                    $continuity->generateCarePlanInternal($id, 'english');
                }
            } catch (Throwable $e) {
                error_log('[Consultation] Auto care plan generation failed: ' . $e->getMessage());
            }
        }

        sendSuccess('Consultation status updated.', [
            'consultation_id' => $id,
            'status' => $status
        ]);
    }
}
