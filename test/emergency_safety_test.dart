// SehatAI Pakistan - Phase 7: Emergency Safety Tests
//
// Critical MVP verification:
//   1. Deterministic critical-symptom safety rule is AI-INDEPENDENT — the
//      mapper may only escalate (never downgrade) critical emergencies.
//   2. EmergencyService.sendSos sends a REAL request and never fabricates
//      location/city data that the caller did not provide.
//   3. EmergencyActionsService performs REAL device actions: tel:1122 dial,
//      GPS reading, OS share sheet — failures reported honestly.
//   4. The high-risk UI wiring actually dials 1122 AND records the SOS
//      alert through the backend.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sehat_ai_pakistan/core/constants/api_endpoints.dart';
import 'package:sehat_ai_pakistan/core/widgets/risk_indicator_badge.dart';
import 'package:sehat_ai_pakistan/features/emergency/emergency_triage_mapper.dart';
import 'package:sehat_ai_pakistan/features/emergency/screens/triage_result_screen.dart';
import 'package:sehat_ai_pakistan/models/triage_model.dart';
import 'package:sehat_ai_pakistan/services/ai_triage_service.dart';
import 'package:sehat_ai_pakistan/services/emergency_actions_service.dart';
import 'package:sehat_ai_pakistan/services/emergency_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HttpServer server;
  late String baseUrl;
  Map<String, dynamic>? lastRequestBody;
  String? lastRequestPath;
  Future<void> Function(HttpRequest request)? handler;

  void respond(HttpRequest request, int code, Map<String, dynamic> body) {
    request.response.statusCode = code;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
    request.response.close();
  }

  setUpAll(() async {
    // Restore the real HttpClient so requests reach the local test server
    // (TestWidgetsFlutterBinding installs an HttpOverrides answering 400).
    HttpOverrides.global = null;

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://${server.address.address}:${server.port}';
    ApiEndpoints.setCustomBaseUrl(baseUrl);

    server.listen((request) async {
      lastRequestPath = request.uri.path;
      final bodyBytes =
          await request.fold<List<int>>([], (prev, chunk) => prev + chunk);
      final bodyString = utf8.decode(bodyBytes);
      if (bodyString.isNotEmpty) {
        try {
          lastRequestBody = jsonDecode(bodyString);
        } catch (_) {
          lastRequestBody = null;
        }
      } else {
        lastRequestBody = null;
      }

      final h = handler;
      if (h != null) {
        await h(request);
      } else {
        respond(request, 500, {'status': 'error', 'message': 'No handler configured.'});
      }
    });
  });

  tearDownAll(() async {
    await server.close(force: true);
  });

  setUp(() {
    lastRequestBody = null;
    lastRequestPath = null;
    handler = null;
    EmergencyActionsService.launchUrlOverride = null;
    EmergencyActionsService.currentLocationOverride = null;
    EmergencyActionsService.shareOverride = null;
  });

  tearDown(() {
    EmergencyActionsService.launchUrlOverride = null;
    EmergencyActionsService.currentLocationOverride = null;
    EmergencyActionsService.shareOverride = null;
  });

  AiTriageResult aiVerdict(
    TriageRiskLevel risk, {
    bool requiresDoctor = false,
    String? warning,
  }) {
    return AiTriageResult(
      reply: 'AI assessment reply',
      detectedSymptoms: ['AI detected something'],
      riskLevel: risk,
      requiresDoctor: requiresDoctor,
      emergencyWarning: warning,
      disclaimer: 'Preliminary guidance only.',
      sessionId: 'sess_phase7_test',
      quickActions: const [],
      source: 'gemini_api',
    );
  }

  // ================================================================
  // 1. Deterministic critical-symptom safety rule — AI INDEPENDENT
  // ================================================================
  group('Deterministic safety rule — critical symptoms override the AI', () {
    test('AI says LOW for chest pain — forced to HIGH', () {
      final model = triageModelFromAiResult(
        aiVerdict(TriageRiskLevel.low),
        symptomText: 'mujhe shadeed chest pain ho raha hai',
      );
      expect(model.riskLevel, TriageRiskLevel.high);
      expect(model.requiresImmediateDoctor, isTrue);
    });

    test('AI says MODERATE for snake bite — forced to HIGH', () {
      final model = triageModelFromAiResult(
        aiVerdict(TriageRiskLevel.moderate, requiresDoctor: true),
        symptomText: 'saanp ne kata hai, zehar faila raha hai',
      );
      expect(model.riskLevel, TriageRiskLevel.high);
      expect(model.requiresImmediateDoctor, isTrue);
    });

    test('AI says LOW for breathing difficulty (Roman Urdu) — forced to HIGH', () {
      final model = triageModelFromAiResult(
        aiVerdict(TriageRiskLevel.low),
        symptomText: 'sans lene mein dushwari ho rahi hai',
      );
      expect(model.riskLevel, TriageRiskLevel.high);
    });

    test('AI says LOW for unconsciousness — forced to HIGH with warning', () {
      final model = triageModelFromAiResult(
        aiVerdict(TriageRiskLevel.low),
        symptomText: 'mareez behosh ho gaya hai',
      );
      expect(model.riskLevel, TriageRiskLevel.high);
      expect(model.requiresImmediateDoctor, isTrue);
      expect(model.emergencyAction, isNotEmpty);
    });

    test('AI LOW + mild symptom stays LOW (no false escalation)', () {
      final model = triageModelFromAiResult(
        aiVerdict(TriageRiskLevel.low),
        symptomText: 'mild headache since morning',
      );
      expect(model.riskLevel, TriageRiskLevel.low);
      expect(model.requiresImmediateDoctor, isFalse);
    });

    test('AI MODERATE + non-critical fever stays MODERATE (AI respected)', () {
      final model = triageModelFromAiResult(
        aiVerdict(TriageRiskLevel.moderate, requiresDoctor: true),
        symptomText: 'Mujhe do din se bukhar hai aur ulti ho rahi hai',
      );
      expect(model.riskLevel, TriageRiskLevel.moderate);
    });

    test('AI HIGH passes through as HIGH', () {
      final model = triageModelFromAiResult(
        aiVerdict(TriageRiskLevel.high, requiresDoctor: true, warning: 'Call 1122 now'),
        symptomText: 'chest pain and sweating',
      );
      expect(model.riskLevel, TriageRiskLevel.high);
      expect(model.emergencyAction, 'Call 1122 now');
    });
  });

  // ================================================================
  // 2. EmergencyService.sendSos — real request, no fabricated data
  // ================================================================
  group('EmergencyService.sendSos — request integrity', () {
    test('no fabricated coordinates or city when caller provides none', () async {
      handler = (req) async {
        respond(req, 201, {
          'status': 'success',
          'message': 'Emergency SOS alert logged.',
          'data': {'alert_id': 5, 'status': 'pending'},
        });
      };

      final result = await EmergencyService().sendSos(symptoms: 'Severe bleeding');

      expect(result['success'], isTrue);
      expect(lastRequestPath, '/emergency/sos');
      expect(lastRequestBody, isNotNull);
      expect(lastRequestBody!.containsKey('latitude'), isFalse,
          reason: 'latitude must not be fabricated when unknown');
      expect(lastRequestBody!.containsKey('longitude'), isFalse,
          reason: 'longitude must not be fabricated when unknown');
      expect(lastRequestBody!.containsKey('city'), isFalse,
          reason: 'city must not be fabricated when unknown');
      expect(lastRequestBody!['symptoms'], 'Severe bleeding');
      expect(lastRequestBody!['risk_level'], 'high');
      expect((result['data'] as Map)['alert_id'], 5);
    });

    test('real city and coordinates are transmitted verbatim (trimmed)', () async {
      handler = (req) async {
        respond(req, 201, {
          'status': 'success',
          'message': 'ok',
          'data': {'alert_id': 6, 'status': 'pending'},
        });
      };

      await EmergencyService().sendSos(
        symptoms: 'Chest pain',
        riskLevel: 'moderate',
        city: '  Skardu  ',
        latitude: 36.3095,
        longitude: 74.6463,
      );

      expect(lastRequestBody!['city'], 'Skardu');
      expect(lastRequestBody!['latitude'], 36.3095);
      expect(lastRequestBody!['longitude'], 74.6463);
      expect(lastRequestBody!['risk_level'], 'moderate');
    });

    test('HTTP 500 — honest failure, never a fake success', () async {
      handler = (req) async {
        respond(req, 500, {'status': 'error', 'message': 'Internal Server Error'});
      };

      final result = await EmergencyService().sendSos(symptoms: 'Snake bite');

      expect(result['success'], isFalse);
      expect(result.containsKey('data'), isFalse);
    });
  });

  // ================================================================
  // 3. EmergencyService.fetchMyAlerts — patient-scoped access
  // ================================================================
  group('EmergencyService.fetchMyAlerts', () {
    test('returns the patient own alerts from the server', () async {
      handler = (req) async {
        respond(req, 200, {
          'status': 'success',
          'message': 'Emergency alerts retrieved.',
          'data': [
            {
              'id': 11,
              'patient_id': 42,
              'symptom_description': 'Chest pain',
              'risk_level': 'high',
              'city': 'Skardu',
              'status': 'pending',
            },
          ],
        });
      };

      final result = await EmergencyService().fetchMyAlerts();

      expect(result['success'], isTrue);
      expect(lastRequestPath, '/emergency/alerts');
      expect((result['data'] as List).length, 1);
      expect((result['data'] as List).first['patient_id'], 42);
    });

    test('server rejection (403) — honest failure', () async {
      handler = (req) async {
        respond(req, 403, {'status': 'error', 'message': 'Forbidden'});
      };

      final result = await EmergencyService().fetchMyAlerts();

      expect(result['success'], isFalse);
    });

    test('network failure — honest failure', () async {
      ApiEndpoints.setCustomBaseUrl('http://127.0.0.1:1');

      final result = await EmergencyService().fetchMyAlerts();

      expect(result['success'], isFalse);

      ApiEndpoints.setCustomBaseUrl(baseUrl);
    });
  });

  // ================================================================
  // 4. EmergencyActionsService — real device actions
  // ================================================================
  group('EmergencyActionsService — real 1122 call, GPS, share', () {
    test('callRescue1122 dials tel:1122 via external application', () async {
      Uri? capturedUri;
      LaunchMode? capturedMode;
      EmergencyActionsService.launchUrlOverride = (uri, mode) async {
        capturedUri = uri;
        capturedMode = mode;
        return true;
      };

      final ok = await EmergencyActionsService().callRescue1122();

      expect(ok, isTrue);
      expect(capturedUri.toString(), 'tel:1122');
      expect(capturedMode, LaunchMode.externalApplication);
    });

    test('dialer cannot open — returns false (honest)', () async {
      EmergencyActionsService.launchUrlOverride = (uri, mode) async => false;

      expect(await EmergencyActionsService().callRescue1122(), isFalse);
    });

    test('dialer throws — returns false, does not crash', () async {
      EmergencyActionsService.launchUrlOverride = (uri, mode) async {
        throw Exception('No dialer app');
      };

      expect(await EmergencyActionsService().callRescue1122(), isFalse);
    });

    test('location unavailable — returns null, never fabricated', () async {
      EmergencyActionsService.currentLocationOverride = () async => null;

      expect(await EmergencyActionsService().getCurrentLocation(), isNull);
    });

    test('share includes real GPS coordinates and a map link', () async {
      String? sharedText;
      EmergencyActionsService.shareOverride = (text) async {
        sharedText = text;
        return ShareResult.unavailable;
      };

      final ok = await EmergencyActionsService().shareEmergencyLocation(
        patientName: 'Test Patient',
        city: 'Skardu',
        symptoms: 'Chest pain',
        location: const EmergencyLocation(latitude: 35.9208, longitude: 74.3144),
      );

      expect(ok, isTrue);
      expect(sharedText, contains('Test Patient'));
      expect(sharedText, contains('Live GPS: 35.920800, 74.314400'));
      expect(sharedText, contains('maps.google.com/?q=35.9208,74.3144'));
      expect(sharedText, contains('1122'));
    });

    test('share without GPS honestly states location unavailable', () async {
      String? sharedText;
      EmergencyActionsService.shareOverride = (text) async {
        sharedText = text;
        return ShareResult.unavailable;
      };

      final ok = await EmergencyActionsService().shareEmergencyLocation(
        patientName: 'Test Patient',
        city: 'Skardu',
        location: null,
      );

      expect(ok, isTrue);
      expect(sharedText, contains('unavailable'));
      expect(sharedText, isNot(contains('maps.google.com')));
    });
  });

  // ================================================================
  // 5. High-risk UI wiring — real dial + real SOS record
  // ================================================================
  group('TriageResultScreen high-risk actions', () {
    final highRiskTriage = TriageModel(
      id: 'triage_phase7_test',
      riskLevel: TriageRiskLevel.high,
      primaryComplaint: 'Crushing chest pain',
      detectedSymptoms: const ['Chest pain', 'Cold sweats'],
      generalGuidance: 'Urgent evaluation needed.',
      nextSteps: 'Call emergency services.',
      emergencyAction: 'Call Rescue 1122.',
      timestamp: DateTime(2026, 9, 7),
      requiresImmediateDoctor: true,
    );

    testWidgets('Call Rescue 1122: confirmation dials tel:1122 AND records SOS with real location',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      bool dialLaunched = false;
      Uri? dialedUri;
      EmergencyActionsService.launchUrlOverride = (uri, mode) async {
        dialLaunched = true;
        dialedUri = uri;
        return true;
      };
      EmergencyActionsService.currentLocationOverride = () async =>
          const EmergencyLocation(latitude: 35.9208, longitude: 74.3144);

      lastRequestBody = null;
      handler = (req) async {
        respond(req, 201, {
          'status': 'success',
          'message': 'Emergency SOS alert registered.',
          'data': {'alert_id': 77, 'status': 'pending'},
        });
      };

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(home: TriageResultScreen(triage: highRiskTriage)),
        );
        await tester.pump();

        // Open the confirmation dialog.
        await tester.tap(find.text('Call Rescue 1122 (Emergency)'));
        await tester.pump();
        expect(find.text('Call Rescue 1122?'), findsOneWidget);

        // Confirm the call.
        await tester.tap(find.text('Call 1122'));
        // Let the dial + location + SOS request complete.
        await Future<void>.delayed(const Duration(milliseconds: 800));
        await tester.pump();
        await tester.pump();
      });

      // Real dialer action was triggered with the emergency number.
      expect(dialLaunched, isTrue);
      expect(dialedUri.toString(), 'tel:1122');

      // Real SOS request reached the backend with real data.
      expect(lastRequestBody, isNotNull);
      expect(lastRequestBody!['symptoms'], 'Crushing chest pain');
      expect(lastRequestBody!['risk_level'], 'high');
      expect(lastRequestBody!['latitude'], 35.9208);
      expect(lastRequestBody!['longitude'], 74.3144);

      // Honest success feedback referencing the server alert id.
      expect(find.textContaining('SOS alert #77'), findsOneWidget);
    });

    testWidgets('Share Location opens the OS share sheet with the real GPS position',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String? sharedText;
      EmergencyActionsService.shareOverride = (text) async {
        sharedText = text;
        return ShareResult.unavailable;
      };
      EmergencyActionsService.currentLocationOverride = () async =>
          const EmergencyLocation(latitude: 36.3095, longitude: 74.6463);

      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(home: TriageResultScreen(triage: highRiskTriage)),
        );
        await tester.pump();

        await tester.tap(find.text('Share Location with Nearby Clinic'));
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await tester.pump();
        await tester.pump();
      });

      expect(sharedText, isNotNull);
      expect(sharedText, contains('maps.google.com/?q=36.3095,74.6463'));
      expect(find.textContaining('live GPS coordinates'), findsOneWidget);
    });
  });
}
