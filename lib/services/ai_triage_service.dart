import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';
import '../core/widgets/language_selector.dart';
import '../core/widgets/risk_indicator_badge.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'mock_triage_service.dart';

class AiTriageResult {
  final String reply;
  final List<String> detectedSymptoms;
  final TriageRiskLevel riskLevel;
  final bool requiresDoctor;
  final String? emergencyWarning;
  final String disclaimer;
  final String sessionId;
  final List<String> quickActions;
  final String source;

  const AiTriageResult({
    required this.reply,
    required this.detectedSymptoms,
    required this.riskLevel,
    required this.requiresDoctor,
    this.emergencyWarning,
    required this.disclaimer,
    required this.sessionId,
    required this.quickActions,
    this.source = 'gemini_api',
  });

  factory AiTriageResult.fromJson(Map<String, dynamic> json, {String defaultSessionId = ''}) {
    final riskStr = (json['risk_level'] ?? 'low').toString().toLowerCase();
    TriageRiskLevel risk = TriageRiskLevel.low;
    if (riskStr == 'high') {
      risk = TriageRiskLevel.high;
    } else if (riskStr == 'moderate') {
      risk = TriageRiskLevel.moderate;
    }

    final symptomsRaw = json['detected_symptoms'];
    List<String> symptoms = [];
    if (symptomsRaw is List) {
      symptoms = symptomsRaw.map((e) => e.toString()).toList();
    } else if (symptomsRaw is String && symptomsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(symptomsRaw);
        if (decoded is List) {
          symptoms = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        symptoms = [symptomsRaw];
      }
    }

    final requiresDoc = json['requires_doctor'] == true ||
        json['requires_doctor'] == 1 ||
        json['requires_doctor'] == '1' ||
        risk != TriageRiskLevel.low;

    final warning = json['emergency_warning']?.toString();

    // Default contextual action chips
    List<String> actions = [];
    if (risk == TriageRiskLevel.high) {
      actions = ['SOS: Open Emergency Triage', 'Connect Emergency Doctor', 'Call 1122'];
    } else if (risk == TriageRiskLevel.moderate) {
      actions = ['Find & Consult Doctor', 'View Home Care Guidance', 'Check Symptoms Again'];
    } else {
      actions = ['Find Doctor', 'General Wellness Tips', 'Check Another Symptom'];
    }

    return AiTriageResult(
      reply: json['reply']?.toString() ?? 'Triage analysis completed.',
      detectedSymptoms: symptoms,
      riskLevel: risk,
      requiresDoctor: requiresDoc,
      emergencyWarning: (warning != null && warning.isNotEmpty) ? warning : null,
      disclaimer: json['disclaimer']?.toString() ??
          'Preliminary medical triage guidance only. Not a definitive medical diagnosis. For emergencies, contact 1122.',
      sessionId: json['session_id']?.toString() ?? defaultSessionId,
      quickActions: actions,
      source: json['_source']?.toString() ?? 'gemini_api',
    );
  }
}

class AiTriageService {
  static final AiTriageService _instance = AiTriageService._internal();
  factory AiTriageService() => _instance;
  AiTriageService._internal();

  final ApiService _api = ApiService();

