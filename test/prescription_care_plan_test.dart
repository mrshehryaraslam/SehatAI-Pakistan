import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_ai_pakistan/core/constants/api_endpoints.dart';
import 'package:sehat_ai_pakistan/features/health_continuity/widgets/care_plan_card.dart';
import 'package:sehat_ai_pakistan/models/care_plan_model.dart';
import 'package:sehat_ai_pakistan/models/patient_brief_model.dart';
import 'package:sehat_ai_pakistan/models/prescription_model.dart';
import 'package:sehat_ai_pakistan/services/health_continuity_service.dart';
import 'package:sehat_ai_pakistan/services/prescription_service.dart';

/// Phase 5: Prescription + AI Care Plan — focused tests.
///
/// Verifies that:
///   1. Real backend payloads parse correctly into CarePlanModel /
///      PatientBriefModel / PrescriptionModel (medicine, dosage, frequency,
///      duration all preserved).
///   2. HealthContinuityService never fabricates demo care plans/briefs:
///      generation failure returns null and clears cached state.
///   3. PrescriptionService.createPrescription sends the real consultation,
///      patient, and medicine payload to the API.
///   4. The AiCarePlanCard UI renders a real Gemini care plan unchanged
///      (source badge, medication guidance, emergency warning signs).
///
/// A local HTTP server stands in for the PHP API so every scenario can be
/// tested deterministically.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HttpServer server;
  late String baseUrl;
  Future<void> Function(HttpRequest request)? handler;

  /// Every request received by the test server, in order:
  /// {'method': String, 'uri': String, 'body': Map<String, dynamic>?}
  final List<Map<String, dynamic>> requestLog = [];

  Future<void> respond(HttpRequest request, int code, Map<String, dynamic> body) async {
    request.response.statusCode = code;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
    await request.response.close();
  }

  Map<String, dynamic> ok(dynamic data) => {
        'status': 'success',
        'message': 'Retrieved.',
        'data': data,
      };

  Map<String, dynamic> fail(int code, String message) => {
        'status': 'error',
        'message': message,
      };

  /// A care plan payload exactly as the PHP backend returns it for a real
  /// Gemini-generated plan tied to a completed consultation + prescription.
  final Map<String, dynamic> realCarePlanJson = {
    'id': 11,
    'consultation_id': 24,
    'prescription_id': 9,
    'patient_id': 42,
    'doctor_id': 2,
    'care_plan_text':
        'Recovery plan for viral upper respiratory infection. Continue the prescribed medicines, monitor your temperature, and rest.',
    'structured_data': {
      'medication_guidance': [
        {
          'medicine': 'Tab. Panadol (Paracetamol) 500mg',
          'how_to_take': '1 Tablet every 6 hours after meals with water (max 4/day) for 5 days.',
          'side_effects_watch': 'Stop and call your doctor if you develop a rash.',
        },
        {
          'medicine': 'Cap. Risek (Omeprazole) 20mg',
          'how_to_take': '1 Capsule once daily before breakfast on an empty stomach for 7 days.',
          'side_effects_watch': 'Report persistent diarrhea or severe stomach pain.',
        },
      ],
      'warning_signs': [
        'Call Rescue 1122 immediately if you have difficulty breathing or chest pain.',
        'Return to the clinic if fever persists beyond 3 more days.',
      ],
      'lifestyle_recommendations': [
        'Drink at least 8 glasses of fluids daily.',
        'Rest and avoid strenuous activity for one week.',
      ],
      'home_monitoring': [
        'Check and record your temperature twice daily.',
      ],
    },
    'follow_up_date': '2026-09-12',
    'language': 'english',
    'source': 'google_gemini_api',
    'patient_name': 'Ahmed Khan',
    'doctor_name': 'Dr. Ayesha Siddiqui',
    'doctor_specialty': 'Cardiology / Emergency Medicine',
    'created_at': '2026-09-04 12:30:00',
  };

  /// A patient brief payload exactly as the PHP backend returns it.
  final Map<String, dynamic> realBriefJson = {
    'id': 7,
    'consultation_id': 24,
    'patient_id': 42,
    'doctor_id': 2,
    'brief_text': 'Clinical summary for Ahmed Khan ahead of the consultation.',
    'structured_data': {
      'chief_complaint': 'Persistent dry cough and fever for 4 days with body aches.',
      'symptom_timeline': 'Symptoms began 4 days ago, gradually worsening.',
      'risk_factors': ['Moderate triage risk level'],
      'relevant_history': 'No chronic conditions on record.',
      'current_medications_summary': 'No active medicines.',
      'allergies_and_contraindications': 'No known allergies.',
      'ai_triage_assessment': 'Moderate risk — in-person consultation advised.',
      'suggested_focus_areas': ['Auscultate lungs', 'Check for dehydration'],
    },
    'language': 'english',
    'source': 'google_gemini_api',
    'created_at': '2026-09-04 11:45:00',
  };

  /// A prescription payload exactly as the PHP backend returns it after a
  /// doctor issues it against a real consultation.
  final Map<String, dynamic> realPrescriptionJson = {
    'id': 9,
    'consultation_id': 24,
    'patient_id': 42,
    'doctor_id': 2,
    'doctor_name': 'Dr. Ayesha Siddiqui',
    'doctor_specialty': 'Cardiology / Emergency Medicine',
    'is_verified': true,
    'created_at': '2026-09-04 12:00:00',
    'medicines': [
      {
        'id': 18,
        'medicine_name': 'Tab. Panadol (Paracetamol) 500mg',
        'dosage': '1 Tablet',
        'frequency': 'Every 6 hours (max 4/day)',
        'duration': '5 days',
        'instructions': 'After meals with water',
      },
    ],
  };

  setUpAll(() async {
    // flutter_test installs a global HttpOverrides whose client answers every
    // request with an empty 400 response. Restore the real HttpClient so the
    // requests below actually reach the local test server.
    HttpOverrides.global = null;

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://${server.address.address}:${server.port}';
    ApiEndpoints.setCustomBaseUrl(baseUrl);

    server.listen((request) async {
      final raw = await utf8.decoder.bind(request).join();
      Map<String, dynamic>? body;
      if (raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) body = decoded;
        } catch (_) {}
      }
      requestLog.add({
        'method': request.method,
        'uri': request.uri.toString(),
        'body': body,
      });

      final h = handler;
      if (h != null) {
        await h(request);
      } else {
        await respond(request, 500, fail(500, 'No handler configured.'));
      }
    });
  });

  tearDownAll(() async {
    await server.close(force: true);
  });

  setUp(() {
    requestLog.clear();
    handler = null;
  });

  Map<String, dynamic>? requestEntry(String method, String path) {
    for (final entry in requestLog) {
      if (entry['method'] == method && (entry['uri'] as String).contains(path)) {
        return entry;
      }
    }
    return null;
  }

  // ================================================================
  // CarePlanModel — real backend payload parsing
  // ================================================================
  group('CarePlanModel — real Gemini care plan parsing', () {
    test('parses a real care plan payload (structured_data already decoded)', () {
      final plan = CarePlanModel.fromJson(realCarePlanJson);

      expect(plan.id, '11');
      expect(plan.consultationId, '24');
      expect(plan.prescriptionId, '9');
      expect(plan.patientId, 42);
      expect(plan.doctorId, 2);
      expect(plan.source, 'google_gemini_api');
      expect(plan.language, 'english');
      expect(plan.carePlanText, isNotEmpty);
      expect(plan.patientName, 'Ahmed Khan');
      expect(plan.doctorName, 'Dr. Ayesha Siddiqui');
      expect(plan.doctorSpecialty, 'Cardiology / Emergency Medicine');

      // Medication guidance must carry the actually prescribed medicines.
      expect(plan.medicineGuidance.length, 2);
      expect(plan.medicineGuidance[0].medicineName, 'Tab. Panadol (Paracetamol) 500mg');
      expect(
        plan.medicineGuidance[0].howToTake,
        contains('every 6 hours'),
      );
      expect(plan.medicineGuidance[1].medicineName, 'Cap. Risek (Omeprazole) 20mg');

      // Emergency warning signs must include the Rescue 1122 guidance.
      expect(plan.warningSigns, isNotEmpty);
      expect(plan.warningSigns.any((s) => s.contains('1122')), isTrue);
      expect(plan.lifestyleRecommendations, isNotEmpty);
      expect(plan.homeMonitoring, isNotEmpty);

      expect(plan.followUpDate, isNotNull);
      expect(plan.daysUntilFollowUp, isNotNull);
      expect(plan.daysUntilFollowUp, greaterThanOrEqualTo(0));
    });

    test('parses structured_data when it arrives as a JSON string (raw DB form)', () {
      final raw = Map<String, dynamic>.from(realCarePlanJson);
      raw['structured_data'] = jsonEncode(realCarePlanJson['structured_data']);

      final plan = CarePlanModel.fromJson(raw);

      expect(plan.source, 'google_gemini_api');
      expect(plan.medicineGuidance.length, 2);
      expect(plan.medicineGuidance[0].medicineName, 'Tab. Panadol (Paracetamol) 500mg');
      expect(plan.warningSigns.any((s) => s.contains('1122')), isTrue);
    });

    test('past follow-up date yields null daysUntilFollowUp, never negative', () {
      final raw = Map<String, dynamic>.from(realCarePlanJson);
      raw['follow_up_date'] = '2020-01-01';

      expect(CarePlanModel.fromJson(raw).daysUntilFollowUp, isNull);
    });
  });

  // ================================================================
  // PatientBriefModel — real backend payload parsing
  // ================================================================
  group('PatientBriefModel — real Gemini brief parsing', () {
    test('parses a real patient brief payload with structured clinical data', () {
      final brief = PatientBriefModel.fromJson(realBriefJson);

      expect(brief.id, '7');
      expect(brief.consultationId, '24');
      expect(brief.patientId, 42);
      expect(brief.doctorId, 2);
      expect(brief.source, 'google_gemini_api');
      expect(brief.chiefComplaint, contains('dry cough'));
      expect(brief.riskFactors, isNotEmpty);
      expect(brief.aiTriageAssessment, contains('Moderate risk'));
      expect(brief.suggestedFocusAreas, isNotEmpty);
      expect(brief.allergiesAndContraindications, isNotEmpty);
    });

    test('parses structured_data when it arrives as a JSON string', () {
      final raw = Map<String, dynamic>.from(realBriefJson);
      raw['structured_data'] = jsonEncode(realBriefJson['structured_data']);

      final brief = PatientBriefModel.fromJson(raw);

      expect(brief.source, 'google_gemini_api');
      expect(brief.chiefComplaint, contains('dry cough'));
    });
  });

  // ================================================================
  // PrescriptionModel — real backend payload parsing
  // ================================================================
  group('PrescriptionModel — real prescription parsing', () {
    test('preserves medicine, dosage, frequency, and duration from the API', () {
      final rx = PrescriptionModel.fromJson(realPrescriptionJson);

      expect(rx.id, '9');
      expect(rx.doctorName, 'Dr. Ayesha Siddiqui');
      expect(rx.doctorSpecialty, 'Cardiology / Emergency Medicine');
      expect(rx.isVerifiedByUser, isTrue);

      expect(rx.items.length, 1);
      final item = rx.items.first;
      expect(item.medicineName, 'Tab. Panadol (Paracetamol) 500mg');
      expect(item.dosage, '1 Tablet');
      expect(item.frequency, 'Every 6 hours (max 4/day)');
      expect(item.duration, '5 days');
      expect(item.instructions, 'After meals with water');
    });

    test('toJson round-trips every medicine field for submission', () {
      const item = PrescriptionItem(
        medicineName: 'Cap. Risek (Omeprazole) 20mg',
        dosage: '1 Capsule',
        frequency: 'Once daily before breakfast',
        duration: '7 days',
        instructions: 'Empty stomach',
      );

      final json = item.toJson();

      expect(json['medicine_name'], 'Cap. Risek (Omeprazole) 20mg');
      expect(json['dosage'], '1 Capsule');
      expect(json['frequency'], 'Once daily before breakfast');
      expect(json['duration'], '7 days');
      expect(json['instructions'], 'Empty stomach');
    });
  });

  // ================================================================
  // HealthContinuityService — real API only, no demo fallback
  // ================================================================
  group('HealthContinuityService — real API data only', () {
    test('fetchCarePlan returns the real care plan from the API', () async {
      handler = (req) async {
        await respond(req, 200, ok(realCarePlanJson));
      };

      final plan = await HealthContinuityService().fetchCarePlan(24);

      expect(plan, isNotNull);
      expect(plan!.source, 'google_gemini_api');
      expect(plan.medicineGuidance[0].medicineName, 'Tab. Panadol (Paracetamol) 500mg');
      expect(HealthContinuityService().isCarePlanLoading, isFalse);
      // The service must query the per-consultation endpoint.
      expect(requestEntry('GET', '/ai/care-plan/24'), isNotNull);
    });

    test('fetchCarePlan returns null when no plan exists (404), never fabricates one', () async {
      handler = (req) async {
        await respond(req, 404, fail(404, 'No care plan found for this consultation.'));
      };

      final plan = await HealthContinuityService().fetchCarePlan(999);

      expect(plan, isNull);
      expect(HealthContinuityService().isCarePlanLoading, isFalse);
    });

    test('generatePatientBrief returns the real brief on API success', () async {
      handler = (req) async {
        await respond(req, 201, {
          'status': 'success',
          'message': 'AI Patient Brief generated.',
          'data': realBriefJson,
        });
      };

      final brief = await HealthContinuityService().generatePatientBrief(24);

      expect(brief, isNotNull);
      expect(brief!.source, 'google_gemini_api');
      expect(HealthContinuityService().currentBrief, isNotNull);
      expect(HealthContinuityService().currentBrief!.chiefComplaint, contains('dry cough'));

      // The generation request must carry the consultation id + language.
      final entry = requestEntry('POST', '/ai/patient-brief');
      expect(entry, isNotNull);
      expect(entry!['body']['consultation_id'], 24);
      expect(entry['body']['language'], 'english');
    });

    test('generatePatientBrief returns null on failure and never fabricates a demo brief', () async {
      handler = (req) async {
        await respond(req, 500, fail(500, 'Internal Server Error'));
      };

      final brief = await HealthContinuityService().generatePatientBrief(24);

      expect(brief, isNull);
      // Critical Phase 5 regression check: the old implementation fell back to
      // a hardcoded mock brief here. It must now clear the cached state.
      expect(HealthContinuityService().currentBrief, isNull);
      expect(HealthContinuityService().isBriefLoading, isFalse);
    });

    test('generateCarePlan returns the real plan on API success', () async {
      handler = (req) async {
        await respond(req, 201, {
          'status': 'success',
          'message': 'AI Care Plan generated.',
          'data': realCarePlanJson,
        });
      };

      final plan = await HealthContinuityService().generateCarePlan(24);

      expect(plan, isNotNull);
      expect(plan!.source, 'google_gemini_api');
      expect(HealthContinuityService().currentCarePlan, isNotNull);

      final entry = requestEntry('POST', '/ai/care-plan');
      expect(entry, isNotNull);
      expect(entry!['body']['consultation_id'], 24);
    });

    test('generateCarePlan returns null on failure and never fabricates a demo plan', () async {
      handler = (req) async {
        await respond(req, 500, fail(500, 'Internal Server Error'));
      };

      final plan = await HealthContinuityService().generateCarePlan(24);

      expect(plan, isNull);
      // Critical Phase 5 regression check: the old implementation fell back to
      // a hardcoded mock care plan here. It must now clear the cached state.
      expect(HealthContinuityService().currentCarePlan, isNull);
      expect(HealthContinuityService().isCarePlanLoading, isFalse);
    });
  });

  // ================================================================
  // PrescriptionService — real prescription creation flow
  // ================================================================
  group('PrescriptionService — real prescription creation', () {
    test('createPrescription sends patient, consultation, and full medicine payload', () async {
      handler = (req) async {
        if (req.method == 'POST' && req.uri.path == '/prescriptions') {
          await respond(req, 201, {
            'status': 'success',
            'message': 'Prescription created successfully.',
            'data': realPrescriptionJson,
          });
        } else {
          await respond(req, 200, ok([realPrescriptionJson]));
        }
      };

      final success = await PrescriptionService().createPrescription(
        patientId: 42,
        consultationId: 24,
        medicines: [
          const PrescriptionItem(
            medicineName: 'Tab. Panadol (Paracetamol) 500mg',
            dosage: '1 Tablet',
            frequency: 'Every 6 hours (max 4/day)',
            duration: '5 days',
            instructions: 'After meals with water',
          ),
        ],
      );

      expect(success, isTrue);

      // The POST body must carry the real DB identifiers and every field
      // the backend persists: medicine, dosage, frequency, duration.
      final entry = requestEntry('POST', '/prescriptions');
      expect(entry, isNotNull, reason: 'createPrescription must POST to /prescriptions.');
      final body = entry!['body'] as Map<String, dynamic>;
      expect(body['patient_id'], 42);
      expect(body['consultation_id'], 24);

      final medicines = body['medicines'] as List;
      expect(medicines.length, 1);
      final med = medicines.first as Map<String, dynamic>;
      expect(med['medicine_name'], 'Tab. Panadol (Paracetamol) 500mg');
      expect(med['dosage'], '1 Tablet');
      expect(med['frequency'], 'Every 6 hours (max 4/day)');
      expect(med['duration'], '5 days');
      expect(med['instructions'], 'After meals with water');

      // After a successful create the service refreshes the real list.
      expect(PrescriptionService().prescriptions, isNotEmpty);
      expect(PrescriptionService().prescriptions.first.id, '9');
    });

    test('createPrescription returns false when the backend rejects (403)', () async {
      handler = (req) async {
        await respond(req, 403, fail(403, 'Only verified doctors can issue prescriptions.'));
      };

      final success = await PrescriptionService().createPrescription(
        patientId: 42,
        medicines: [
          const PrescriptionItem(
            medicineName: 'Some Medicine',
            dosage: '1 Tablet',
            frequency: 'Once daily',
            duration: '3 days',
            instructions: '',
          ),
        ],
      );

      expect(success, isFalse);
    });

    test('fetchPrescriptions parses consultation-linked prescriptions from the API', () async {
      handler = (req) async {
        await respond(req, 200, ok([realPrescriptionJson]));
      };

      final result = await PrescriptionService().fetchPrescriptions();

      expect(result.length, 1);
      expect(result.first.id, '9');
      expect(result.first.doctorName, 'Dr. Ayesha Siddiqui');
      expect(result.first.items.first.dosage, '1 Tablet');
      expect(result.first.items.first.frequency, 'Every 6 hours (max 4/day)');
      expect(result.first.items.first.duration, '5 days');
      expect(PrescriptionService().hasError, isFalse);
    });

    test('doctor context: explicit patient_id is sent to the API', () async {
      handler = (req) async {
        await respond(req, 200, ok([]));
      };

      await PrescriptionService().fetchPrescriptions(patientId: 42);

      expect(requestEntry('GET', '/prescriptions')!['uri'], contains('patient_id=42'));
    });
  });

  // ================================================================
  // AiCarePlanCard — UI renders the real care plan (UI preserved)
  // ================================================================
  group('AiCarePlanCard — real care plan UI (preserved)', () {
    testWidgets('renders medication guidance, emergency signs, and AI source badge', (tester) async {
      handler = (req) async {
        await respond(req, 200, ok(realCarePlanJson));
      };

      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AiCarePlanCard(consultationId: 24))));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();
        await tester.pump();
      });

      expect(find.text('Your AI Care Plan'), findsOneWidget);
      // Real prescribed medicine shown in the guidance section.
      expect(find.text('Tab. Panadol (Paracetamol) 500mg'), findsOneWidget);
      // Emergency sign with Rescue 1122.
      expect(find.textContaining('1122'), findsOneWidget);
      // Real Gemini source is badged as AI Generated, not Offline Template.
      expect(find.text('AI Generated'), findsOneWidget);
      expect(find.text('Offline Template'), findsNothing);
      expect(find.text('View Full Care Plan'), findsOneWidget);
    });

    testWidgets('renders nothing when no care plan exists — never a demo plan', (tester) async {
      handler = (req) async {
        await respond(req, 404, fail(404, 'No care plan found for this consultation.'));
      };

      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AiCarePlanCard(consultationId: 999))));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();
        await tester.pump();
      });

      expect(find.text('Your AI Care Plan'), findsNothing);
      expect(find.text('AI Generated'), findsNothing);
      expect(find.text('Offline Template'), findsNothing);
    });
  });
}
