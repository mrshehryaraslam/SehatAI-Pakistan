-- SehatAI Pakistan — Phase 5 Migration: Health Continuity Engine tables
-- Applies the missing ai_patient_briefs and ai_care_plans tables to existing
-- installations without re-running schema.sql / seed.sql (no data loss).
--
-- Usage:
--   mysql -u root sehatai_pakistan < migration_phase5_continuity_tables.sql



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
