-- ====================================================================
-- SehatAI Pakistan - InfinityFree Cloud Database Setup Script
-- Target Database: if0_42859111_sehatai
-- Host: sql113.infinityfree.com
--
-- Instructions:
-- 1. Open InfinityFree Control Panel (VistaPanel / cPanel)
-- 2. Click "phpMyAdmin" next to if0_42859111_sehatai
-- 3. Click the "Import" tab at the top
-- 4. Select this file (infinityfree_setup.sql) and click "Go"
-- ====================================================================

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

-- 9. Medicine Intake Logs (Adherence Tracking)
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

-- 10. Medical Records & Lab Reports Timeline
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

-- 11. Emergency SOS Alerts Logger
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

-- 12. AI Triage Assessments
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

-- 13. AI Triage Conversation Messages
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

-- 14. AI Patient Briefs (Health Continuity Engine)
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

-- 15. AI Care Plans (Health Continuity Engine)
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

-- ====================================================================
-- SEED DATA & VERIFIED DEFAULT ACCOUNTS
-- Standard Logins:
-- Admin:   admin@sehat.ai           (Password: Admin@123)
-- Doctor:  ayesha.siddiqui@sehat.ai (Password: Doctor@123)
-- Patient: ahmed.khan@gmail.com     (Password: Patient@123)
-- ====================================================================

-- 1. Insert Core Users
INSERT INTO `users` (`id`, `full_name`, `email`, `phone`, `password_hash`, `role`, `city`) VALUES
(1, 'System Administrator', 'admin@sehat.ai', '+92 300 0000001', '$2y$10$Ftlxr4iAOuSPyC5LpDFyxeSc14vK1xrTlGBYbUQhxnKJF4VLNGgd2', 'admin', 'Islamabad'),
(2, 'Dr. Ayesha Siddiqui', 'ayesha.siddiqui@sehat.ai', '+92 300 1111111', '$2y$10$m0sGt84.8/Wbf5cVN.pKOeCA9ehL5AO1aYtnIYNEpqsYKLtyAp69y', 'doctor', 'Gilgit'),
(3, 'Dr. Bilal Tariq', 'bilal.tariq@sehat.ai', '+92 300 2222222', '$2y$10$m0sGt84.8/Wbf5cVN.pKOeCA9ehL5AO1aYtnIYNEpqsYKLtyAp69y', 'doctor', 'Skardu'),
(4, 'Dr. Fatima Zahra', 'fatima.zahra@sehat.ai', '+92 300 3333333', '$2y$10$m0sGt84.8/Wbf5cVN.pKOeCA9ehL5AO1aYtnIYNEpqsYKLtyAp69y', 'doctor', 'Hunza'),
(5, 'Dr. Tariq Mehmood', 'tariq.mehmood@sehat.ai', '+92 300 4444444', '$2y$10$m0sGt84.8/Wbf5cVN.pKOeCA9ehL5AO1aYtnIYNEpqsYKLtyAp69y', 'doctor', 'Chilas'),
(6, 'Ahmed Khan', 'ahmed.khan@gmail.com', '+92 321 5555555', '$2y$10$TdOx5lO2W3Oyp4rOfaio9ewMsbOSAjMWlCD9ON0i9FsvzBTYHX2HG', 'patient', 'Gilgit'),
(7, 'Zainab Bibi', 'zainab.bibi@gmail.com', '+92 333 6666666', '$2y$10$TdOx5lO2W3Oyp4rOfaio9ewMsbOSAjMWlCD9ON0i9FsvzBTYHX2HG', 'patient', 'Skardu')
ON DUPLICATE KEY UPDATE `password_hash` = VALUES(`password_hash`);

