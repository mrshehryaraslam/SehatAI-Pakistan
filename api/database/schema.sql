-- SehatAI Pakistan Database Schema
-- Phase 2: Relational Architecture for Healthcare, Doctor PMDC Verification & Consultations



-- 1. Users Table (Core Auth & Roles)
CREATE TABLE IF NOT EXISTS `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `full_name` VARCHAR(150) NOT NULL,
    `email` VARCHAR(150) UNIQUE NULL,
    `phone` VARCHAR(30) UNIQUE NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,
    `role` ENUM('patient', 'doctor', 'admin') NOT NULL DEFAULT 'patient',
    `city` VARCHAR(100) NOT NULL DEFAULT 'Gilgit',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Patient Profiles
CREATE TABLE IF NOT EXISTS `patient_profiles` (
    `user_id` INT PRIMARY KEY,
    `age` INT NULL DEFAULT 30,
    `gender` ENUM('Male', 'Female', 'Other') DEFAULT 'Male',
    `blood_group` VARCHAR(10) DEFAULT 'B+',
    `emergency_contact` VARCHAR(150) DEFAULT '+92 321 9876543 (Brother)',
    `allergies` TEXT NULL,
    `chronic_conditions` TEXT NULL,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Doctor Profiles
CREATE TABLE IF NOT EXISTS `doctor_profiles` (
    `user_id` INT PRIMARY KEY,
    `specialization` VARCHAR(150) NOT NULL DEFAULT 'General Physician',
    `qualification` VARCHAR(150) NOT NULL DEFAULT 'MBBS',
    `experience_years` INT NOT NULL DEFAULT 5,
    `pmdc_number` VARCHAR(50) UNIQUE NOT NULL,
    `verification_status` ENUM('pending', 'verified', 'rejected') NOT NULL DEFAULT 'pending',
    `is_online` TINYINT(1) NOT NULL DEFAULT 1,
    `languages` VARCHAR(200) NOT NULL DEFAULT 'Urdu, English',
    `availability` VARCHAR(150) NOT NULL DEFAULT 'Available Today • 9 AM - 6 PM',
    `hospital_affiliation` VARCHAR(200) NOT NULL DEFAULT 'Civil Hospital',
    `bio` TEXT NULL,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Consultations (Telehealth Sessions)
CREATE TABLE IF NOT EXISTS `consultations` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `patient_id` INT NOT NULL,
    `doctor_id` INT NOT NULL,
    `symptoms` TEXT NOT NULL,
    `risk_level` ENUM('low', 'moderate', 'high') NOT NULL DEFAULT 'moderate',
    `status` ENUM('pending', 'in_progress', 'completed', 'cancelled') NOT NULL DEFAULT 'pending',
    `doctor_notes` TEXT NULL,
    `requested_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `scheduled_at` TIMESTAMP NULL,
    FOREIGN KEY (`patient_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`doctor_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Chat Messages (Consultation Threads)
CREATE TABLE IF NOT EXISTS `chat_messages` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `consultation_id` INT NOT NULL,
    `sender_id` INT NOT NULL,
    `sender_role` ENUM('patient', 'doctor', 'system') NOT NULL,
    `message` TEXT NOT NULL,
    `is_emergency_notice` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`consultation_id`) REFERENCES `consultations`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`sender_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Prescriptions
CREATE TABLE IF NOT EXISTS `prescriptions` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `consultation_id` INT NULL,
    `patient_id` INT NOT NULL,
    `doctor_id` INT NULL,
    `doctor_name` VARCHAR(150) NOT NULL DEFAULT 'Dr. Ayesha Siddiqui',
    `doctor_specialty` VARCHAR(150) NOT NULL DEFAULT 'Internal Medicine',
    `is_verified` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`patient_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Prescription Items (Dosage and Instructions)
CREATE TABLE IF NOT EXISTS `prescription_items` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `prescription_id` INT NOT NULL,
    `medicine_name` VARCHAR(150) NOT NULL,
    `dosage` VARCHAR(100) NOT NULL,
    `frequency` VARCHAR(100) NOT NULL,
    `duration` VARCHAR(100) NOT NULL,
    `instructions` TEXT NOT NULL,
    FOREIGN KEY (`prescription_id`) REFERENCES `prescriptions`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Medicine Reminders (Patient Active Schedule)