  /// Sends user message to PHP /api/ai/triage with conversation context and profile info.
  /// Falls back smoothly to offline rule-based triage if network or server is unreachable.
  Future<AiTriageResult> analyzeSymptoms({
    required String message,
    AppLanguage language = AppLanguage.romanUrdu,
    String? sessionId,
    List<Map<String, String>>? history,
    UserModel? patientProfile,
  }) async {
    final langKey = _mapLanguageToKey(language);
    final effectiveSessionId = sessionId ?? 'sess_${DateTime.now().millisecondsSinceEpoch}';

    final body = <String, dynamic>{
      'message': message,
      'session_id': effectiveSessionId,
      'language': langKey,
    };

    if (history != null && history.isNotEmpty) {
      body['conversation_history'] = history;
    }

    if (patientProfile != null) {
      body['patient_profile'] = {
        'age': patientProfile.age,
        'gender': patientProfile.gender,
        'allergies': patientProfile.allergies,
        'chronic_conditions': patientProfile.chronicConditions,
        'city': patientProfile.city,
      };
    }

    try {
      final response = await _api.post(
        ApiEndpoints.aiTriage,
        body,
        authRequired: true,
        timeout: const Duration(seconds: 30),
      );

      if (response.isSuccess && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('[AiTriageService] Live AI triage received successfully from backend.');
        return AiTriageResult.fromJson(data, defaultSessionId: effectiveSessionId);
      } else {
        debugPrint('[AiTriageService] Backend returned error: ${response.message}. Using offline fallback.');
      }
    } catch (e) {
      debugPrint('[AiTriageService] Network/exception occurred: $e. Using offline fallback.');
    }

    // Offline Rule-Based Fallback
    return _generateOfflineFallback(message, language, effectiveSessionId);
  }

