import 'app_env.dart';

class ApiEndpoints {
  /// Optional runtime override (e.g. for integration tests).
  static String? _customBaseUrl;

  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Base URL resolved from [AppEnv] (DEV in debug, PROD in release).
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    return AppEnv.apiUrl;
  }

  // Auth
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get me => '$baseUrl/auth/me';

  // Doctors
  static String get doctors => '$baseUrl/doctors';
  static String get doctorMe => '$baseUrl/doctors/me';
  static String get doctorStatus => '$baseUrl/doctors/status';
  static String doctorDetail(int id) => '$baseUrl/doctors/$id';

  // Consultations
  static String get requestConsultation => '$baseUrl/consultations/request';
  static String get doctorConsultations => '$baseUrl/consultations/doctor';
  static String get patientConsultations => '$baseUrl/consultations/patient';
  static String acceptConsultation(int id) => '$baseUrl/consultations/$id/accept';
  static String rejectConsultation(int id) => '$baseUrl/consultations/$id/reject';
  static String consultationStatus(int id) => '$baseUrl/consultations/$id/status';
  static String consultationMessages(int id) => '$baseUrl/consultations/$id/messages';

  // Medicines
  static String get medicines => '$baseUrl/medicines';
  static String get medicineAdherence => '$baseUrl/medicines/adherence';
  static String medicineDetail(int id) => '$baseUrl/medicines/$id';
  static String toggleMedicine(int id) => '$baseUrl/medicines/$id/toggle';
  static String markMedicineIntake(int id) => '$baseUrl/medicines/$id/intake';

  // Prescriptions
  static String get prescriptions => '$baseUrl/prescriptions';
  static String prescriptionDetail(int id) => '$baseUrl/prescriptions/$id';

  // Records
  static String get records => '$baseUrl/records';

  // Emergency
  static String get emergencySos => '$baseUrl/emergency/sos';
  static String get emergencyAlerts => '$baseUrl/emergency/alerts';

  // AI Triage
  static String get aiTriage => '$baseUrl/ai/triage';

  // Admin
  static String get adminMetrics => '$baseUrl/admin/metrics';
  static String get adminDoctors => '$baseUrl/admin/doctors';
  static String get adminVerifyDoctor => '$baseUrl/admin/verify-doctor';
  static String get adminEmergencyLogs => '$baseUrl/admin/emergency-logs';
  static String get adminEmergencyAlertStatus => '$baseUrl/admin/emergency-alert-status';

  // Health Continuity Engine (AI Patient Brief + AI Care Plan)
  static String get patientBrief => '$baseUrl/ai/patient-brief';
  static String patientBriefByConsultation(int id) => '$baseUrl/ai/patient-brief/$id';
  static String get carePlan => '$baseUrl/ai/care-plan';
  static String carePlanByConsultation(int id) => '$baseUrl/ai/care-plan/$id';
}

