<?php
/**
 * SehatAI Pakistan - Authentication Controller
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../utils/response.php';
require_once __DIR__ . '/../utils/token_helper.php';
require_once __DIR__ . '/../middleware/auth_middleware.php';

class AuthController {
    private PDO $db;

    public function __construct() {
        $database = new Database();
        $this->db = $database->getConnection();
    }

    /**
     * POST /api/auth/register
     * Allowed roles: patient, doctor
     */
    public function register(): void {
        $input = json_decode(file_get_contents('php://input'), true) ?? [];

        $fullName = trim($input['full_name'] ?? '');
        $phone = trim($input['phone'] ?? '');
        $email = trim($input['email'] ?? '');
        $password = trim($input['password'] ?? '');
        $role = strtolower(trim($input['role'] ?? 'patient'));
        $city = trim($input['city'] ?? 'Gilgit');

        if (empty($fullName) || empty($phone) || empty($password)) {
            sendError('Full name, phone, and password are required.');
        }

        if (strlen($password) < 6) {
            sendError('Password must be at least 6 characters.');
        }

        if ($role === 'admin') {
            sendError('Admin accounts cannot be registered publicly.', 403);
        }

        if (!in_array($role, ['patient', 'doctor'], true)) {
            sendError('Invalid role specified. Must be patient or doctor.');
        }

        // Check if phone or email already exists
        $checkStmt = $this->db->prepare("SELECT id FROM users WHERE phone = :phone OR (email != '' AND email = :email)");
        $checkStmt->execute([':phone' => $phone, ':email' => $email]);
        if ($checkStmt->fetch()) {
            sendError('A user with this phone number or email already exists.', 409);
        }

        $passwordHash = password_hash($password, PASSWORD_BCRYPT);

        try {
            $this->db->beginTransaction();

            $userStmt = $this->db->prepare(
                "INSERT INTO users (full_name, email, phone, password_hash, role, city) 
                 VALUES (:full_name, :email, :phone, :password_hash, :role, :city)"
            );
            $userStmt->execute([
                ':full_name' => $fullName,
                ':email' => !empty($email) ? $email : null,
                ':phone' => $phone,
                ':password_hash' => $passwordHash,
                ':role' => $role,
                ':city' => $city,
            ]);
            $userId = (int)$this->db->lastInsertId();

            if ($role === 'patient') {
                $patientStmt = $this->db->prepare(
                    "INSERT INTO patient_profiles (user_id, age, gender, blood_group, emergency_contact, allergies, chronic_conditions)
                     VALUES (:user_id, :age, :gender, :blood_group, :emergency_contact, :allergies, :chronic_conditions)"
                );
                $patientStmt->execute([
                    ':user_id' => $userId,
                    ':age' => isset($input['age']) ? (int)$input['age'] : 30,
                    ':gender' => $input['gender'] ?? 'Male',
                    ':blood_group' => $input['blood_group'] ?? 'B+',
                    ':emergency_contact' => $input['emergency_contact'] ?? '',
                    ':allergies' => $input['allergies'] ?? null,
                    ':chronic_conditions' => $input['chronic_conditions'] ?? null,
                ]);
            } else if ($role === 'doctor') {
                $pmdc = trim($input['pmdc_number'] ?? '');
                if (empty($pmdc)) {
                    $this->db->rollBack();
                    sendError('PMDC registration number is required for doctor registration.');
                }

                // Check PMDC unique
                $pmdcCheck = $this->db->prepare("SELECT user_id FROM doctor_profiles WHERE pmdc_number = :pmdc");
                $pmdcCheck->execute([':pmdc' => $pmdc]);
                if ($pmdcCheck->fetch()) {
                    $this->db->rollBack();
                    sendError('A doctor with this PMDC number is already registered.', 409);
                }

                $doctorStmt = $this->db->prepare(
                    "INSERT INTO doctor_profiles (user_id, specialization, qualification, experience_years, pmdc_number, verification_status, is_online, languages, availability, hospital_affiliation, bio)
                     VALUES (:user_id, :specialization, :qualification, :experience_years, :pmdc_number, 'pending', 1, :languages, :availability, :hospital_affiliation, :bio)"
                );
                $doctorStmt->execute([
                    ':user_id' => $userId,
                    ':specialization' => $input['specialization'] ?? 'General Physician',
                    ':qualification' => $input['qualification'] ?? 'MBBS',
                    ':experience_years' => isset($input['experience_years']) ? (int)$input['experience_years'] : 3,
                    ':pmdc_number' => $pmdc,
                    ':languages' => $input['languages'] ?? 'Urdu, English',
                    ':availability' => $input['availability'] ?? 'Available Today • 9 AM - 5 PM',
                    ':hospital_affiliation' => $input['hospital_affiliation'] ?? 'Civil Hospital',
                    ':bio' => $input['bio'] ?? 'Medical practitioner committed to patient care.',
                ]);
            }

            $this->db->commit();

            $user = [
                'id' => $userId,
                'full_name' => $fullName,
                'email' => $email,
                'phone' => $phone,
                'role' => $role,
                'city' => $city,
            ];

            $token = TokenHelper::generateToken($user);

            sendSuccess('Registration successful.', [
                'user' => $user,
                'token' => $token,
                'verification_status' => ($role === 'doctor') ? 'pending' : 'verified'
            ], 201);

        } catch (Exception $e) {
            $this->db->rollBack();
            sendError('Failed to register: ' . $e->getMessage(), 500);
        }
    }

    /**
     * POST /api/auth/login
     */
    public function login(): void {
        $input = json_decode(file_get_contents('php://input'), true) ?? [];

        $identifier = trim($input['identifier'] ?? $input['email'] ?? $input['phone'] ?? '');
        $password = trim($input['password'] ?? '');

        if (empty($identifier) || empty($password)) {
            sendError('Phone/Email and password are required.');
        }

        $stmt = $this->db->prepare(
            "SELECT id, full_name, email, phone, password_hash, role, city, created_at 
             FROM users 
             WHERE email = :id1 OR phone = :id2"
        );
        $stmt->execute([':id1' => $identifier, ':id2' => $identifier]);
        $user = $stmt->fetch();

        if (!$user) {
            sendError('Invalid phone/email or password.', 401);
        }

        if (!password_verify($password, $user['password_hash'])) {
            sendError('Invalid phone/email or password.', 401);
        }

        unset($user['password_hash']);

        // Fetch profile details if doctor or patient
        $profile = null;
        if ($user['role'] === 'doctor') {
            $docStmt = $this->db->prepare("SELECT * FROM doctor_profiles WHERE user_id = :uid");
            $docStmt->execute([':uid' => $user['id']]);
            $profile = $docStmt->fetch();
        } else if ($user['role'] === 'patient') {
            $patStmt = $this->db->prepare("SELECT * FROM patient_profiles WHERE user_id = :uid");
            $patStmt->execute([':uid' => $user['id']]);
            $profile = $patStmt->fetch();
        }

        $token = TokenHelper::generateToken($user);

        sendSuccess('Login successful.', [
            'user' => $user,
            'profile' => $profile,
            'token' => $token
        ]);
    }

    /**
     * GET /api/auth/me
     */
    public function me(): void {
        $authUser = AuthMiddleware::authenticate();

        $stmt = $this->db->prepare("SELECT id, full_name, email, phone, role, city, created_at FROM users WHERE id = :id");
        $stmt->execute([':id' => $authUser['id']]);
        $user = $stmt->fetch();

        if (!$user) {
            sendError('User not found.', 404);
        }

        $profile = null;
        if ($user['role'] === 'doctor') {
            $docStmt = $this->db->prepare("SELECT * FROM doctor_profiles WHERE user_id = :uid");
            $docStmt->execute([':uid' => $user['id']]);
            $profile = $docStmt->fetch();
        } else if ($user['role'] === 'patient') {
            $patStmt = $this->db->prepare("SELECT * FROM patient_profiles WHERE user_id = :uid");
            $patStmt->execute([':uid' => $user['id']]);
            $profile = $patStmt->fetch();
        }

        sendSuccess('User profile fetched.', [
            'user' => $user,
            'profile' => $profile
        ]);
    }
}
