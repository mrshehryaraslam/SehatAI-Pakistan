import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';
import 'api_service.dart';

class AdminDoctorModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String specialization;
  final String qualification;
  final int experienceYears;
  final String pmdcNumber;
  final String verificationStatus; // 'pending', 'verified', 'rejected'
  final bool isOnline;
  final String hospital;

  const AdminDoctorModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.specialization,
    required this.qualification,
    required this.experienceYears,
    required this.pmdcNumber,
    required this.verificationStatus,
    required this.isOnline,
    required this.hospital,
  });
}

class AdminMetrics {
  final int totalPatients;
  final int verifiedDoctors;
  final int pendingVerifications;
  final int totalConsultations;
  final int activeConsultations;
  final int totalEmergencyAlerts;
  final int pendingEmergencies;

  const AdminMetrics({
    required this.totalPatients,
    required this.verifiedDoctors,
    required this.pendingVerifications,
    required this.totalConsultations,
    required this.activeConsultations,
    required this.totalEmergencyAlerts,
    required this.pendingEmergencies,
  });
}

class AdminService extends ChangeNotifier {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final ApiService _api = ApiService();

  AdminMetrics? _metrics;
  List<AdminDoctorModel> _doctors = [];
  bool _isLoading = false;

  AdminMetrics? get metrics => _metrics;
  List<AdminDoctorModel> get doctors => _doctors;
  bool get isLoading => _isLoading;

  Future<AdminMetrics?> fetchMetrics() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.get(ApiEndpoints.adminMetrics);
      if (res.isSuccess && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        _metrics = AdminMetrics(
          totalPatients: int.tryParse(data['total_patients']?.toString() ?? '0') ?? 0,
          verifiedDoctors: int.tryParse(data['verified_doctors']?.toString() ?? '0') ?? 0,
          pendingVerifications: int.tryParse(data['pending_verifications']?.toString() ?? '0') ?? 0,
          totalConsultations: int.tryParse(data['total_consultations']?.toString() ?? '0') ?? 0,
          activeConsultations: int.tryParse(data['active_consultations']?.toString() ?? '0') ?? 0,
          totalEmergencyAlerts: int.tryParse(data['total_emergency_alerts']?.toString() ?? '0') ?? 0,
          pendingEmergencies: int.tryParse(data['pending_emergencies']?.toString() ?? '0') ?? 0,
        );

        _isLoading = false;
        notifyListeners();
        return _metrics;
      }
    } catch (e) {
      debugPrint('[AdminService] Metrics error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return _metrics;
  }

  Future<List<AdminDoctorModel>> fetchDoctors({String? status}) async {
    _isLoading = true;
    notifyListeners();

    try {
      String url = ApiEndpoints.adminDoctors;
      if (status != null && status.isNotEmpty) {
        url += '?status=${Uri.encodeComponent(status)}';
      }

      final res = await _api.get(url);
      if (res.isSuccess && res.data is List) {
        final list = res.data as List;
        _doctors = list.map((item) {
          final map = item as Map<String, dynamic>;
          return AdminDoctorModel(
            id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
            name: map['full_name'] ?? 'Doctor',
            email: map['email'] ?? '',
            phone: map['phone'] ?? '',
            city: map['city'] ?? 'Gilgit',
            specialization: map['specialization'] ?? 'General Physician',
            qualification: map['qualification'] ?? 'MBBS',
            experienceYears: int.tryParse(map['experience_years']?.toString() ?? '5') ?? 5,
            pmdcNumber: map['pmdc_number'] ?? 'PMDC-00000',
            verificationStatus: map['verification_status'] ?? 'pending',
            isOnline: map['is_online'] == 1 || map['is_online'] == true,
            hospital: map['hospital_affiliation'] ?? 'Civil Hospital',
          );
        }).toList();

        _isLoading = false;
        notifyListeners();
        return _doctors;
      }
    } catch (e) {
      debugPrint('[AdminService] Doctors error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return _doctors;
  }

  Future<bool> verifyDoctor({required int doctorId, required String status}) async {
    try {
      final res = await _api.post(
        ApiEndpoints.adminVerifyDoctor,
        {
          'doctor_id': doctorId,
          'status': status,
        },
      );

      if (res.isSuccess) {
        await fetchDoctors();
        await fetchMetrics();
        return true;
      }
      if (res.statusCode > 0) {
        return false;
      }
    } catch (e) {
      debugPrint('[AdminService] Verify doctor error: $e');
    }

    return false;
  }

  /// Fetch emergency SOS audit logs from live API
  Future<List<Map<String, dynamic>>> fetchEmergencyLogs() async {
    try {
      final res = await _api.get(ApiEndpoints.adminEmergencyLogs);
      if (res.isSuccess && res.data is List) {
        return List<Map<String, dynamic>>.from(
          (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
    } catch (e) {
      debugPrint('[AdminService] Emergency logs error: $e');
    }
    return [];
  }

  /// Acknowledge or resolve an emergency alert (admin only).
  /// [status] must be 'reviewed' or 'resolved'.
  Future<bool> updateEmergencyAlertStatus({
    required int alertId,
    required String status,
  }) async {
    try {
      final res = await _api.post(
        ApiEndpoints.adminEmergencyAlertStatus,
        {'alert_id': alertId, 'status': status},
      );
      return res.isSuccess;
    } catch (e) {
      debugPrint('[AdminService] Emergency alert status update error: $e');
      return false;
    }
  }
}