CREATE TABLE IF NOT EXISTS `medicine_reminders` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `patient_id` INT NOT NULL,
    `medicine_name` VARCHAR(150) NOT NULL,
    `dosage` VARCHAR(100) NOT NULL,
    `frequency` VARCHAR(100) NOT NULL,
    `time_of_day` VARCHAR(50) NOT NULL,
    `start_date` DATE NOT NULL,
    `end_date` DATE NOT NULL,
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `instructions` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`patient_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8b. Medicine Intake Logs (Phase 6 — Adherence Tracking)
CREATE TABLE IF NOT EXISTS `medicine_intake_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `reminder_id` INT NOT NULL,
    `log_date` DATE NOT NULL,
    `status` ENUM('taken', 'missed') NOT NULL DEFAULT 'taken',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_reminder_date` (`reminder_id`, `log_date`),
    FOREIGN KEY (`reminder_id`) REFERENCES `medicine_reminders`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. Medical Records & Lab Reports Timeline
CREATE TABLE IF NOT EXISTS `medical_records` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `patient_id` INT NOT NULL,
    `title` VARCHAR(200) NOT NULL,
    `category` ENUM('history', 'consultation', 'prescription', 'lab_report', 'allergy') NOT NULL,
    `doctor_or_lab` VARCHAR(150) NOT NULL,
    `description` TEXT NOT NULL,
    `diagnosis` VARCHAR(200) NULL,
    `record_date` DATE NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`patient_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Emergency SOS Alerts Logger
CREATE TABLE IF NOT EXISTS `emergency_alerts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `patient_id` INT NOT NULL,
    `symptom_description` TEXT NOT NULL,
    `risk_level` ENUM('low', 'moderate', 'high') NOT NULL DEFAULT 'high',
    `latitude` DECIMAL(10, 8) NULL,
    `longitude` DECIMAL(11, 8) NULL,
    `city` VARCHAR(100) NOT NULL DEFAULT 'Gilgit',
    `status` ENUM('pending', 'reviewed', 'resolved') NOT NULL DEFAULT 'pending',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`patient_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. AI Triage Assessments
CREATE TABLE IF NOT EXISTS `ai_triage_assessments` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NULL,
    `session_id` VARCHAR(100) NOT NULL,
    `language` VARCHAR(30) NOT NULL DEFAULT 'roman_urdu',
    `primary_complaint` TEXT NOT NULL,
    `detected_symptoms` JSON NULL,
    `risk_level` ENUM('low', 'moderate', 'high') NOT NULL DEFAULT 'low',
    `requires_doctor` TINYINT(1) NOT NULL DEFAULT 0,
    `emergency_warning` TEXT NULL,
    `ai_reply` TEXT NOT NULL,
    `disclaimer` TEXT NOT NULL,
    `patient_context` JSON NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 12. AI Triage Conversation Messages
CREATE TABLE IF NOT EXISTS `ai_triage_messages` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `assessment_id` INT NULL,
    `session_id` VARCHAR(100) NOT NULL,
    `user_id` INT NULL,
    `role` ENUM('user', 'model', 'system') NOT NULL,
    `message` TEXT NOT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`assessment_id`) REFERENCES `ai_triage_assessments`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 13. AI Patient Briefs (Health Continuity Engine)
-- Auto-generated when doctor accepts a consultation; provides structured clinical summary.
CREATE TABLE IF NOT EXISTS `ai_patient_briefs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `consultation_id` INT NOT NULL,
    `patient_id` INT NOT NULL,
    `doctor_id` INT NOT NULL,
    `brief_text` TEXT NOT NULL,
    `structured_data` JSON NULL,
    `language` VARCHAR(30) NOT NULL DEFAULT 'english',
    `source` ENUM('google_gemini_api', 'offline_template') NOT NULL DEFAULT 'google_gemini_api',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`consultation_id`) REFERENCES `consultations`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`patient_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`doctor_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 14. AI Care Plans (Health Continuity Engine)
-- Auto-generated when consultation is completed with a prescription; provides
-- follow-up guidance, medication tips, warning signs, and next-step schedule.
CREATE TABLE IF NOT EXISTS `ai_care_plans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `consultation_id` INT NOT NULL,
    `prescription_id` INT NULL,
    `patient_id` INT NOT NULL,
    `doctor_id` INT NOT NULL,
    `care_plan_text` TEXT NOT NULL,
    `structured_data` JSON NULL,
    `follow_up_date` DATE NULL,
    `language` VARCHAR(30) NOT NULL DEFAULT 'english',
    `source` ENUM('google_gemini_api', 'offline_template') NOT NULL DEFAULT 'google_gemini_api',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`consultation_id`) REFERENCES `consultations`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`prescription_id`) REFERENCES `prescriptions`(`id`) ON DELETE SET NULL,
    FOREIGN KEY (`patient_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`doctor_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

