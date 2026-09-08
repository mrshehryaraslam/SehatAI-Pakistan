-- SehatAI Pakistan Seed Data
-- Default Admin, Verified Doctors, Pending Doctor, Patients, Consultations, Prescriptions, Reminders, and Records



-- Disable Foreign Key checks for clean re-seeding
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE `emergency_alerts`;
TRUNCATE TABLE `medical_records`;
TRUNCATE TABLE `medicine_reminders`;
TRUNCATE TABLE `prescription_items`;
TRUNCATE TABLE `prescriptions`;
TRUNCATE TABLE `chat_messages`;
TRUNCATE TABLE `consultations`;
TRUNCATE TABLE `doctor_profiles`;
TRUNCATE TABLE `patient_profiles`;
TRUNCATE TABLE `users`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Insert Users (Admin, Doctors, Patients)
-- Passwords are bcrypt-hashed below. See setup_db.php for password generation.
-- Default test credentials are documented in .env.example (never commit real passwords).

INSERT INTO `users` (`id`, `full_name`, `email`, `phone`, `password_hash`, `role`, `city`) VALUES
(1, 'System Administrator', 'admin@sehat.ai', '+92 300 0000001', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 'Islamabad'),
(2, 'Dr. Ayesha Siddiqui', 'ayesha.siddiqui@sehat.ai', '+92 300 1111111', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'doctor', 'Gilgit'),
(3, 'Dr. Bilal Tariq', 'bilal.tariq@sehat.ai', '+92 300 2222222', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'doctor', 'Skardu'),
(4, 'Dr. Fatima Zahra', 'fatima.zahra@sehat.ai', '+92 300 3333333', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'doctor', 'Hunza'),
(5, 'Dr. Tariq Mehmood', 'tariq.mehmood@sehat.ai', '+92 300 4444444', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'doctor', 'Chilas'),
(6, 'Ahmed Khan', 'ahmed.khan@gmail.com', '+92 321 5555555', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'patient', 'Gilgit'),
(7, 'Zainab Bibi', 'zainab.bibi@gmail.com', '+92 333 6666666', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'patient', 'Skardu');

-- 2. Insert Doctor Profiles
INSERT INTO `doctor_profiles` (`user_id`, `specialization`, `qualification`, `experience_years`, `pmdc_number`, `verification_status`, `is_online`, `languages`, `availability`, `hospital_affiliation`, `bio`) VALUES
(2, 'Cardiology / Emergency Medicine', 'MBBS, FCPS (Cardiology)', 12, 'PMDC-45892-A', 'verified', 1, 'Urdu, English, Shina', 'Available Today • 9 AM - 8 PM', 'DHQ Hospital Gilgit', 'Experienced cardiologist and emergency triage specialist serving northern Pakistan.'),
(3, 'Pediatrics & Neonatology', 'MBBS, DCH, MCPS', 8, 'PMDC-67219-P', 'verified', 1, 'Urdu, English, Balti', 'Available Today • 10 AM - 6 PM', 'Skardu Child Healthcare Center', 'Dedicated to child wellness, acute infections, and emergency pediatric consults.'),
(4, 'General Physician & Women Health', 'MBBS, FCPS (General Medicine)', 10, 'PMDC-58301-G', 'verified', 1, 'Urdu, English, Burushaski', 'Available Today • 8 AM - 4 PM', 'Aga Khan Health Service Hunza', 'Passionate about maternal care, preventative medicine, and remote digital consultations.'),
(5, 'Orthopedic & Trauma Surgery', 'MBBS, MS (Orthopedics)', 6, 'PMDC-89104-O', 'pending', 0, 'Urdu, English, Shina', 'Mon - Sat • 10 AM - 2 PM', 'Chilas Civil Hospital', 'Specialist in trauma care, fracture management, and rehabilitation.');

-- 3. Insert Patient Profiles
INSERT INTO `patient_profiles` (`user_id`, `age`, `gender`, `blood_group`, `emergency_contact`, `allergies`, `chronic_conditions`) VALUES
(6, 42, 'Male', 'B+', '+92 321 9876543 (Brother - Tariq Khan)', 'Penicillin, Dust', 'Hypertension (Mild)'),
(7, 28, 'Female', 'O+', '+92 333 1234567 (Husband - Ali Raza)', 'Sulfa drugs', 'None');

-- 4. Insert Consultations
INSERT INTO `consultations` (`id`, `patient_id`, `doctor_id`, `symptoms`, `risk_level`, `status`, `doctor_notes`, `requested_at`) VALUES
(1, 6, 2, 'Chest tightness during physical activity, mild breathlessness for 2 days.', 'high', 'in_progress', 'Patient monitored for stable vitals. Prescribed sublingual nitrates and ECG recommended.', NOW() - INTERVAL 1 HOUR),
(2, 7, 4, 'Recurring migraine headache and sensitivity to light in high altitude.', 'moderate', 'completed', 'Advised hydration, prophylactic analgesics, and symptom log.', NOW() - INTERVAL 2 DAY);

