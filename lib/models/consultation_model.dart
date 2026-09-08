import 'doctor_model.dart';
import 'user_model.dart';
import 'triage_model.dart';

enum ConsultationStatus { pending, inProgress, completed, cancelled }

class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final bool isFromDoctor;
  final bool isFromAi;
  final String message;
  final DateTime timestamp;
  final bool isEmergencyNotice;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.isFromDoctor = false,
    this.isFromAi = false,
    required this.message,
    required this.timestamp,
    this.isEmergencyNotice = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final role = json['sender_role']?.toString().toLowerCase();
    return ChatMessageModel(
      id: json['id']?.toString() ?? '0',
      senderId: json['sender_id']?.toString() ?? '0',
      senderName: json['sender_name'] ?? 'User',
      isFromDoctor: role == 'doctor',
      isFromAi: role == 'system',
      message: json['message'] ?? '',
      timestamp: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isEmergencyNotice: json['is_emergency_notice'] == true || json['is_emergency_notice'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'is_from_doctor': isFromDoctor,
      'is_from_ai': isFromAi,
      'message': message,
      'created_at': timestamp.toIso8601String(),
      'is_emergency_notice': isEmergencyNotice,
    };
  }
}

class ConsultationModel {
  final String id;
  final UserModel patient;
  final DoctorModel doctor;
  final String symptoms;
  final TriageModel? triageSummary;
  final ConsultationStatus status;
  final DateTime requestedAt;
  final DateTime? scheduledAt;
  final List<ChatMessageModel> chatMessages;
  final String? doctorNotes;

  const ConsultationModel({
    required this.id,
    required this.patient,
    required this.doctor,
    required this.symptoms,
    this.triageSummary,
    this.status = ConsultationStatus.pending,
    required this.requestedAt,
    this.scheduledAt,
    this.chatMessages = const [],
    this.doctorNotes,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    ConsultationStatus status = ConsultationStatus.pending;
    final statusStr = json['status']?.toString().toLowerCase();
    if (statusStr == 'in_progress') status = ConsultationStatus.inProgress;
    if (statusStr == 'completed') status = ConsultationStatus.completed;
    if (statusStr == 'cancelled') status = ConsultationStatus.cancelled;

    final rawMessages = json['messages'] as List? ?? [];

    return ConsultationModel(
      id: json['id']?.toString() ?? '0',
      patient: UserModel(
        id: json['patient_id']?.toString() ?? '6',
        fullName: json['patient_name'] ?? 'Ahmed Khan',
        email: json['patient_email'] ?? 'ahmed.khan@gmail.com',
        phone: json['patient_phone'] ?? '+92 321 5555555',
        role: UserRole.patient,
        city: json['patient_city'] ?? 'Gilgit',
        age: int.tryParse(json['patient_age']?.toString() ?? '42') ?? 42,
        gender: json['patient_gender'] ?? 'Male',
        bloodGroup: json['patient_blood_group'] ?? 'B+',
      ),
      doctor: DoctorModel(
        id: json['doctor_id']?.toString() ?? '2',
        name: json['doctor_name'] ?? 'Dr. Ayesha Siddiqui',
        specialization: json['doctor_specialization'] ?? 'Cardiology',
        qualification: 'MBBS, FCPS',
        experienceYears: 12,
        pmdcNumber: 'PMDC-45892-A',
        consultationFee: 0.0,
        languages: const ['Urdu', 'English'],
        availability: 'Available Today',
        hospitalAffiliation: json['doctor_hospital'] ?? 'DHQ Hospital Gilgit',
        about: 'Specialist physician.',
        avatarUrl: json['doctor_avatar'] ?? 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=150',
      ),
      symptoms: json['symptoms'] ?? 'Telehealth Consultation',
      status: status,
      requestedAt: json['requested_at'] != null
          ? DateTime.tryParse(json['requested_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString())
          : null,
      doctorNotes: json['doctor_notes']?.toString(),
      chatMessages: rawMessages.map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patient.id,
      'doctor_id': doctor.id,
      'symptoms': symptoms,
      'status': status.name,
      'requested_at': requestedAt.toIso8601String(),
      'scheduled_at': scheduledAt?.toIso8601String(),
      'doctor_notes': doctorNotes,
    };
  }
}

