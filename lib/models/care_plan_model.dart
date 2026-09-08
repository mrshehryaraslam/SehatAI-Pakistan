import 'dart:convert';

/// Medicine-level guidance within a care plan.
class MedicineGuidance {
  final String medicineName;
  final String howToTake;
  final String sideEffectsWatch;

  const MedicineGuidance({
    required this.medicineName,
    required this.howToTake,
    required this.sideEffectsWatch,
  });

  factory MedicineGuidance.fromJson(Map<String, dynamic> json) {
    return MedicineGuidance(
      medicineName: json['medicine']?.toString() ?? json['medicine_name']?.toString() ?? 'Medicine',
      howToTake: json['how_to_take']?.toString() ?? 'Take as directed by your doctor.',
      sideEffectsWatch: json['side_effects_watch']?.toString() ?? 'Report any unusual reactions.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicine': medicineName,
      'how_to_take': howToTake,
      'side_effects_watch': sideEffectsWatch,
    };
  }
}

/// AI Care Plan model — post-consultation recovery guidance generated for patients
/// when a consultation is completed with a prescription.
class CarePlanModel {
  final String id;
  final String consultationId;
  final String? prescriptionId;
  final int patientId;
  final int doctorId;
  final String carePlanText;
  final List<MedicineGuidance> medicineGuidance;
  final List<String> warningSigns;
  final List<String> lifestyleRecommendations;
  final List<String> homeMonitoring;
  final DateTime? followUpDate;
  final String source;
  final String language;
  final String? patientName;
  final String? doctorName;
  final String? doctorSpecialty;
  final DateTime createdAt;

  const CarePlanModel({
    required this.id,
    required this.consultationId,
    this.prescriptionId,
    required this.patientId,
    required this.doctorId,
    required this.carePlanText,
    this.medicineGuidance = const [],
    this.warningSigns = const [],
    this.lifestyleRecommendations = const [],
    this.homeMonitoring = const [],
    this.followUpDate,
    this.source = 'offline_template',
    this.language = 'english',
    this.patientName,
    this.doctorName,
    this.doctorSpecialty,
    required this.createdAt,
  });

  /// Days remaining until the follow-up appointment.
  int? get daysUntilFollowUp {
    if (followUpDate == null) return null;
    final diff = followUpDate!.difference(DateTime.now()).inDays;
    return diff >= 0 ? diff : null;
  }

  factory CarePlanModel.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_data'];
    Map<String, dynamic> s = {};
    if (structured is Map<String, dynamic>) {
      s = structured;
    } else if (structured is String) {
      try {
        final decoded = jsonDecode(structured);
        if (decoded is Map<String, dynamic>) {
          s = decoded;
        }
      } catch (_) {}
    }

    final rawMeds = s['medication_guidance'];
    List<MedicineGuidance> meds = [];
    if (rawMeds is List) {
      meds = rawMeds
          .map((m) => MedicineGuidance.fromJson(m is Map<String, dynamic> ? m : {}))
          .toList();
    }

    DateTime? followUp;
    if (json['follow_up_date'] != null && json['follow_up_date'].toString().isNotEmpty) {
      followUp = DateTime.tryParse(json['follow_up_date'].toString());
    }

    return CarePlanModel(
      id: json['id']?.toString() ?? '0',
      consultationId: json['consultation_id']?.toString() ?? '0',
      prescriptionId: json['prescription_id']?.toString(),
      patientId: int.tryParse(json['patient_id']?.toString() ?? '0') ?? 0,
      doctorId: int.tryParse(json['doctor_id']?.toString() ?? '0') ?? 0,
      carePlanText: json['care_plan_text']?.toString() ?? '',
      medicineGuidance: meds,
      warningSigns: _parseStringList(s['warning_signs']),
      lifestyleRecommendations: _parseStringList(s['lifestyle_recommendations']),
      homeMonitoring: _parseStringList(s['home_monitoring']),
      followUpDate: followUp,
      source: json['source']?.toString() ?? 'offline_template',
      language: json['language']?.toString() ?? 'english',
      patientName: json['patient_name']?.toString(),
      doctorName: json['doctor_name']?.toString(),
      doctorSpecialty: json['doctor_specialty']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consultation_id': consultationId,
      'prescription_id': prescriptionId,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'care_plan_text': carePlanText,
      'structured_data': {
        'medication_guidance': medicineGuidance.map((m) => m.toJson()).toList(),
        'warning_signs': warningSigns,
        'lifestyle_recommendations': lifestyleRecommendations,
        'home_monitoring': homeMonitoring,
      },
      'follow_up_date': followUpDate?.toIso8601String(),
      'source': source,
      'language': language,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