-- 5. Insert Chat Messages
INSERT INTO `chat_messages` (`id`, `consultation_id`, `sender_id`, `sender_role`, `message`, `is_emergency_notice`, `created_at`) VALUES
(1, 1, 6, 'patient', 'Assalam-o-Alaikum Doctor, I have been feeling chest pressure since yesterday evening.', 0, NOW() - INTERVAL 50 MINUTE),
(2, 1, 2, 'doctor', 'Walaikum Assalam Ahmed. Does the pain radiate to your left arm or jaw?', 0, NOW() - INTERVAL 45 MINUTE),
(3, 1, 6, 'patient', 'No radiation, but I feel slightly breathless when climbing stairs.', 0, NOW() - INTERVAL 40 MINUTE),
(4, 1, 2, 'doctor', 'Please rest immediately. Sit in an upright position. I have noted your vitals.', 1, NOW() - INTERVAL 35 MINUTE);

-- 6. Insert Prescriptions
INSERT INTO `prescriptions` (`id`, `consultation_id`, `patient_id`, `doctor_id`, `doctor_name`, `doctor_specialty`, `is_verified`, `created_at`) VALUES
(1, 1, 6, 2, 'Dr. Ayesha Siddiqui', 'Cardiology / Emergency Medicine', 1, NOW() - INTERVAL 30 MINUTE),
(2, 2, 7, 4, 'Dr. Fatima Zahra', 'General Medicine', 1, NOW() - INTERVAL 2 DAY);

-- 7. Insert Prescription Items
INSERT INTO `prescription_items` (`id`, `prescription_id`, `medicine_name`, `dosage`, `frequency`, `duration`, `instructions`) VALUES
(1, 1, 'Tab. Loprin (Aspirin)', '75mg', 'Once daily', '30 days', 'Take after lunch with full glass of water'),
(2, 1, 'Tab. Angised (Nitroglycerin)', '0.5mg', 'As needed', '10 days', 'Keep under tongue if acute chest discomfort occurs'),
(3, 2, 'Tab. Panadol Extra', '500mg', 'Twice daily', '5 days', 'Take after meals for severe headache'),
(4, 2, 'Cap. Risek (Omeprazole)', '20mg', 'Once daily', '14 days', 'Take 30 minutes before breakfast');

-- 8. Insert Medicine Reminders
INSERT INTO `medicine_reminders` (`id`, `patient_id`, `medicine_name`, `dosage`, `frequency`, `time_of_day`, `start_date`, `end_date`, `is_active`, `instructions`) VALUES
(1, 6, 'Loprin (Aspirin)', '75mg', 'Once daily', '01:00 PM', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 1, 'Post lunch daily cardio protection'),
(2, 6, 'Concor (Bisoprolol)', '2.5mg', 'Once daily', '08:00 AM', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 1, 'Morning blood pressure management'),
(3, 7, 'Risek (Omeprazole)', '20mg', 'Once daily', '07:30 AM', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY), 1, 'Empty stomach with plain water');

-- 9. Insert Medical Records
INSERT INTO `medical_records` (`id`, `patient_id`, `title`, `category`, `doctor_or_lab`, `description`, `diagnosis`, `record_date`) VALUES
(1, 6, '12-Lead Electrocardiogram (ECG)', 'lab_report', 'Gilgit Diagnostic Center', 'Sinus rhythm, normal axis, no acute ST elevations detected.', 'Normal Sinus Rhythm', DATE_SUB(CURDATE(), INTERVAL 7 DAY)),
(2, 6, 'Emergency Cardiac Consultation', 'consultation', 'Dr. Ayesha Siddiqui', 'Tele-triage session completed. Recommended blood lipid panel and stress testing.', 'Atypical Angina Evaluation', CURDATE()),
(3, 7, 'Complete Blood Count (CBC)', 'lab_report', 'Aga Khan Lab Skardu', 'Hemoglobin 13.2 g/dL, Platelets normal, TLC within reference limits.', 'Normal CBC Profile', DATE_SUB(CURDATE(), INTERVAL 15 DAY));

-- 10. Insert Emergency SOS Alerts
INSERT INTO `emergency_alerts` (`id`, `patient_id`, `symptom_description`, `risk_level`, `latitude`, `longitude`, `city`, `status`, `created_at`) VALUES
(1, 6, 'Sudden severe palpitations and dizziness while at high altitude pass.', 'high', 35.92080000, 74.31440000, 'Gilgit', 'reviewed', NOW() - INTERVAL 4 HOUR),
(2, 7, 'Acute allergic reaction with facial swelling after bee sting.', 'high', 35.29710000, 75.63330000, 'Skardu', 'resolved', NOW() - INTERVAL 1 DAY);
