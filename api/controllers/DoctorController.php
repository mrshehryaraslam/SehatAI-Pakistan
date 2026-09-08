<?php
/**
 * SehatAI Pakistan - Doctor Controller
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../middleware/auth_middleware.php';
require_once __DIR__ . '/../middleware/role_middleware.php';

class DoctorController {
    private PDO $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    /**
     * GET /api/doctors
     * Lists verified doctors (supports query filter: ?search= &city=)
     */
    public function index(): void {
        $search = trim($_GET['search'] ?? '');
        $city = trim($_GET['city'] ?? '');

        $sql = "SELECT u.id, u.full_name, u.email, u.phone, u.city,
                       d.specialization, d.qualification, d.experience_years, 
                       d.pmdc_number, d.verification_status, d.is_online, 
                       d.languages, d.availability, d.hospital_affiliation, d.bio
                FROM users u
                JOIN doctor_profiles d ON u.id = d.user_id
                WHERE u.role = 'doctor' AND d.verification_status = 'verified'";

        $params = [];
        if (!empty($search)) {
            $sql .= " AND (u.full_name LIKE :search OR d.specialization LIKE :search2 OR d.hospital_affiliation LIKE :search3)";
            $params[':search'] = "%{$search}%";
            $params[':search2'] = "%{$search}%";
            $params[':search3'] = "%{$search}%";
        }

        if (!empty($city)) {
            $sql .= " AND u.city = :city";
            $params[':city'] = $city;
        }

        $sql .= " ORDER BY d.is_online DESC, d.experience_years DESC";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($params);
        $doctors = $stmt->fetchAll();

        // Format for Flutter models
        $formatted = array_map(function ($doc) {
            return [
                'id' => (int)$doc['id'],
                'name' => $doc['full_name'],
                'specialty' => $doc['specialization'],
                'hospital' => $doc['hospital_affiliation'],
                'experience' => (int)$doc['experience_years'],
                'rating' => 4.9, // Default aggregate rating
                'review_count' => 84,
                'is_available' => (bool)$doc['is_online'],
                'languages' => explode(',', $doc['languages']),
                'pmdc_number' => $doc['pmdc_number'],
                'verification_status' => $doc['verification_status'],
                'availability' => $doc['availability'],
                'city' => $doc['city'],
                'phone' => $doc['phone'],
                'bio' => $doc['bio'],
            ];
        }, $doctors);

        sendSuccess('Verified doctors retrieved successfully.', $formatted);
    }

    /**
     * GET /api/doctors/me
     * Doctor retrieves their own profile
     */
    public function me(): void {
        $authUser = AuthMiddleware::authenticate();
        RoleMiddleware::requireDoctor($authUser);

        $stmt = $this->db->prepare(
            "SELECT u.id, u.full_name, u.email, u.phone, u.city,
                    d.specialization, d.qualification, d.experience_years, 
                    d.pmdc_number, d.verification_status, d.is_online, 
                    d.languages, d.availability, d.hospital_affiliation, d.bio
             FROM users u
             JOIN doctor_profiles d ON u.id = d.user_id
             WHERE u.id = :id"
        );
        $stmt->execute([':id' => $authUser['id']]);
        $doctor = $stmt->fetch();

        if (!$doctor) {
            sendError('Doctor profile not found.', 404);
        }

        sendSuccess('Doctor profile retrieved.', $doctor);
    }

    /**
     * POST /api/doctors/status
     * Doctor toggles online/offline availability
     */
    public function toggleStatus(): void {
        $authUser = AuthMiddleware::authenticate();
        RoleMiddleware::requireDoctor($authUser);

        $input = json_decode(file_get_contents('php://input'), true) ?? [];
        $isOnline = isset($input['is_online']) ? (int)(bool)$input['is_online'] : null;

        if ($isOnline === null) {
            // Toggle current status
            $stmt = $this->db->prepare("UPDATE doctor_profiles SET is_online = NOT is_online WHERE user_id = :id");
            $stmt->execute([':id' => $authUser['id']]);
        } else {
            $stmt = $this->db->prepare("UPDATE doctor_profiles SET is_online = :online WHERE user_id = :id");
            $stmt->execute([':online' => $isOnline, ':id' => $authUser['id']]);
        }

        $checkStmt = $this->db->prepare("SELECT is_online FROM doctor_profiles WHERE user_id = :id");
        $checkStmt->execute([':id' => $authUser['id']]);
        $updated = $checkStmt->fetch();

        sendSuccess('Availability status updated.', [
            'is_online' => (bool)$updated['is_online']
        ]);
    }

    /**
     * GET /api/doctors/{id}
     */
    public function show(int $id): void {
        $stmt = $this->db->prepare(
            "SELECT u.id, u.full_name, u.email, u.phone, u.city,
                    d.specialization, d.qualification, d.experience_years, 
                    d.pmdc_number, d.verification_status, d.is_online, 
                    d.languages, d.availability, d.hospital_affiliation, d.bio
             FROM users u
             JOIN doctor_profiles d ON u.id = d.user_id
             WHERE u.id = :id"
        );
        $stmt->execute([':id' => $id]);
        $doctor = $stmt->fetch();

        if (!$doctor) {
            sendError('Doctor not found.', 404);
        }

        sendSuccess('Doctor details retrieved.', $doctor);
    }
}
