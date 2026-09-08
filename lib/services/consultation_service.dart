import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';
import '../models/consultation_model.dart';
import '../models/doctor_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class ConsultationService extends ChangeNotifier {
  static final ConsultationService _instance = ConsultationService._internal();
  factory ConsultationService() => _instance;
  ConsultationService._internal();

  final ApiService _api = ApiService();
  List<ConsultationModel> _consultations = [];
  bool _isLoading = false;

  List<ConsultationModel> get consultations => _consultations;
  bool get isLoading => _isLoading;

  Future<List<ConsultationModel>> fetchPatientConsultations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.get(ApiEndpoints.patientConsultations);
      if (res.isSuccess && res.data is List) {
        final list = res.data as List;
        _consultations = list.map((item) => _mapToConsultationModel(item)).toList();
        _isLoading = false;
        notifyListeners();
        return _consultations;
      }
    } catch (e) {
      debugPrint('[ConsultationService] Fetch error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return _consultations;
  }

  Future<List<ConsultationModel>> fetchDoctorConsultations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.get(ApiEndpoints.doctorConsultations);
      if (res.isSuccess && res.data is List) {
        final list = res.data as List;
        _consultations = list.map((item) => _mapToConsultationModel(item)).toList();
        _isLoading = false;
        notifyListeners();
        return _consultations;
      }
    } catch (e) {
      debugPrint('[ConsultationService] Doctor fetch error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return _consultations;
  }

  /// Submits a real consultation request to the API.
  /// Returns true only when the server accepted the request.
  /// Never fabricates a local/demo consultation on failure.
  Future<bool> requestConsultation({
    required String symptoms,
    String? doctorId,
    String riskLevel = 'moderate',
  }) async {
    try {
      final res = await _api.post(
        ApiEndpoints.requestConsultation,
        {
          'symptoms': symptoms,
          'doctor_id': doctorId != null ? int.tryParse(doctorId) : null,
          'risk_level': riskLevel,
        },
      );

      if (res.isSuccess) {
        await fetchPatientConsultations();
        return true;
      }

      debugPrint('[ConsultationService] Request failed: ${res.message}');
      return false;
    } catch (e) {
      debugPrint('[ConsultationService] Request error: $e');
      return false;
    }
  }

  Future<bool> acceptConsultation(String consultationId) async {
    final intId = int.tryParse(consultationId);
    if (intId != null) {
      try {
        final res = await _api.post(
          ApiEndpoints.acceptConsultation(intId),
          {},
        );
        if (res.isSuccess) {
          await fetchDoctorConsultations();
          return true;
        }
        if (res.statusCode > 0) {
          return false;
        }
      } catch (e) {
        debugPrint('[ConsultationService] Accept error: $e');
      }
    }

    return false;
  }

  /// Doctor rejects (declines) a consultation request via the dedicated endpoint.
  Future<bool> rejectConsultation(String consultationId) async {
    final intId = int.tryParse(consultationId);
    if (intId != null) {
      try {
        final res = await _api.post(
          ApiEndpoints.rejectConsultation(intId),
          {},
        );
        if (res.isSuccess) {
          await fetchDoctorConsultations();
          return true;
        }
        if (res.statusCode > 0) {
          return false;
        }
      } catch (e) {
        debugPrint('[ConsultationService] Reject error: $e');
      }
    }

    return false;
  }

  Future<List<ChatMessageModel>> fetchMessages(String consultationId, {int afterId = 0}) async {
    final intId = int.tryParse(consultationId);
    if (intId != null) {
      try {
        final res = await _api.get(
          '${ApiEndpoints.consultationMessages(intId)}?after_id=$afterId',
        );
        if (res.isSuccess && res.data is List) {
          final list = res.data as List;
          return list.map((m) {
            final map = m as Map<String, dynamic>;
            final role = map['sender_role']?.toString().toLowerCase();
            return ChatMessageModel(
              id: map['id'].toString(),
              senderId: map['sender_id'].toString(),
              senderName: map['sender_name'] ?? 'User',
              isFromDoctor: role == 'doctor',
              isFromAi: role == 'system',
              message: map['message'] ?? '',
              timestamp: map['created_at'] != null
                  ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
                  : DateTime.now(),
              isEmergencyNotice: map['is_emergency_notice'] == true,
            );
          }).toList();
        }
      } catch (e) {
        debugPrint('[ConsultationService] Messages fetch error: $e');
      }
    }

    return [];
  }

  Future<bool> sendMessage(
    String consultationId,
    String message, {
    bool isEmergency = false,
  }) async {
    final intId = int.tryParse(consultationId);
    if (intId != null) {
      try {
        final res = await _api.post(
          ApiEndpoints.consultationMessages(intId),
          {
            'message': message,
            'is_emergency_notice': isEmergency ? 1 : 0,
          },
        );
        if (res.isSuccess) {
          return true;
        }
        if (res.statusCode > 0) {
          return false;
        }
      } catch (e) {
        debugPrint('[ConsultationService] Send message error: $e');
      }
    }

    return false;
  }

  /// Update consultation status via API (decline/complete)
  Future<bool> updateConsultationStatus(int consultationId, String status, {String? doctorNotes}) async {
    try {
      final res = await _api.post(
        ApiEndpoints.consultationStatus(consultationId),
        {
          'status': status,
          if (doctorNotes != null) 'doctor_notes': doctorNotes,
        },
      );
      if (res.isSuccess) {
        await fetchDoctorConsultations();
        return true;
      }
    } catch (e) {
      debugPrint('[ConsultationService] Update status error: $e');
    }
    return false;
  }

  ConsultationModel _mapToConsultationModel(dynamic json) {
    final map = json as Map<String, dynamic>;
    ConsultationStatus status = ConsultationStatus.pending;
    final statusStr = map['status']?.toString().toLowerCase();
    if (statusStr == 'in_progress') {
      status = ConsultationStatus.inProgress;
    } else if (statusStr == 'completed') {
      status = ConsultationStatus.completed;
    } else if (statusStr == 'cancelled') {
      status = ConsultationStatus.cancelled;
    }

    return ConsultationModel(
      id: map['id'].toString(),
      patient: UserModel(
        id: map['patient_id']?.toString() ?? '',
        fullName: map['patient_name']?.toString() ?? 'Patient',
        email: map['patient_email']?.toString() ?? '',
        phone: map['patient_phone']?.toString() ?? '',
        role: UserRole.patient,
        city: map['patient_city']?.toString() ?? '',
        age: int.tryParse(map['patient_age']?.toString() ?? '') ?? 0,
        gender: map['patient_gender']?.toString() ?? '',
        bloodGroup: map['patient_blood_group']?.toString() ?? '',
      ),
      doctor: DoctorModel(
        id: map['doctor_id']?.toString() ?? '',
        name: map['doctor_name']?.toString() ?? 'Doctor',
        specialization: map['doctor_specialization']?.toString() ?? 'General Physician',
        qualification: map['doctor_qualification']?.toString() ?? 'MBBS',
        experienceYears: int.tryParse(map['doctor_experience_years']?.toString() ?? '') ?? 0,
        pmdcNumber: map['doctor_pmdc']?.toString() ?? '',
        consultationFee: 0.0,
        languages: const ['Urdu', 'English'],
        availability: 'Available Today',
        hospitalAffiliation: map['doctor_hospital']?.toString() ?? '',
        about: 'Specialist physician.',
        avatarUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=150',
      ),
      symptoms: map['symptoms']?.toString() ?? '',
      status: status,
      requestedAt: map['requested_at'] != null
          ? DateTime.tryParse(map['requested_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      doctorNotes: map['doctor_notes']?.toString(),
      chatMessages: const [],
    );
  }
}
