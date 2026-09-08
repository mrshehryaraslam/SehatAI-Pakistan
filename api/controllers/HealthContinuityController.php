<?php
/**
 * SehatAI Pakistan - Health Continuity Engine Controller
 *
 * Generates AI Patient Briefs (for doctors) and AI Care Plans (for patients)
 * by aggregating data from existing triage, consultation, prescription, and
 * medical records modules.  Uses the existing GeminiService with offline
 * template fallbacks and rule-based emergency safety nets.
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../utils/token_helper.php';
require_once __DIR__ . '/../middleware/auth_middleware.php';
require_once __DIR__ . '/../middleware/role_middleware.php';
require_once __DIR__ . '/../services/GeminiService.php';

class HealthContinuityController {
    private PDO $db;
    private GeminiService $gemini;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
        $this->gemini = new GeminiService();
    }

    // =================================================================
    // PUBLIC API ENDPOINTS
    // =================================================================

    /**
     * POST /api/ai/patient-brief
     * Doctor triggers (re)generation of AI Patient Brief for a consultation.
     */
    public function generatePatientBrief(): void {
        $authUser = AuthMiddleware::authenticate();
        RoleMiddleware::requireRole($authUser, ['doctor', 'admin']);

        $input = json_decode(file_get_contents('php://input'), true) ?? [];
        $consultationId = (int)($input['consultation_id'] ?? 0);
        $language = strtolower(trim($input['language'] ?? 'english'));

        if ($consultationId <= 0) {
            sendError('Valid consultation_id is required.', 422);
        }

        // Doctors may only generate briefs for their own consultations.
        $this->authorizeDoctorForConsultation($authUser, $consultationId);

        $result = $this->buildAndStorePatientBrief($consultationId, $language);
        if ($result === null) {
            sendError('Failed to generate patient brief. Consultation not found.', 404);
        }

        sendSuccess('AI Patient Brief generated successfully.', $result, 201);
    }

    /**
     * GET /api/ai/patient-brief/{consultation_id}
     * Retrieve stored brief for a consultation (doctor or assigned patient).
     */
    public function getPatientBrief(int $consultationId): void {
        $authUser = AuthMiddleware::authenticate();

        $this->authorizeConsultationAccess($authUser, $consultationId);

        $stmt = $this->db->prepare(
            "SELECT b.*, u.full_name AS patient_name
             FROM ai_patient_briefs b
             JOIN users u ON b.patient_id = u.id
             WHERE b.consultation_id = :cid
             ORDER BY b.id DESC
             LIMIT 1"
        );
        $stmt->execute([':cid' => $consultationId]);
        $brief = $stmt->fetch();

        if (!$brief) {
            sendError('No patient brief found for this consultation.', 404);
        }

        // Decode structured JSON
        if (!empty($brief['structured_data']) && is_string($brief['structured_data'])) {
            $brief['structured_data'] = json_decode($brief['structured_data'], true);
        }

        sendSuccess('Patient brief retrieved.', $brief);
    }

    /**
     * POST /api/ai/care-plan
     * Doctor triggers (re)generation of AI Care Plan after prescription.
     */
    public function generateCarePlan(): void {
        $authUser = AuthMiddleware::authenticate();
        RoleMiddleware::requireRole($authUser, ['doctor', 'admin']);

        $input = json_decode(file_get_contents('php://input'), true) ?? [];
        $consultationId = (int)($input['consultation_id'] ?? 0);
        $language = strtolower(trim($input['language'] ?? 'english'));

        if ($consultationId <= 0) {
            sendError('Valid consultation_id is required.', 422);
        }

        // Doctors may only generate care plans for their own consultations.
        $this->authorizeDoctorForConsultation($authUser, $consultationId);

        $result = $this->buildAndStoreCarePlan($consultationId, $language);
        if ($result === null) {
            sendError('Failed to generate care plan. Consultation not found.', 404);
        }

        sendSuccess('AI Care Plan generated successfully.', $result, 201);
    }

    /**
     * GET /api/ai/care-plan/{consultation_id}
     * Retrieve stored care plan (patient or doctor).
     */
    public function getCarePlan(int $consultationId): void {
        $authUser = AuthMiddleware::authenticate();

        $this->authorizeConsultationAccess($authUser, $consultationId);

        $stmt = $this->db->prepare(
            "SELECT cp.*, u.full_name AS patient_name,
                    dr.full_name AS doctor_name, dp.specialization AS doctor_specialty
             FROM ai_care_plans cp
             JOIN users u ON cp.patient_id = u.id
             LEFT JOIN users dr ON cp.doctor_id = dr.id
             LEFT JOIN doctor_profiles dp ON dr.id = dp.user_id
             WHERE cp.consultation_id = :cid
             ORDER BY cp.id DESC
             LIMIT 1"
        );
        $stmt->execute([':cid' => $consultationId]);
        $plan = $stmt->fetch();

        if (!$plan) {
            sendError('No care plan found for this consultation.', 404);
        }

        if (!empty($plan['structured_data']) && is_string($plan['structured_data'])) {
            $plan['structured_data'] = json_decode($plan['structured_data'], true);
        }

        sendSuccess('Care plan retrieved.', $plan);
    }

    // =================================================================
    // AUTHORIZATION HELPERS
    // =================================================================

    /**
     * Ensures the authenticated user is the assigned doctor, the assigned
     * patient, or an admin for the given consultation. Sends 404/403 on failure.
     */
    private function authorizeConsultationAccess(array $authUser, int $consultationId): void {
        $stmt = $this->db->prepare("SELECT patient_id, doctor_id FROM consultations WHERE id = :cid");
        $stmt->execute([':cid' => $consultationId]);
        $consultation = $stmt->fetch();

        if (!$consultation) {
            sendError('Consultation not found.', 404);
        }

        $role = strtolower($authUser['role'] ?? '');
        $isAssignedPatient = ($role === 'patient' && (int)$consultation['patient_id'] === (int)$authUser['id']);
        $isAssignedDoctor = ($role === 'doctor' && (int)$consultation['doctor_id'] === (int)$authUser['id']);
        $isAdmin = ($role === 'admin');

        if (!$isAssignedPatient && !$isAssignedDoctor && !$isAdmin) {
            sendError('Forbidden: Only the assigned doctor, the assigned patient, or an administrator may access this resource.', 403);
        }
    }

    /**
     * Ensures a doctor (non-admin) is assigned to the given consultation.
     * Sends 404/403 on failure. Admins bypass.
     */
    private function authorizeDoctorForConsultation(array $authUser, int $consultationId): void {
        if (strtolower($authUser['role'] ?? '') === 'admin') {
            return;
        }

        $stmt = $this->db->prepare("SELECT doctor_id FROM consultations WHERE id = :cid");
        $stmt->execute([':cid' => $consultationId]);
        $consultation = $stmt->fetch();

        if (!$consultation) {
            sendError('Consultation not found.', 404);
        }

        if ((int)$consultation['doctor_id'] !== (int)$authUser['id']) {
            sendError('Forbidden: Only the doctor assigned to this consultation may perform this action.', 403);
        }
    }

    // =================================================================
    // INTERNAL METHODS (called from ConsultationController auto-triggers)
    // =================================================================

    /**
     * Called internally when a doctor accepts a consultation.
     * Pre-generates the patient brief so it's ready by the time the doctor opens the file.
     */
    public function generatePatientBriefInternal(int $consultationId, string $language = 'english'): ?array {
        try {
            return $this->buildAndStorePatientBrief($consultationId, $language);
        } catch (Throwable $e) {
            error_log('[HealthContinuity] Auto brief generation failed: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Called internally when a consultation is completed with a prescription.
     * Auto-generates the care plan for the patient.
     */
    public function generateCarePlanInternal(int $consultationId, string $language = 'english'): ?array {
        try {
            return $this->buildAndStoreCarePlan($consultationId, $language);
        } catch (Throwable $e) {
            error_log('[HealthContinuity] Auto care plan generation failed: ' . $e->getMessage());
            return null;
        }
    }

    // =================================================================
    // PRIVATE BUILDERS — Aggregate data and call GeminiService
    // =================================================================

    /**
     * Aggregate all required data, call Gemini, store result for Patient Brief.
     */
    private function buildAndStorePatientBrief(int $consultationId, string $language): ?array {
        // 1. Fetch consultation
        $cStmt = $this->db->prepare(
            "SELECT c.*, u.full_name AS patient_name, u.city AS patient_city
             FROM consultations c
             JOIN users u ON c.patient_id = u.id
             WHERE c.id = :cid"
        );
        $cStmt->execute([':cid' => $consultationId]);
        $consultation = $cStmt->fetch();
        if (!$consultation) {
            return null;
        }

        $patientId = (int)$consultation['patient_id'];
        $doctorId = (int)$consultation['doctor_id'];

        // 2. Build context
        $context = [
            'patient_profile' => $this->fetchPatientProfile($patientId),
            'triage' => $this->fetchLatestTriage($patientId),
            'consultation' => [
                'symptoms' => $consultation['symptoms'] ?? '',
                'risk_level' => $consultation['risk_level'] ?? 'moderate',
            ],
            'medical_records' => $this->fetchRecentRecords($patientId),
            'active_medicines' => $this->fetchActiveMedicines($patientId),
        ];

        // 3. Generate via Gemini (or offline fallback)
        $result = $this->gemini->generatePatientBrief($context, $language);

        // 4. Store in DB
        $stmt = $this->db->prepare(
            "INSERT INTO ai_patient_briefs
             (consultation_id, patient_id, doctor_id, brief_text, structured_data, language, source)
             VALUES (:cid, :pid, :did, :brief_text, :structured, :lang, :source)"
        );
        $stmt->execute([
            ':cid' => $consultationId,
            ':pid' => $patientId,
            ':did' => $doctorId,
            ':brief_text' => $result['brief_text'] ?? '',
            ':structured' => json_encode($result['structured_data'] ?? [], JSON_UNESCAPED_UNICODE),
            ':lang' => $language,
            ':source' => $result['_source'] ?? 'offline_template',
        ]);

        $briefId = (int)$this->db->lastInsertId();

        return [
            'id' => $briefId,
            'consultation_id' => $consultationId,
            'patient_id' => $patientId,
            'doctor_id' => $doctorId,
            'brief_text' => $result['brief_text'],
            'structured_data' => $result['structured_data'] ?? [],
            'language' => $language,
            'source' => $result['_source'] ?? 'offline_template',
        ];
    }

    /**
     * Aggregate all required data, call Gemini, store result for Care Plan.
     */
    private function buildAndStoreCarePlan(int $consultationId, string $language): ?array {
        // 1. Fetch consultation
        $cStmt = $this->db->prepare(
            "SELECT c.*, u.full_name AS patient_name
             FROM consultations c
             JOIN users u ON c.patient_id = u.id
             WHERE c.id = :cid"
        );
        $cStmt->execute([':cid' => $consultationId]);
        $consultation = $cStmt->fetch();
        if (!$consultation) {
            return null;
        }

        $patientId = (int)$consultation['patient_id'];
        $doctorId = (int)$consultation['doctor_id'];

        // 2. Fetch prescription and items for this consultation
        $prescriptionId = null;
        $prescriptionItems = [];
        $doctorName = 'Doctor';
        $doctorSpecialty = 'General Physician';

        $pStmt = $this->db->prepare(
            "SELECT p.id, p.doctor_name, p.doctor_specialty
             FROM prescriptions p
             WHERE p.consultation_id = :cid
             ORDER BY p.id DESC LIMIT 1"
        );
        $pStmt->execute([':cid' => $consultationId]);
        $prescription = $pStmt->fetch();

        if ($prescription) {
            $prescriptionId = (int)$prescription['id'];
            $doctorName = $prescription['doctor_name'] ?? 'Doctor';
            $doctorSpecialty = $prescription['doctor_specialty'] ?? 'General Physician';

            $iStmt = $this->db->prepare("SELECT * FROM prescription_items WHERE prescription_id = :pid");
            $iStmt->execute([':pid' => $prescriptionId]);
            $prescriptionItems = $iStmt->fetchAll();
        }

        // 3. Build context
        $context = [
            'patient_profile' => $this->fetchPatientProfile($patientId),
            'consultation' => [
                'symptoms' => $consultation['symptoms'] ?? '',
                'risk_level' => $consultation['risk_level'] ?? 'moderate',
                'doctor_notes' => $consultation['doctor_notes'] ?? '',
            ],
            'prescription_items' => $prescriptionItems,
            'doctor_name' => $doctorName,
            'doctor_specialty' => $doctorSpecialty,
        ];

        // 4. Generate via Gemini (or offline fallback)
        $result = $this->gemini->generateCarePlan($context, $language);

        // 5. Store in DB
        $followUpDate = $result['follow_up_date'] ?? null;
        $stmt = $this->db->prepare(
            "INSERT INTO ai_care_plans
             (consultation_id, prescription_id, patient_id, doctor_id, care_plan_text, structured_data, follow_up_date, language, source)
             VALUES (:cid, :presc_id, :pid, :did, :plan_text, :structured, :follow_up, :lang, :source)"
        );
        $stmt->execute([
            ':cid' => $consultationId,
            ':presc_id' => $prescriptionId,
            ':pid' => $patientId,
            ':did' => $doctorId,
            ':plan_text' => $result['care_plan_text'] ?? '',
            ':structured' => json_encode($result['structured_data'] ?? [], JSON_UNESCAPED_UNICODE),
            ':follow_up' => $followUpDate,
            ':lang' => $language,
            ':source' => $result['_source'] ?? 'offline_template',
        ]);

        $planId = (int)$this->db->lastInsertId();

        // 6. Auto-create medicine reminders from care plan medication guidance
        $this->autoCreateMedicineReminders($patientId, $prescriptionItems, $result['structured_data'] ?? []);

        return [
            'id' => $planId,
            'consultation_id' => $consultationId,
            'prescription_id' => $prescriptionId,
            'patient_id' => $patientId,
            'doctor_id' => $doctorId,
            'care_plan_text' => $result['care_plan_text'],
            'structured_data' => $result['structured_data'] ?? [],
            'follow_up_date' => $followUpDate,
            'language' => $language,
            'source' => $result['_source'] ?? 'offline_template',
        ];
    }

    // =================================================================
    // DATA FETCHERS — Reuse existing table structures
    // =================================================================

    private function fetchPatientProfile(int $patientId): array {
        $stmt = $this->db->prepare(
            "SELECT u.full_name, u.city, p.age, p.gender, p.blood_group, p.allergies, p.chronic_conditions
             FROM users u
             LEFT JOIN patient_profiles p ON u.id = p.user_id
             WHERE u.id = :pid"
        );
        $stmt->execute([':pid' => $patientId]);
        $row = $stmt->fetch();
        return $row ?: [];
    }

    private function fetchLatestTriage(int $patientId): ?array {
        $stmt = $this->db->prepare(
            "SELECT primary_complaint, detected_symptoms, risk_level, emergency_warning, ai_reply, patient_context
             FROM ai_triage_assessments
             WHERE user_id = :uid
             ORDER BY id DESC
             LIMIT 1"
        );
        $stmt->execute([':uid' => $patientId]);
        $row = $stmt->fetch();
        if ($row) {
            if (!empty($row['detected_symptoms']) && is_string($row['detected_symptoms'])) {
                $row['detected_symptoms'] = json_decode($row['detected_symptoms'], true);
            }
            if (!empty($row['patient_context']) && is_string($row['patient_context'])) {
                $row['patient_context'] = json_decode($row['patient_context'], true);
            }
            return $row;
        }
        return null;
    }

    private function fetchRecentRecords(int $patientId, int $limit = 5): array {
        $stmt = $this->db->prepare(
            "SELECT title, description, diagnosis, record_date, category
             FROM medical_records
             WHERE patient_id = :pid
             ORDER BY record_date DESC
             LIMIT :lim"
        );
        $stmt->bindValue(':pid', $patientId, PDO::PARAM_INT);
        $stmt->bindValue(':lim', $limit, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll() ?: [];
    }

    private function fetchActiveMedicines(int $patientId): array {
        $stmt = $this->db->prepare(
            "SELECT medicine_name, dosage, frequency
             FROM medicine_reminders
             WHERE patient_id = :pid AND is_active = 1
             ORDER BY id DESC
             LIMIT 10"
        );
        $stmt->execute([':pid' => $patientId]);
        return $stmt->fetchAll() ?: [];
    }

    /**
     * Auto-create medicine reminders from prescription items when care plan is generated.
     * Only creates reminders that don't already exist for the same medicine + patient combo.
     */
    private function autoCreateMedicineReminders(int $patientId, array $prescriptionItems, array $structuredData): void {
        if (empty($prescriptionItems)) {
            return;
        }

        try {
            $checkStmt = $this->db->prepare(
                "SELECT id FROM medicine_reminders
                 WHERE patient_id = :pid AND medicine_name = :med AND is_active = 1"
            );

            $insertStmt = $this->db->prepare(
                "INSERT INTO medicine_reminders
                 (patient_id, medicine_name, dosage, frequency, time_of_day, start_date, end_date, is_active, instructions)
                 VALUES (:pid, :med, :dosage, :freq, :tod, CURDATE(), :end_date, 1, :instructions)"
            );

            foreach ($prescriptionItems as $item) {
                $medName = trim($item['medicine_name'] ?? '');
                if (empty($medName)) continue;

                // Skip if already active
                $checkStmt->execute([':pid' => $patientId, ':med' => $medName]);
                if ($checkStmt->fetch()) continue;

                // Parse duration for end date (e.g. "7 days", "5 days")
                $durationDays = 7;
                $durationStr = $item['duration'] ?? '';
                if (preg_match('/(\d+)/', $durationStr, $m)) {
                    $durationDays = max(1, (int)$m[1]);
                }
                $endDate = date('Y-m-d', strtotime("+{$durationDays} days"));

                // Infer time_of_day from frequency
                $freq = strtolower($item['frequency'] ?? '');
                $timeOfDay = 'Morning';
                if (str_contains($freq, 'twice') || str_contains($freq, '2') || str_contains($freq, 'bd')) {
                    $timeOfDay = 'Morning, Evening';
                } elseif (str_contains($freq, 'thrice') || str_contains($freq, '3') || str_contains($freq, 'tds')) {
                    $timeOfDay = 'Morning, Afternoon, Night';
                } elseif (str_contains($freq, 'night') || str_contains($freq, 'bedtime') || str_contains($freq, 'nocte')) {
                    $timeOfDay = 'Night';
                }

                $insertStmt->execute([
                    ':pid' => $patientId,
                    ':med' => $medName,
                    ':dosage' => $item['dosage'] ?? '',
                    ':freq' => $item['frequency'] ?? '',
                    ':tod' => $timeOfDay,
                    ':end_date' => $endDate,
                    ':instructions' => $item['instructions'] ?? '',
                ]);
            }
        } catch (Throwable $e) {
            // Non-fatal: log but don't block care plan generation
            error_log('[HealthContinuity] Auto medicine reminder creation failed: ' . $e->getMessage());
        }
    }
}