-- 2. Insert Doctor Profiles
INSERT INTO `doctor_profiles` (`user_id`, `specialization`, `qualification`, `experience_years`, `pmdc_number`, `verification_status`, `is_online`, `languages`, `availability`, `hospital_affiliation`, `bio`) VALUES
(2, 'Cardiology / Emergency Medicine', 'MBBS, FCPS (Cardiology)', 12, 'PMDC-45892-A', 'verified', 1, 'Urdu, English, Shina', 'Available Today • 9 AM - 8 PM', 'DHQ Hospital Gilgit', 'Experienced cardiologist and emergency triage specialist serving northern Pakistan.'),
(3, 'Pediatrics & Neonatology', 'MBBS, DCH, MCPS', 8, 'PMDC-67219-P', 'verified', 1, 'Urdu, English, Balti', 'Available Today • 10 AM - 6 PM', 'Skardu Child Healthcare Center', 'Dedicated to child wellness, acute infections, and emergency pediatric consults.'),
(4, 'General Physician & Women Health', 'MBBS, FCPS (General Medicine)', 10, 'PMDC-58301-G', 'verified', 1, 'Urdu, English, Burushaski', 'Available Today • 8 AM - 4 PM', 'Aga Khan Health Service Hunza', 'Passionate about maternal care, preventative medicine, and remote digital consultations.'),
(5, 'Orthopedic & Trauma Surgery', 'MBBS, MS (Orthopedics)', 6, 'PMDC-89104-O', 'pending', 0, 'Urdu, English, Shina', 'Mon - Sat • 10 AM - 2 PM', 'Chilas Civil Hospital', 'Specialist in trauma care, fracture management, and rehabilitation.')
ON DUPLICATE KEY UPDATE `verification_status` = VALUES(`verification_status`);

-- 3. Insert Patient Profiles
INSERT INTO `patient_profiles` (`user_id`, `age`, `gender`, `blood_group`, `emergency_contact`, `allergies`, `chronic_conditions`) VALUES
(6, 42, 'Male', 'B+', '+92 321 9876543 (Brother - Tariq Khan)', 'Penicillin, Dust', 'Hypertension (Mild)'),
(7, 28, 'Female', 'O+', '+92 333 1234567 (Husband - Ali Raza)', 'Sulfa drugs', 'None')
ON DUPLICATE KEY UPDATE `emergency_contact` = VALUES(`emergency_contact`);

-- 4. Insert Consultations
INSERT INTO `consultations` (`id`, `patient_id`, `doctor_id`, `symptoms`, `risk_level`, `status`, `doctor_notes`, `requested_at`) VALUES
(1, 6, 2, 'Chest tightness during physical activity, mild breathlessness for 2 days.', 'high', 'in_progress', 'Patient monitored for stable vitals. Prescribed sublingual nitrates and ECG recommended.', NOW() - INTERVAL 1 HOUR),
(2, 7, 4, 'Recurring migraine headache and sensitivity to light in high altitude.', 'moderate', 'completed', 'Advised hydration, prophylactic analgesics, and symptom log.', NOW() - INTERVAL 2 DAY)
ON DUPLICATE KEY UPDATE `status` = VALUES(`status`);

-- 5. Insert Chat Messages
INSERT INTO `chat_messages` (`id`, `consultation_id`, `sender_id`, `sender_role`, `message`, `is_emergency_notice`, `created_at`) VALUES
(1, 1, 6, 'patient', 'Assalam-o-Alaikum Doctor, I have been feeling chest pressure since yesterday evening.', 0, NOW() - INTERVAL 50 MINUTE),
(2, 1, 2, 'doctor', 'Walaikum Assalam Ahmed. Does the pain radiate to your left arm or jaw?', 0, NOW() - INTERVAL 45 MINUTE),
(3, 1, 6, 'patient', 'No radiation, but I feel slightly breathless when climbing stairs.', 0, NOW() - INTERVAL 40 MINUTE),
(4, 1, 2, 'doctor', 'Please rest immediately. Sit in an upright position. I have noted your vitals.', 1, NOW() - INTERVAL 35 MINUTE)
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- 6. Insert Prescriptions
INSERT INTO `prescriptions` (`id`, `consultation_id`, `patient_id`, `doctor_id`, `doctor_name`, `doctor_specialty`, `is_verified`, `created_at`) VALUES
(1, 1, 6, 2, 'Dr. Ayesha Siddiqui', 'Cardiology / Emergency Medicine', 1, NOW() - INTERVAL 30 MINUTE),
(2, 2, 7, 4, 'Dr. Fatima Zahra', 'General Medicine', 1, NOW() - INTERVAL 2 DAY)
ON DUPLICATE KEY UPDATE `is_verified` = VALUES(`is_verified`);

