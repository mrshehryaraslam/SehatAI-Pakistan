import '../core/widgets/risk_indicator_badge.dart';

class TriageModel {
  final String id;
  final TriageRiskLevel riskLevel;
  final String primaryComplaint;
  final List<String> detectedSymptoms;
  final String generalGuidance;
  final String nextSteps;
  final String emergencyAction;
  final DateTime timestamp;
  final bool requiresImmediateDoctor;

  const TriageModel({
    required this.id,
    required this.riskLevel,
    required this.primaryComplaint,
    required this.detectedSymptoms,
    required this.generalGuidance,
    required this.nextSteps,
    required this.emergencyAction,
    required this.timestamp,
    this.requiresImmediateDoctor = false,
  });
}
