<?php
/**
 * SehatAI Pakistan - Prescription Controller
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth_middleware.php';
require_once __DIR__ . '/../middleware/role_middleware.php';

class PrescriptionController {
    private PDO $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    /**
     * POST /api/prescriptions
     * Doctor creates a prescription for a patient.
     */
    public function store(): void {
        $authUser = AuthMiddleware::authenticate();
        RoleMiddleware::requireDoctor($authUser);

        // Only PMDC-verified doctors may issue prescriptions.
        $verifyStmt = $this->db->prepare("SELECT verification_status FROM doctor_profiles WHERE user_id = :uid");
        $verifyStmt->execute([':uid' => (int)$authUser['id']]);
        $docProfile = $verifyStmt->fetch();
        if (!$docProfile || $docProfile['verification_status'] !== 'verified') {
            sendError('Forbidden: Unverified doctors cannot issue prescriptions until PMDC credentials are approved by Admin.', 403);
        }

        $input = json_decode(file_get_contents('php://input'), true) ?? [];

        $patientId = (int)($input['patient_id'] ?? 0);
        $consultationId = isset($input['consultation_id']) ? (int)$input['consultation_id'] : null;
        $medicines = $input['medicines'] ?? [];

        if ($patientId <= 0) {
            sendError('Valid patient_id is required.');
        }

        if (empty($medicines) || !is_array($medicines)) {
            sendError('At least one medicine item is required.');
        }

        // Validate each medicine item
        foreach ($medicines as $i => $med) {
            if (empty($med['medicine_name']) || empty($med['dosage']) || empty($med['frequency']) || empty($med['duration'])) {
                sendError("Medicine item at index {$i} is missing required fields (medicine_name, dosage, frequency, duration).");
            }
        }

        // Verify patient exists
        $patientStmt = $this->db->prepare("SELECT id FROM users WHERE id = :pid AND role = 'patient'");
        $patientStmt->execute([':pid' => $patientId]);
        if (!$patientStmt->fetch()) {
            sendError('Patient not found.', 404);
        }

        // Verify the consultation (when linked) belongs to this doctor and patient
        if ($consultationId !== null && $consultationId > 0) {
            $cStmt = $this->db->prepare(
                "SELECT id FROM consultations WHERE id = :cid AND doctor_id = :did AND patient_id = :pid"
            );
            $cStmt->execute([':cid' => $consultationId, ':did' => (int)$authUser['id'], ':pid' => $patientId]);
            if (!$cStmt->fetch()) {
                sendError('Consultation not found for this doctor and patient.', 404);
            }
        } else {
            $consultationId = null;
        }

        // Get doctor profile for name and specialty
        $docStmt = $this->db->prepare(
            "SELECT u.full_name, d.specialization
             FROM users u
             JOIN doctor_profiles d ON u.id = d.user_id
             WHERE u.id = :did"
        );
        $docStmt->execute([':did' => (int)$authUser['id']]);
        $docInfo = $docStmt->fetch();

        $doctorName = $docInfo['full_name'] ?? $authUser['full_name'] ?? 'Doctor';
        $doctorSpecialty = $docInfo['specialization'] ?? 'General Physician';

        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare(
                "INSERT INTO prescriptions (consultation_id, patient_id, doctor_id, doctor_name, doctor_specialty, is_verified)
                 VALUES (:consultation_id, :patient_id, :doctor_id, :doctor_name, :doctor_specialty, 1)"
            );
            $stmt->execute([
                ':consultation_id' => $consultationId,
                ':patient_id' => $patientId,
                ':doctor_id' => (int)$authUser['id'],
                ':doctor_name' => $doctorName,
                ':doctor_specialty' => $doctorSpecialty,
            ]);

            $prescriptionId = (int)$this->db->lastInsertId();

            $itemStmt = $this->db->prepare(
                "INSERT INTO prescription_items (prescription_id, medicine_name, dosage, frequency, duration, instructions)
                 VALUES (:pid, :name, :dosage, :frequency, :duration, :instructions)"
            );

            $itemsResult = [];
            foreach ($medicines as $med) {
                $itemStmt->execute([
                    ':pid' => $prescriptionId,
                    ':name' => trim($med['medicine_name']),
                    ':dosage' => trim($med['dosage']),
                    ':frequency' => trim($med['frequency']),
                    ':duration' => trim($med['duration']),
                    ':instructions' => trim($med['instructions'] ?? ''),
                ]);
                $itemsResult[] = [
                    'id' => (int)$this->db->lastInsertId(),
                    'medicine_name' => trim($med['medicine_name']),
                    'dosage' => trim($med['dosage']),
                    'frequency' => trim($med['frequency']),
                    'duration' => trim($med['duration']),
                    'instructions' => trim($med['instructions'] ?? ''),
                ];
            }

            $this->db->commit();

            sendSuccess('Prescription created successfully.', [
                'id' => $prescriptionId,
                'consultation_id' => $consultationId,
                'patient_id' => $patientId,
                'doctor_id' => (int)$authUser['id'],
                'doctor_name' => $doctorName,
                'doctor_specialty' => $doctorSpecialty,
                'is_verified' => true,
                'medicines' => $itemsResult,
            ], 201);
        } catch (Exception $e) {
            if ($this->db->inTransaction()) {
                $this->db->rollBack();
            }
            sendError('Failed to create prescription: ' . $e->getMessage(), 500);
        }
    }

    /**
     * GET /api/prescriptions
     * Patients see only their own prescriptions. Doctors see their own issued
     * prescriptions, or a specific patient's when patient_id is provided.
     * Admins may view all.
     */
    public function index(): void {
        $authUser = AuthMiddleware::authenticate();

        $role = strtolower($authUser['role']);
        $patientId = null;

        if ($role === 'patient') {
            // Patients can only ever see their own prescriptions.
            $patientId = (int)$authUser['id'];
        } elseif ($role === 'doctor') {
            if (isset($_GET['patient_id'])) {
                $patientId = (int)$_GET['patient_id'];
            }
        } elseif ($role === 'admin') {
            $patientId = isset($_GET['patient_id']) ? (int)$_GET['patient_id'] : null;
        } else {
            sendError('Forbidden: You do not have permission to access this resource.', 403);
        }

        $doctorFilter = ($role === 'doctor' && $patientId === null) ? (int)$authUser['id'] : null;

        $sql = "SELECT p.*, 
                       COALESCE(u.full_name, p.doctor_name) AS doctor_name, 
                       COALESCE(d.specialization, p.doctor_specialty) AS doctor_specialty,
                       d.pmdc_number AS doctor_pmdc
                FROM prescriptions p
                LEFT JOIN users u ON p.doctor_id = u.id
                LEFT JOIN doctor_profiles d ON u.id = d.user_id";

        $params = [];
        $conditions = [];
        if ($patientId !== null) {
            $conditions[] = "p.patient_id = :pid";
            $params[':pid'] = $patientId;
        }
        if ($doctorFilter !== null) {
            $conditions[] = "p.doctor_id = :did";
            $params[':did'] = $doctorFilter;
        }
        if (!empty($conditions)) {
            $sql .= " WHERE " . implode(" AND ", $conditions);
        }

        $sql .= " ORDER BY p.created_at DESC";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $prescriptions = $stmt->fetchAll();

        // Fetch items for each prescription
        $itemStmt = $this->db->prepare("SELECT * FROM prescription_items WHERE prescription_id = :pid");

        $result = [];
        foreach ($prescriptions as $p) {
            $itemStmt->execute([':pid' => $p['id']]);
            $items = $itemStmt->fetchAll();

            $result[] = [
                'id' => (int)$p['id'],
                'consultation_id' => $p['consultation_id'] ? (int)$p['consultation_id'] : null,
                'patient_id' => (int)$p['patient_id'],
                'doctor_name' => $p['doctor_name'],
                'doctor_specialty' => $p['doctor_specialty'] ?: 'General Physician',
                'is_verified' => (bool)$p['is_verified'],
                'created_at' => $p['created_at'],
                'medicines' => array_map(function ($item) {
                    return [
                        'id' => (int)$item['id'],
                        'name' => $item['medicine_name'],
                        'dosage' => $item['dosage'],
                        'frequency' => $item['frequency'],
                        'duration' => $item['duration'],
                        'instructions' => $item['instructions'],
                    ];
                }, $items),
            ];
        }

        sendSuccess('Prescriptions retrieved.', $result);
    }

    /**
     * GET /api/prescriptions/{id}
     * Only the prescription's patient, the issuing doctor, or an admin may view it.
     */
    public function show(int $id): void {
        $authUser = AuthMiddleware::authenticate();

        $stmt = $this->db->prepare(
            "SELECT p.*, 
                    COALESCE(u.full_name, p.doctor_name) AS doctor_name, 
                    COALESCE(d.specialization, p.doctor_specialty) AS doctor_specialty,
                    d.pmdc_number AS doctor_pmdc
             FROM prescriptions p
             LEFT JOIN users u ON p.doctor_id = u.id
             LEFT JOIN doctor_profiles d ON u.id = d.user_id
             WHERE p.id = :id"
        );
        $stmt->execute([':id' => $id]);
        $prescription = $stmt->fetch();

        if (!$prescription) {
            sendError('Prescription not found.', 404);
        }

        // Authorization: owning patient, issuing doctor, or admin only.
        $role = strtolower($authUser['role']);
        $isOwnerPatient = ($role === 'patient' && (int)$prescription['patient_id'] === (int)$authUser['id']);
        $isIssuingDoctor = ($role === 'doctor' && (int)$prescription['doctor_id'] === (int)$authUser['id']);
        $isAdmin = ($role === 'admin');

        if (!$isOwnerPatient && !$isIssuingDoctor && !$isAdmin) {
            sendError('Forbidden: You do not have permission to view this prescription.', 403);
        }

        $itemStmt = $this->db->prepare("SELECT * FROM prescription_items WHERE prescription_id = :pid");
        $itemStmt->execute([':pid' => $id]);
        $items = $itemStmt->fetchAll();

        $prescription['medicines'] = $items;
        sendSuccess('Prescription details retrieved.', $prescription);
    }
}
