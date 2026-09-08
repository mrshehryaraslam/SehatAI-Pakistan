<?php
/**
 * SehatAI Pakistan - Main REST API Gateway & Router
 */

declare(strict_types=1);

require_once __DIR__ . '/config/cors.php';
require_once __DIR__ . '/config/env_loader.php';   // Load .env before constants
require_once __DIR__ . '/config/constants.php';
require_once __DIR__ . '/utils/response.php';

// Handle CORS Pre-flight and headers
handleCors();

// Autoload Controllers
require_once __DIR__ . '/controllers/AuthController.php';
require_once __DIR__ . '/controllers/DoctorController.php';
require_once __DIR__ . '/controllers/ConsultationController.php';
require_once __DIR__ . '/controllers/ChatController.php';
require_once __DIR__ . '/controllers/MedicineController.php';
require_once __DIR__ . '/controllers/PrescriptionController.php';
require_once __DIR__ . '/controllers/MedicalRecordController.php';
require_once __DIR__ . '/controllers/EmergencyController.php';
require_once __DIR__ . '/controllers/AdminController.php';
require_once __DIR__ . '/controllers/AiController.php';
require_once __DIR__ . '/controllers/HealthContinuityController.php';


// Parse Request Method and URI
$requestMethod = $_SERVER['REQUEST_METHOD'];
$requestUri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// Normalize path: strip script directory if running under XAMPP subfolder
$scriptName = dirname($_SERVER['SCRIPT_NAME']); // e.g. /SehatAI Pakistan/api or /api
if ($scriptName !== '/' && str_starts_with($requestUri, $scriptName)) {
    $path = substr($requestUri, strlen($scriptName));
} else {
    // If not matching, clean up common prefixes
    $path = preg_replace('#^/.*?api#', '', $requestUri);
}

$path = '/' . trim($path, '/');

// Base Root / Health check
if ($path === '/' || $path === '/health' || $path === '') {
    sendSuccess('SehatAI Pakistan Healthcare REST API Engine is active.', [
        'name' => APP_NAME,
        'version' => APP_VERSION,
        'time' => date('Y-m-d H:i:s'),
        'status' => 'operational',
        'gemini_api_key_configured' => !empty(GEMINI_API_KEY),
        'ai_engine' => !empty(GEMINI_API_KEY) ? 'google_gemini_api' : 'offline_rule_engine',
    ]);
}

// -------------------------------------------------------------
// ROUTE DISPATCHER
// -------------------------------------------------------------

