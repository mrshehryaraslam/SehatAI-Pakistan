<?php
/**
 * SehatAI Pakistan - Medicine Reminders Controller
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth_middleware.php';

class MedicineController {
    private PDO $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    /**
     * Resolves the patient context for the request.
     * - Patients always operate on their own records.
     * - Doctors/admins MUST supply an explicit valid patient_id
     *   (no demo/default patient is ever used).
     */
    private function resolvePatientId(array $authUser, ?int $explicitId): int {
        if (($authUser['role'] ?? '') === 'patient') {
            return (int)$authUser['id'];
        }

        if ($explicitId === null || $explicitId <= 0) {
            sendError('patient_id is required for doctor/admin requests.', 400);
        }

        $stmt = $this->db->prepare("SELECT id FROM users WHERE id = :pid AND role = 'patient'");
        $stmt->execute([':pid' => $explicitId]);
        if (!$stmt->fetch()) {
            sendError('Patient not found.', 404);
        }

        return $explicitId;
    }

    /**
     * GET /api/medicines
     * Retrieve reminders for the authenticated patient
     */
    public function index(): void {
        $authUser = AuthMiddleware::authenticate();

        $patientId = $this->resolvePatientId(
            $authUser,
            isset($_GET['patient_id']) ? (int)$_GET['patient_id'] : null
        );

        $stmt = $this->db->prepare(
            "SELECT id, patient_id, medicine_name, dosage, frequency, time_of_day, 
                    start_date, end_date, is_active, instructions, created_at
             FROM medicine_reminders 
             WHERE patient_id = :pid 
             ORDER BY is_active DESC, time_of_day ASC"
        );
        $stmt->execute([':pid' => $patientId]);
        $reminders = $stmt->fetchAll();

        $formatted = array_map(function ($r) {
            return [
                'id' => (int)$r['id'],
                'patient_id' => (int)$r['patient_id'],
                'medicine_name' => $r['medicine_name'],
                'dosage' => $r['dosage'],
                'frequency' => $r['frequency'],
                'time_of_day' => $r['time_of_day'],
                'start_date' => $r['start_date'],
                'end_date' => $r['end_date'],
                'is_active' => (bool)$r['is_active'],
                'instructions' => $r['instructions'] ?? '',
            ];
        }, $reminders);

        sendSuccess('Medicine reminders retrieved.', $formatted);
    }

    /**
     * POST /api/medicines
     * Add a new medicine reminder
     */
    public function store(): void {
        $authUser = AuthMiddleware::authenticate();
        $input = json_decode(file_get_contents('php://input'), true) ?? [];

        $patientId = $this->resolvePatientId(
            $authUser,
            isset($input['patient_id']) ? (int)$input['patient_id'] : null
        );
        $name = trim($input['medicine_name'] ?? '');
        $dosage = trim($input['dosage'] ?? '1 Tablet');
        $frequency = trim($input['frequency'] ?? 'Once daily');
        $timeOfDay = trim($input['time_of_day'] ?? '08:00 AM');
        $startDate = $input['start_date'] ?? date('Y-m-d');
        $endDate = $input['end_date'] ?? date('Y-m-d', strtotime('+30 days'));
        $instructions = trim($input['instructions'] ?? '');

        if (empty($name)) {
            sendError('Medicine name is required.');
        }

        $stmt = $this->db->prepare(
            "INSERT INTO medicine_reminders (patient_id, medicine_name, dosage, frequency, time_of_day, start_date, end_date, is_active, instructions)
             VALUES (:pid, :name, :dosage, :freq, :time, :start, :end, 1, :inst)"
        );
        $stmt->execute([
            ':pid' => $patientId,
            ':name' => $name,
            ':dosage' => $dosage,
            ':freq' => $frequency,
            ':time' => $timeOfDay,
            ':start' => $startDate,
            ':end' => $endDate,
            ':inst' => $instructions
        ]);

        $id = (int)$this->db->lastInsertId();

        sendSuccess('Medicine reminder created.', [
            'id' => $id,
            'medicine_name' => $name,
            'dosage' => $dosage,
            'frequency' => $frequency,
            'time_of_day' => $timeOfDay,
            'is_active' => true,
        ], 201);
    }

    /**
     * POST /api/medicines/{id}/toggle
     */
    public function toggle(int $id): void {
        $authUser = AuthMiddleware::authenticate();
        $reminder = $this->fetchOwnedReminder($id, $authUser);

        $newStatus = $reminder['is_active'] ? 0 : 1;
        $updateStmt = $this->db->prepare("UPDATE medicine_reminders SET is_active = :status WHERE id = :id");
        $updateStmt->execute([':status' => $newStatus, ':id' => $id]);

        sendSuccess('Medicine reminder status updated.', [
            'id' => $id,
            'is_active' => (bool)$newStatus
        ]);
    }

    /**
     * PUT /api/medicines/{id}
     * Update an existing medicine reminder (patient-owned or doctor/admin with patient_id).
     */
    public function update(int $id): void {
        $authUser = AuthMiddleware::authenticate();
        $reminder = $this->fetchOwnedReminder($id, $authUser);

        $input = json_decode(file_get_contents('php://input'), true) ?? [];

        $name = trim($input['medicine_name'] ?? $reminder['medicine_name']);
        $dosage = trim($input['dosage'] ?? $reminder['dosage']);
        $frequency = trim($input['frequency'] ?? $reminder['frequency']);
        $timeOfDay = trim($input['time_of_day'] ?? $reminder['time_of_day']);
        $startDate = $input['start_date'] ?? $reminder['start_date'];
        $endDate = $input['end_date'] ?? $reminder['end_date'];
        $instructions = trim($input['instructions'] ?? ($reminder['instructions'] ?? ''));
        $isActive = isset($input['is_active']) ? ((int)$input['is_active']) : (int)$reminder['is_active'];

        if (empty($name)) {
            sendError('Medicine name is required.');
        }

        $stmt = $this->db->prepare(
            "UPDATE medicine_reminders 
             SET medicine_name = :name, dosage = :dosage, frequency = :freq, 
                 time_of_day = :time, start_date = :start, end_date = :end, 
                 is_active = :active, instructions = :inst 
             WHERE id = :id"
        );
        $stmt->execute([
            ':name' => $name,
            ':dosage' => $dosage,
            ':freq' => $frequency,
            ':time' => $timeOfDay,
            ':start' => $startDate,
            ':end' => $endDate,
            ':active' => $isActive,
            ':inst' => $instructions,
            ':id' => $id,
        ]);

        sendSuccess('Medicine reminder updated.', [
            'id' => $id,
            'medicine_name' => $name,
            'dosage' => $dosage,
            'frequency' => $frequency,
            'time_of_day' => $timeOfDay,
            'is_active' => (bool)$isActive,
        ]);
    }

    /**
     * DELETE /api/medicines/{id}
     * Delete a medicine reminder (patient-owned or doctor/admin with patient_id).
     */
    public function destroy(int $id): void {
        $authUser = AuthMiddleware::authenticate();
        $this->fetchOwnedReminder($id, $authUser);

        $stmt = $this->db->prepare("DELETE FROM medicine_reminders WHERE id = :id");
        $stmt->execute([':id' => $id]);

        sendSuccess('Medicine reminder deleted.', ['id' => $id]);
    }

    /**
     * POST /api/medicines/{id}/intake
     * Mark a medicine as taken or missed for today.
     * Body: { "status": "taken" | "missed" }
     */
    public function markIntake(int $id): void {
        $authUser = AuthMiddleware::authenticate();
        $reminder = $this->fetchOwnedReminder($id, $authUser);

        $input = json_decode(file_get_contents('php://input'), true) ?? [];
        $status = strtolower(trim($input['status'] ?? ''));

        if (!in_array($status, ['taken', 'missed'], true)) {
            sendError('Status must be "taken" or "missed".');
        }

        $today = date('Y-m-d');
        $patientId = (int)$reminder['patient_id'];

        // UPSERT: insert or update for today's log
        $stmt = $this->db->prepare(
            "INSERT INTO medicine_intake_logs (reminder_id, patient_id, log_date, status) 
             VALUES (:rid, :pid, :log_date, :status)
             ON DUPLICATE KEY UPDATE status = VALUES(status), logged_at = CURRENT_TIMESTAMP"
        );
        $stmt->execute([
            ':rid' => $id,
            ':pid' => $patientId,
            ':log_date' => $today,
            ':status' => $status,
        ]);

        sendSuccess("Medicine intake marked as {$status}.", [
            'reminder_id' => $id,
            'log_date' => $today,
            'status' => $status,
        ]);
    }

    /**
     * GET /api/medicines/adherence
     * Daily adherence/progress for the authenticated patient's active medicines.
     * Returns today's taken/missed/pending counts and per-medicine status.
     */
    public function adherence(): void {
        $authUser = AuthMiddleware::authenticate();
        $patientId = $this->resolvePatientId(
            $authUser,
            isset($_GET['patient_id']) ? (int)$_GET['patient_id'] : null
        );

        $today = date('Y-m-d');

        // Fetch all active reminders for this patient
        $remStmt = $this->db->prepare(
            "SELECT id, medicine_name, dosage, frequency, time_of_day 
             FROM medicine_reminders 
             WHERE patient_id = :pid AND is_active = 1
             ORDER BY time_of_day ASC"
        );
        $remStmt->execute([':pid' => $patientId]);
        $reminders = $remStmt->fetchAll();

        if (empty($reminders)) {
            sendSuccess('Adherence data retrieved.', [
                'date' => $today,
                'total_active' => 0,
                'taken' => 0,
                'missed' => 0,
                'pending' => 0,
                'adherence_percent' => 0,
                'medicines' => [],
            ]);
            return;
        }

        // Fetch today's intake logs
        $ids = array_column($reminders, 'id');
        $placeholders = implode(',', array_fill(0, count($ids), '?'));
        $logStmt = $this->db->prepare(
            "SELECT reminder_id, status FROM medicine_intake_logs 
             WHERE reminder_id IN ({$placeholders}) AND log_date = ?"
        );
        $logStmt->execute(array_merge($ids, [$today]));
        $logs = $logStmt->fetchAll();

        $logMap = [];
        foreach ($logs as $log) {
            $logMap[(int)$log['reminder_id']] = $log['status'];
        }

        $taken = 0;
        $missed = 0;
        $medicines = [];
        foreach ($reminders as $r) {
            $rid = (int)$r['id'];
            $status = $logMap[$rid] ?? 'pending';
            if ($status === 'taken') $taken++;
            elseif ($status === 'missed') $missed++;

            $medicines[] = [
                'reminder_id' => $rid,
                'medicine_name' => $r['medicine_name'],
                'dosage' => $r['dosage'],
                'frequency' => $r['frequency'],
                'time_of_day' => $r['time_of_day'],
                'intake_status' => $status,
            ];
        }

        $total = count($reminders);
        $pending = $total - $taken - $missed;
        $adherencePercent = $total > 0 ? round(($taken / $total) * 100) : 0;

        sendSuccess('Adherence data retrieved.', [
            'date' => $today,
            'total_active' => $total,
            'taken' => $taken,
            'missed' => $missed,
            'pending' => $pending,
            'adherence_percent' => $adherencePercent,
            'medicines' => $medicines,
        ]);
    }

    /**
     * Fetches a reminder and enforces ownership.
     * - Patients: must own the reminder.
     * - Doctors/admins: must supply explicit patient_id; the reminder must belong to that patient.
     */
    private function fetchOwnedReminder(int $id, array $authUser): array {
        $checkStmt = $this->db->prepare("SELECT * FROM medicine_reminders WHERE id = :id");
        $checkStmt->execute([':id' => $id]);
        $reminder = $checkStmt->fetch();

        if (!$reminder) {
            sendError('Medicine reminder not found.', 404);
        }

        $role = $authUser['role'] ?? '';

        if ($role === 'patient') {
            if ((int)$reminder['patient_id'] !== (int)$authUser['id']) {
                sendError('Forbidden: You can only access your own medicine reminders.', 403);
            }
            return $reminder;
        }

        // Doctor/admin: verify the reminder belongs to the explicit patient
        $input = json_decode(file_get_contents('php://input'), true) ?? [];
        $explicitPid = isset($input['patient_id']) ? (int)$input['patient_id'] : null;
        if ($explicitPid === null || $explicitPid <= 0) {
            // Also check query param
            $explicitPid = isset($_GET['patient_id']) ? (int)$_GET['patient_id'] : null;
        }
        if ($explicitPid === null || $explicitPid <= 0) {
            sendError('patient_id is required for doctor/admin requests.', 400);
        }
        if ((int)$reminder['patient_id'] !== $explicitPid) {
            sendError('Forbidden: This reminder does not belong to the specified patient.', 403);
        }

        return $reminder;
    }
}
