-- Phase 6: Medicine Intake Logs (Adherence Tracking)
-- Tracks daily Taken/Missed status per medicine reminder.



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
