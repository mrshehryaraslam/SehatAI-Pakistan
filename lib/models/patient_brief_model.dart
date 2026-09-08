import 'dart:convert';

/// AI Patient Brief model — structured clinical summary generated for doctors
/// when they accept a consultation. Powered by the Health Continuity Engine.
class PatientBriefModel {
  final String id;
  final String consultationId;
  final int patientId;
  final int doctorId;
  final String briefText;
  final String chiefComplaint;
  final String symptomTimeline;
  final List<String> riskFactors;
  final String relevantHistory;
  final String currentMedicationsSummary;
  final String allergiesAndContraindications;
  final String aiTriageAssessment;
  final List<String> suggestedFocusAreas;
  final String source;
  final String language;
  final DateTime createdAt;

  const PatientBriefModel({
    required this.id,
    required this.consultationId,
    required this.patientId,
    required this.doctorId,
    required this.briefText,
    this.chiefComplaint = '',
    this.symptomTimeline = '',
    this.riskFactors = const [],
    this.relevantHistory = '',
    this.currentMedicationsSummary = '',
    this.allergiesAndContraindications = '',
    this.aiTriageAssessment = '',
    this.suggestedFocusAreas = const [],
    this.source = 'offline_template',
    this.language = 'english',
    required this.createdAt,
  });

  factory PatientBriefModel.fromJson(Map<String, dynamic> json) {
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

    return PatientBriefModel(
      id: json['id']?.toString() ?? '0',
      consultationId: json['consultation_id']?.toString() ?? '0',
      patientId: int.tryParse(json['patient_id']?.toString() ?? '0') ?? 0,
      doctorId: int.tryParse(json['doctor_id']?.toString() ?? '0') ?? 0,
      briefText: json['brief_text']?.toString() ?? '',
      chiefComplaint: s['chief_complaint']?.toString() ?? '',
      symptomTimeline: s['symptom_timeline']?.toString() ?? '',
      riskFactors: _parseStringList(s['risk_factors']),
      relevantHistory: s['relevant_history']?.toString() ?? '',
      currentMedicationsSummary: s['current_medications_summary']?.toString() ?? '',
      allergiesAndContraindications: s['allergies_and_contraindications']?.toString() ?? '',
      aiTriageAssessment: s['ai_triage_assessment']?.toString() ?? '',
      suggestedFocusAreas: _parseStringList(s['suggested_focus_areas']),
      source: json['source']?.toString() ?? 'offline_template',
      language: json['language']?.toString() ?? 'english',
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
      'patient_id': patientId,
      'doctor_id': doctorId,
      'brief_text': briefText,
      'structured_data': {
        'chief_complaint': chiefComplaint,
        'symptom_timeline': symptomTimeline,
        'risk_factors': riskFactors,
        'relevant_history': relevantHistory,
        'current_medications_summary': currentMedicationsSummary,
        'allergies_and_contraindications': allergiesAndContraindications,
        'ai_triage_assessment': aiTriageAssessment,
        'suggested_focus_areas': suggestedFocusAreas,
      },
      'source': source,
      'language': language,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
