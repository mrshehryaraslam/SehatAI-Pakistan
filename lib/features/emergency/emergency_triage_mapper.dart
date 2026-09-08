import '../../core/widgets/risk_indicator_badge.dart';
import '../../models/triage_model.dart';
import '../../services/ai_triage_service.dart';
import '../../services/mock_triage_service.dart';

/// Maps a live AI triage result to the [TriageModel] used by the emergency UI.
///
/// CRITICAL SAFETY RULE (deterministic, AI-independent):
/// The offline keyword rule engine is evaluated on the raw symptom text and
/// may only ever ESCALATE risk — when critical red-flag symptoms are detected
/// (chest pain, breathing difficulty, snake bite, unconsciousness, severe
/// bleeding, …) the result is forced to HIGH regardless of what the AI
/// returned. The AI can never downgrade a critical emergency, even when the
/// model, the network or the Gemini quota misbehaves.
TriageModel triageModelFromAiResult(
  AiTriageResult result, {
  required String symptomText,
}) {
  // Deterministic keyword safety net — independent of the AI verdict.
  final deterministic = MockTriageService.analyzeSymptoms(symptomText);
  final bool criticalSymptoms =
      deterministic.riskLevel == TriageRiskLevel.high;

  final riskLevel =
      criticalSymptoms ? TriageRiskLevel.high : result.riskLevel;
  final bool requiresImmediateDoctor = criticalSymptoms ||
      result.requiresDoctor ||
      riskLevel == TriageRiskLevel.high;

  final String? emergencyWarning =
      (result.emergencyWarning != null && result.emergencyWarning!.isNotEmpty)
          ? result.emergencyWarning
          : (criticalSymptoms ? deterministic.emergencyAction : null);

  return TriageModel(
    id: result.sessionId,
    riskLevel: riskLevel,
    primaryComplaint: symptomText,
    detectedSymptoms: result.detectedSymptoms.isNotEmpty
        ? result.detectedSymptoms
        : deterministic.detectedSymptoms,
    generalGuidance: result.reply,
    nextSteps: emergencyWarning ?? deterministic.nextSteps,
    emergencyAction: emergencyWarning ?? deterministic.emergencyAction,
    timestamp: DateTime.now(),
    requiresImmediateDoctor: requiresImmediateDoctor,
  );
}