  String _mapLanguageToKey(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.urdu:
        return 'urdu';
      case AppLanguage.romanUrdu:
        return 'roman_urdu';
      case AppLanguage.english:
        return 'english';
    }
  }

  /// Offline rule-based fallback if offline or network drops.
  AiTriageResult _generateOfflineFallback(
    String message,
    AppLanguage language,
    String sessionId,
  ) {
    final mockTriage = MockTriageService.analyzeSymptoms(message);
    final isHigh = mockTriage.riskLevel == TriageRiskLevel.high;
    final isModerate = mockTriage.riskLevel == TriageRiskLevel.moderate;

    String reply;
    String disclaimer;
    String? warning;
    List<String> actions;

    if (isHigh) {
      actions = ['SOS: Open Emergency Triage', 'Connect Emergency Doctor', 'Call 1122'];
      if (language == AppLanguage.urdu) {
        reply = '🚨 **ہنگامی الرٹ (High Risk Alert)**\n\n'
            'آپ کی علامات فوری ہنگامی طبی توجہ کی متقاضی ہیں۔\n\n'
            '• فوری ریسکیو 1122 پر کال کریں یا قریبی ایمرجنسی وارڈ تشریف لے جائیں۔\n'
            '• پرسکون رہیں اور مریض کو اکیلا نہ چھوڑیں۔';
        warning = 'فوری ایمرجنسی امداد کی ضرورت ہے۔ 1122 پر کال کریں۔';
        disclaimer = 'ابتدائی رہنمائی ہے۔ حتمی تشخیص نہیں۔ ایمرجنسی میں 1122 کال کریں۔';
      } else if (language == AppLanguage.romanUrdu) {
        reply = '🚨 **HIGH-RISK WARNING DETECTED**\n\n'
            'Ye alamaat potential critical emergency ki nishandahi karti hain.\n\n'
            '• Foran Rescue 1122 par call karein ya qareebi hospital emergency jayein.\n'
            '• Khud se koi dawai na lein aur pursukoon rahein.\n\n'
            'Kiya aap Emergency SOS trigger karna chahte hain?';
        warning = 'Immediate emergency evaluation required. Call 1122.';
        disclaimer = 'Ibtidai triage guidance hai, hatmi diagnosis nahi. Emergency mein 1122 rabta karein.';
      } else {
        reply = '🚨 **HIGH-RISK WARNING DETECTED**\n\n'
            'These symptoms require **immediate emergency care**.\n\n'
            '• Contact Rescue 1122 or go to the nearest emergency department immediately.\n'
            '• Do not exert yourself and stay accompanied.\n\n'
            'Would you like to trigger Emergency SOS or connect directly with an emergency doctor?';
        warning = 'Critical emergency signs detected. Call 1122.';
        disclaimer = 'Preliminary triage guidance only. Not a definitive diagnosis. In emergency, call 1122.';
      }
    } else if (isModerate) {
      actions = ['Find & Consult Doctor', 'View Home Care Guidance', 'Check Symptoms Again'];
      if (language == AppLanguage.urdu) {
        reply = '⚠️ **معتدل خطرے کا جائزہ (Moderate Assessment)**\n\n'
            'آپ کی بیان کردہ علامات کے مطابق:\n\n'
            '• مناسب پانی اور او آر ایس کا استعمال کریں۔\n'
            '• ہر 4 سے 6 گھنٹے بعد بخار چیک کریں۔\n'
            '• 24 گھنٹے میں پی ایم ڈی سی تصدیق شدہ ڈاکٹر سے مشاورت تجویز کی جاتی ہے۔';
        disclaimer = 'ابتدائی رہنمائی۔ حتمی تشخیص کے لیے ڈاکٹر سے رجوع کریں۔';
      } else if (language == AppLanguage.romanUrdu) {
        reply = '⚠️ **Moderate Health Assessment**\n\n'
            'Aap ki reported symptoms ("$message") ke mutabiq:\n\n'
            '• Hydration ka sakhti se khayal rakhein (ubla hua paani, ORS, soups).\n'
            '• Har 4-6 ghante baad temperature monitor karein.\n'
            '• 24 ghante ke andar PMDC registered doctor se mashwara karein.';
        disclaimer = 'Ibtidai medical triage hai. Behtar rehnumai ke liye doctor se rabta karein.';
      } else {
        reply = '⚠️ **Moderate Health Assessment**\n\n'
            'Based on your reported symptoms ("$message"):\n\n'
            '• Maintain strict hydration (boiled water, ORS, warm fluids).\n'
            '• Monitor your body temperature every 4-6 hours.\n'
            '• A teleconsultation with a PMDC registered doctor is recommended within 24 hours.';
        disclaimer = 'Preliminary triage guidance only. Consult a registered physician.';
      }
    } else {
      actions = ['Find Doctor', 'General Wellness Tips', 'Check Another Symptom'];
      if (language == AppLanguage.urdu) {
        reply = '✅ **عمومی رہنمائی (Low Risk)**\n\n'
            'علامات بظاہر معمولی معلوم ہوتی ہیں:\n\n'
            '• مناسب آرام کریں اور زیادہ پانی پیئیں۔\n'
            '• اگلے 48 گھنٹے تک علامات پر نظر رکھیں۔';
        disclaimer = 'عمومی معلوماتی رہنمائی۔';
      } else if (language == AppLanguage.romanUrdu) {
        reply = '✅ **Low Risk / General Guidance**\n\n'
            'Aap ki batayi gayi alamaat mamooli maloom hoti hain:\n\n'
            '• Mukammal rest karein aur paani zyada piyein.\n'
            '• Agle 48 ghante tak tabiyat observe karein.\n'
            '• Agar takleef 3-5 din tak rahe to doctor se mashwara karein.';
        disclaimer = 'Ibtidai medical guidance. Hatmi diagnosis nahi.';
      } else {
        reply = '✅ **Low Risk / General Guidance**\n\n'
            'The symptoms you described appear to be mild and self-limiting:\n\n'
            '• Get adequate rest and drink plenty of fluids.\n'
            '• Observe symptoms for the next 48 hours.\n'
            '• If symptoms persist beyond 3-5 days, please consult a physician.';
        disclaimer = 'General wellness guidance. Not a definitive diagnosis.';
      }
    }

    return AiTriageResult(
      reply: reply,
      detectedSymptoms: mockTriage.detectedSymptoms,
      riskLevel: mockTriage.riskLevel,
      requiresDoctor: mockTriage.requiresImmediateDoctor || isModerate,
      emergencyWarning: warning,
      disclaimer: disclaimer,
      sessionId: sessionId,
      quickActions: actions,
      source: 'offline_rule_fallback',
    );
  }
}
