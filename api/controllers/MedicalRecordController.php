<?php
/**
 * SehatAI Pakistan - Medical Records Controller
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth_middleware.php';

class MedicalRecordController {
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
     * GET /api/records
     */
    public function index(): void {
        $authUser = AuthMiddleware::authenticate();

        $patientId = $this->resolvePatientId(
            $authUser,
            isset($_GET['patient_id']) ? (int)$_GET['patient_id'] : null
        );

        $category = $_GET['category'] ?? '';

        $sql = "SELECT * FROM medical_records WHERE patient_id = :pid";
        $params = [':pid' => $patientId];

        if (!empty($category)) {
            $sql .= " AND category = :cat";
            $params[':cat'] = $category;
        }

        $sql .= " ORDER BY record_date DESC, created_at DESC";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $records = $stmt->fetchAll();

        $formatted = array_map(function ($r) {
            return [
                'id' => (int)$r['id'],
                'patient_id' => (int)$r['patient_id'],
                'title' => $r['title'],
                'category' => $r['category'],
                'doctor_or_lab' => $r['doctor_or_lab'],
                'description' => $r['description'],
                'diagnosis' => $r['diagnosis'] ?? '',
                'date' => $r['record_date'],
            ];
        }, $records);

        sendSuccess('Medical records retrieved.', $formatted);
    }

    /**
     * POST /api/records
     */
    public function store(): void {
        $authUser = AuthMiddleware::authenticate();
        $input = json_decode(file_get_contents('php://input'), true) ?? [];

        $patientId = $this->resolvePatientId(
            $authUser,
            isset($input['patient_id']) ? (int)$input['patient_id'] : null
        );
        $title = trim($input['title'] ?? '');
        $category = trim($input['category'] ?? 'consultation');
        $doctorOrLab = trim($input['doctor_or_lab'] ?? 'SehatAI Health Facility');
        $description = trim($input['description'] ?? '');
        $diagnosis = trim($input['diagnosis'] ?? '');
        $recordDate = $input['date'] ?? $input['record_date'] ?? date('Y-m-d');

        if (empty($title) || empty($description)) {
            sendError('Title and description are required.');
        }

        $stmt = $this->db->prepare(
            "INSERT INTO medical_records (patient_id, title, category, doctor_or_lab, description, diagnosis, record_date)
             VALUES (:pid, :title, :cat, :doc, :desc, :diag, :rdate)"
        );
        $stmt->execute([
            ':pid' => $patientId,
            ':title' => $title,
            ':cat' => $category,
            ':doc' => $doctorOrLab,
            ':desc' => $description,
            ':diag' => $diagnosis,
            ':rdate' => $recordDate
        ]);

        $id = (int)$this->db->lastInsertId();

        sendSuccess('Medical record created.', [
            'id' => $id,
            'title' => $title,
            'category' => $category,
            'doctor_or_lab' => $doctorOrLab,
            'description' => $description,
            'diagnosis' => $diagnosis,
            'date' => $recordDate
        ], 201);
    }
}
