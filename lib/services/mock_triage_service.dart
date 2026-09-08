import 'dart:math';
import '../models/triage_model.dart';
import '../core/widgets/risk_indicator_badge.dart';

class MockTriageService {
  static TriageModel analyzeSymptoms(String symptomText) {
    final lower = symptomText.toLowerCase();

    // High Risk Trigger Keywords
    // Mirrors the backend GeminiService::applyEmergencySafetyNet red-flag
    // list so the client-side deterministic rule never under-triggers when
    // the server/AI is unreachable. This list may only ESCALATE risk.
    final highRiskKeywords = [
      // English
      'chest pain',
      'heart attack',
      'difficulty breathing',
      'shortness of breath',
      'snake bite',
      'poison',
      'unconscious',
      'paralysis',
      'severe head injury',
      'bleeding',
      'severe bleeding',
      'convulsion',
      'stroke',
      'cyanosis',
      // Roman Urdu
      'seene mein dard',
      'seene me dard',
      'dil ka daura',
      'sans lene mein dushwari',
      'saans nahi aa rahi',
      'khoon nikal raha hai',
      'saanp ne kata',
      'saanp ka katna',
      'zehar',
      'zehr',
      'behoshi',
      'behosh',
      'falij',
      'lakwa',
      'sar par chot',
      'sar par shadeed chot',
      'jhatke',
      'mirgi',
      'hont neelay',
      // Urdu script
      'سینے میں درد',
      'سانس لینے میں دشواری',
      'سانس نہیں آ رہی',
      'سانپ',
      'زہر',
      'بے ہوش',
      'بےہوش',
      'فالج',
      'لکوا',
      'دورے',
      'مرگی',
      'شدید خون',
      'سر پر چوٹ',
      'جھٹکے',
    ];

    // Moderate Risk Trigger Keywords
    final moderateRiskKeywords = [
      'fever',
      'bukhar',
      'vomiting',
      'ulti',
      'stomach pain',
      'pait mein dard',
      'infection',
      'cough',
      'khansi',
      'throat pain',
      'gala kharab',
      'diarrhea',
      'dast',
      'loose motion',
      'dizziness',
      'chakkar',
      'cut',
      'wound',
    ];

    bool isHighRisk = highRiskKeywords.any((kw) => lower.contains(kw));
    bool isModerateRisk = moderateRiskKeywords.any((kw) => lower.contains(kw));

    if (isHighRisk) {
      return TriageModel(
        id: 'triage_${DateTime.now().millisecondsSinceEpoch}',
        riskLevel: TriageRiskLevel.high,
        primaryComplaint: symptomText.trim().isEmpty
            ? 'Acute Critical Symptom Alert'
            : symptomText,
        detectedSymptoms: [
          'Potential acute cardiopulmonary or trauma indicator',
          'High acuity clinical warning signs',
          'Requires immediate in-person or rapid stabilization triage',
        ],
        generalGuidance:
            'This situation warrants urgent clinical attention. Do not attempt unverified home remedies or self-medicate.',
        nextSteps:
            'Immediate emergency evaluation required. Prepare to visit the nearest emergency department or call 1122.',
        emergencyAction:
            'Connect with emergency on-call physician or initiate Rescue 1122 ambulance dispatch.',
        timestamp: DateTime.now(),
        requiresImmediateDoctor: true,
      );
    } else if (isModerateRisk) {
      return TriageModel(
        id: 'triage_${DateTime.now().millisecondsSinceEpoch}',
        riskLevel: TriageRiskLevel.moderate,
        primaryComplaint: symptomText.trim().isEmpty
            ? 'Persistent Moderate Health Concern'
            : symptomText,
        detectedSymptoms: [
          'Moderate systemic symptoms detected',
          'Potential bacterial or viral illness requiring clinical monitoring',
          'Secondary symptoms warranting teleconsultation',
        ],
        generalGuidance:
            'Monitor vital signs (temperature, hydration, pulse). Keep yourself rested and avoid strenuous physical tasks.',
        nextSteps:
            'Schedule a consultation with a certified doctor within 24 hours for differential evaluation and prescription.',
        emergencyAction:
            'If symptoms suddenly worsen or respiratory distress occurs, escalate immediately to High Risk emergency triage.',
        timestamp: DateTime.now(),
        requiresImmediateDoctor: false,
      );
    } else {
      return TriageModel(
        id: 'triage_${DateTime.now().millisecondsSinceEpoch}',
        riskLevel: TriageRiskLevel.low,
        primaryComplaint: symptomText.trim().isEmpty
            ? 'Mild Symptom Assessment'
            : symptomText,
        detectedSymptoms: [
          'Mild self-limiting discomfort',
          'No acute red-flag emergency symptoms identified',
        ],
        generalGuidance:
            'Maintain good hydration, balanced nutrition, and adequate sleep. Observe symptoms over the next 48 hours.',
        nextSteps:
            'Self-care and OTC symptomatic management. If symptoms persist beyond 3-5 days, book an online doctor appointment.',
        emergencyAction:
            'Routine monitoring. No immediate emergency intervention indicated.',
        timestamp: DateTime.now(),
        requiresImmediateDoctor: false,
      );
    }
  }

