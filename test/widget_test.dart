// Placeholder smoke test — SehatAI Pakistan app entry point test
// Note: Full widget tests are in ai_triage_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_ai_pakistan/services/mock_triage_service.dart';
import 'package:sehat_ai_pakistan/core/widgets/risk_indicator_badge.dart';

void main() {
  test('MockTriageService analyzeSymptoms returns a valid TriageModel', () {
    final result = MockTriageService.analyzeSymptoms('chest pain');
    expect(result.riskLevel, TriageRiskLevel.high);
    expect(result.id, isNotEmpty);
    expect(result.detectedSymptoms, isNotEmpty);
    expect(result.requiresImmediateDoctor, isTrue);
  });
}