-- 7. Insert Prescription Items
INSERT INTO `prescription_items` (`id`, `prescription_id`, `medicine_name`, `dosage`, `frequency`, `duration`, `instructions`) VALUES
(1, 1, 'Tab. Loprin (Aspirin)', '75mg', 'Once daily', '30 days', 'Take after lunch with full glass of water'),
(2, 1, 'Tab. Angised (Nitroglycerin)', '0.5mg', 'As needed', '10 days', 'Keep under tongue if acute chest discomfort occurs'),
(3, 2, 'Tab. Panadol Extra', '500mg', 'Twice daily', '5 days', 'Take after meals for severe headache'),
(4, 2, 'Cap. Risek (Omeprazole)', '20mg', 'Once daily', '14 days', 'Take 30 minutes before breakfast')
ON DUPLICATE KEY UPDATE `dosage` = VALUES(`dosage`);

-- 8. Insert Medicine Reminders
INSERT INTO `medicine_reminders` (`id`, `patient_id`, `medicine_name`, `dosage`, `frequency`, `time_of_day`, `start_date`, `end_date`, `is_active`, `instructions`) VALUES
(1, 6, 'Loprin (Aspirin)', '75mg', 'Once daily', '01:00 PM', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 1, 'Post lunch daily cardio protection'),
(2, 6, 'Concor (Bisoprolol)', '2.5mg', 'Once daily', '08:00 AM', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 1, 'Morning blood pressure management'),
(3, 7, 'Risek (Omeprazole)', '20mg', 'Once daily', '07:30 AM', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY), 1, 'Empty stomach with plain water')
ON DUPLICATE KEY UPDATE `is_active` = VALUES(`is_active`);

-- 9. Insert Medical Records
INSERT INTO `medical_records` (`id`, `patient_id`, `title`, `category`, `doctor_or_lab`, `description`, `diagnosis`, `record_date`) VALUES
(1, 6, '12-Lead Electrocardiogram (ECG)', 'lab_report', 'Gilgit Diagnostic Center', 'Sinus rhythm, normal axis, no acute ST elevations detected.', 'Normal Sinus Rhythm', DATE_SUB(CURDATE(), INTERVAL 7 DAY)),
(2, 6, 'Emergency Cardiac Consultation', 'consultation', 'Dr. Ayesha Siddiqui', 'Tele-triage session completed. Recommended blood lipid panel and stress testing.', 'Atypical Angina Evaluation', CURDATE()),
(3, 7, 'Complete Blood Count (CBC)', 'lab_report', 'Aga Khan Lab Skardu', 'Hemoglobin 13.2 g/dL, Platelets normal, TLC within reference limits.', 'Normal CBC Profile', DATE_SUB(CURDATE(), INTERVAL 15 DAY))
ON DUPLICATE KEY UPDATE `title` = VALUES(`title`);

-- 10. Insert Emergency SOS Alerts
INSERT INTO `emergency_alerts` (`id`, `patient_id`, `symptom_description`, `risk_level`, `latitude`, `longitude`, `city`, `status`, `created_at`) VALUES
(1, 6, 'Sudden severe palpitations and dizziness while at high altitude pass.', 'high', 35.92080000, 74.31440000, 'Gilgit', 'reviewed', NOW() - INTERVAL 4 HOUR),
(2, 7, 'Acute allergic reaction with facial swelling after bee sting.', 'high', 35.29710000, 75.63330000, 'Skardu', 'resolved', NOW() - INTERVAL 1 DAY)
ON DUPLICATE KEY UPDATE `status` = VALUES(`status`);