  static TriageModel getMockTriageByRisk(TriageRiskLevel level) {
    switch (level) {
      case TriageRiskLevel.high:
        return TriageModel(
          id: 'tr_high_${Random().nextInt(999)}',
          riskLevel: TriageRiskLevel.high,
          primaryComplaint: 'Severe acute crushing chest pain with cold sweats',
          detectedSymptoms: [
            'Crushing retrosternal chest pain',
            'Radiation to left arm and jaw',
            'Diaphoresis (Cold Sweats)',
            'Shortness of breath',
          ],
          generalGuidance:
              'Potential acute coronary syndrome or myocardial ischemia. DO NOT DRIVE YOURSELF.',
          nextSteps:
              'Immediate transport to the nearest tertiary care / cardiac emergency facility (e.g. NICVD / Civil / DHQ Hospital).',
          emergencyAction:
              'Call Rescue 1122 immediately. Keep patient seated and reassure calmly.',
          timestamp: DateTime.now(),
          requiresImmediateDoctor: true,
        );
      case TriageRiskLevel.moderate:
        return TriageModel(
          id: 'tr_mod_${Random().nextInt(999)}',
          riskLevel: TriageRiskLevel.moderate,
          primaryComplaint: 'High fever (102.5°F), chills, body aches and retro-orbital headache',
          detectedSymptoms: [
            'High continuous fever > 102°F',
            'Retro-orbital headache (pain behind eyes)',
            'Severe myalgia (body pain)',
            'Mild dehydration',
          ],
          generalGuidance:
              'Potential Dengue or Malaria viral illness prevalent in regional climates. Maintain strict fluid intake (ORS, water, juices).',
          nextSteps:
              'Consult a tele-physician for CBC & Dengue NS1 / Malarial Parasite lab test orders.',
          emergencyAction:
              'Watch for warning signs: bleeding from gums, persistent vomiting, black stools.',
          timestamp: DateTime.now(),
          requiresImmediateDoctor: false,
        );
      case TriageRiskLevel.low:
        return TriageModel(
          id: 'tr_low_${Random().nextInt(999)}',
          riskLevel: TriageRiskLevel.low,
          primaryComplaint: 'Mild seasonal sneezing, runny nose and slight scratchy throat',
          detectedSymptoms: [
            'Mild nasal congestion',
            'Clear rhinorrhea',
            'Occasional dry sneeze',
            'Normal body temperature (98.6°F)',
          ],
          generalGuidance:
              'Typical mild upper respiratory allergic/viral rhinitis. Steam inhalation and warm green tea recommended.',
          nextSteps:
              'Rest and hydration. Antihistamine may be used if recommended by a healthcare provider.',
          emergencyAction:
              'No emergency action required.',
          timestamp: DateTime.now(),
          requiresImmediateDoctor: false,
        );
    }
  }
}