try {
    // 1. Auth Routes
    if ($path === '/auth/register' && $requestMethod === 'POST') {
        (new AuthController())->register();
    }
    if ($path === '/auth/login' && $requestMethod === 'POST') {
        (new AuthController())->login();
    }
    if ($path === '/auth/me' && $requestMethod === 'GET') {
        (new AuthController())->me();
    }

    // 2. Doctor Routes
    if ($path === '/doctors' && $requestMethod === 'GET') {
        (new DoctorController())->index();
    }
    if ($path === '/doctors/me' && $requestMethod === 'GET') {
        (new DoctorController())->me();
    }
    if ($path === '/doctors/status' && $requestMethod === 'POST') {
        (new DoctorController())->toggleStatus();
    }
    if (preg_match('#^/doctors/(\d+)$#', $path, $matches) && $requestMethod === 'GET') {
        (new DoctorController())->show((int)$matches[1]);
    }

    // 3. Consultation Routes
    if ($path === '/consultations/request' && $requestMethod === 'POST') {
        (new ConsultationController())->requestConsultation();
    }
    if ($path === '/consultations/doctor' && $requestMethod === 'GET') {
        (new ConsultationController())->getDoctorConsultations();
    }
    if ($path === '/consultations/patient' && $requestMethod === 'GET') {
        (new ConsultationController())->getPatientConsultations();
    }
    if (preg_match('#^/consultations/(\d+)/accept$#', $path, $matches) && $requestMethod === 'POST') {
        (new ConsultationController())->acceptConsultation((int)$matches[1]);
    }
    if (preg_match('#^/consultations/(\d+)/reject$#', $path, $matches) && $requestMethod === 'POST') {
        (new ConsultationController())->rejectConsultation((int)$matches[1]);
    }
    if (preg_match('#^/consultations/(\d+)/status$#', $path, $matches) && $requestMethod === 'POST') {
        (new ConsultationController())->updateStatus((int)$matches[1]);
    }

    // 4. Chat Messages Routes
    if (preg_match('#^/consultations/(\d+)/messages$#', $path, $matches)) {
        if ($requestMethod === 'GET') {
            (new ChatController())->getMessages((int)$matches[1]);
        } else if ($requestMethod === 'POST') {
            (new ChatController())->sendMessage((int)$matches[1]);
        }
    }

    // 5. Medicine Reminders Routes
    if ($path === '/medicines') {
        if ($requestMethod === 'GET') {
            (new MedicineController())->index();
        } else if ($requestMethod === 'POST') {
            (new MedicineController())->store();
        }
    }
    if ($path === '/medicines/adherence' && $requestMethod === 'GET') {
        (new MedicineController())->adherence();
    }
    if (preg_match('#^/medicines/(\d+)/toggle$#', $path, $matches) && $requestMethod === 'POST') {
        (new MedicineController())->toggle((int)$matches[1]);
    }
    if (preg_match('#^/medicines/(\d+)/intake$#', $path, $matches) && $requestMethod === 'POST') {
        (new MedicineController())->markIntake((int)$matches[1]);
    }
    if (preg_match('#^/medicines/(\d+)$#', $path, $matches)) {
        if ($requestMethod === 'PUT') {
            (new MedicineController())->update((int)$matches[1]);
        } else if ($requestMethod === 'DELETE') {
            (new MedicineController())->destroy((int)$matches[1]);
        }
    }

    // 6. Prescription Routes
    if ($path === '/prescriptions') {
        if ($requestMethod === 'GET') {
            (new PrescriptionController())->index();
        } else if ($requestMethod === 'POST') {
            (new PrescriptionController())->store();
        }
    }
    if (preg_match('#^/prescriptions/(\d+)$#', $path, $matches) && $requestMethod === 'GET') {
        (new PrescriptionController())->show((int)$matches[1]);
    }

    // 7. Medical Records Routes
    if ($path === '/records') {
        if ($requestMethod === 'GET') {
            (new MedicalRecordController())->index();
        } else if ($requestMethod === 'POST') {
            (new MedicalRecordController())->store();
        }
    }

    // 8. Emergency SOS Routes
    if ($path === '/emergency/sos' && $requestMethod === 'POST') {
        (new EmergencyController())->logSos();
    }
    if ($path === '/emergency/alerts' && $requestMethod === 'GET') {
        (new EmergencyController())->getAlerts();
    }

    // 9. Admin Routes
    if ($path === '/admin/metrics' && $requestMethod === 'GET') {
        (new AdminController())->getMetrics();
    }
    if ($path === '/admin/doctors' && $requestMethod === 'GET') {
        (new AdminController())->getDoctors();
    }
    if ($path === '/admin/verify-doctor' && $requestMethod === 'POST') {
        (new AdminController())->verifyDoctor();
    }
    if ($path === '/admin/emergency-logs' && $requestMethod === 'GET') {
        (new AdminController())->getEmergencyLogs();
    }
    if ($path === '/admin/emergency-alert-status' && $requestMethod === 'POST') {
        (new AdminController())->updateEmergencyAlertStatus();
    }

    // 10. AI Assistant & Triage Routes
    if ($path === '/ai/triage' && $requestMethod === 'POST') {
        (new AiController())->triage();
    }

    // 11. Health Continuity Engine Routes (AI Patient Brief + AI Care Plan)
    if ($path === '/ai/patient-brief' && $requestMethod === 'POST') {
        (new HealthContinuityController())->generatePatientBrief();
    }
    if (preg_match('#^/ai/patient-brief/(\d+)$#', $path, $matches) && $requestMethod === 'GET') {
        (new HealthContinuityController())->getPatientBrief((int)$matches[1]);
    }
    if ($path === '/ai/care-plan' && $requestMethod === 'POST') {
        (new HealthContinuityController())->generateCarePlan();
    }
    if (preg_match('#^/ai/care-plan/(\d+)$#', $path, $matches) && $requestMethod === 'GET') {
        (new HealthContinuityController())->getCarePlan((int)$matches[1]);
    }


    // Fallback: Route Not Found
    sendError("Endpoint {$requestMethod} {$path} not found.", 404);

} catch (Throwable $e) {
    sendError('Internal Server Error: ' . $e->getMessage(), 500);
}
