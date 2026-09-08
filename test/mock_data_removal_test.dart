import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_ai_pakistan/core/constants/api_endpoints.dart';
import 'package:sehat_ai_pakistan/features/doctors/screens/doctor_list_screen.dart';
import 'package:sehat_ai_pakistan/features/medicines/screens/medicines_screen.dart';
import 'package:sehat_ai_pakistan/services/consultation_service.dart';
import 'package:sehat_ai_pakistan/services/doctor_service.dart';
import 'package:sehat_ai_pakistan/services/emergency_service.dart';
import 'package:sehat_ai_pakistan/services/medical_records_service.dart';
import 'package:sehat_ai_pakistan/services/medicine_service.dart';
import 'package:sehat_ai_pakistan/services/mock_data_service.dart';
import 'package:sehat_ai_pakistan/services/prescription_service.dart';

/// Phase 2 fix verification: no demo/mock data may ever be shown to a real
/// logged-in user.
///
/// A local HTTP server stands in for the PHP API so every scenario
/// (empty account, real data, server failure, network failure) can be tested
/// deterministically.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HttpServer server;
  late String baseUrl;
  String? lastRequestUri;
  Future<void> Function(HttpRequest request)? handler;

  void respond(HttpRequest request, int code, Map<String, dynamic> body) {
    request.response.statusCode = code;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
    request.response.close();
  }

  Map<String, dynamic> ok(List<dynamic> data) => {
        'status': 'success',
        'message': 'Retrieved.',
        'data': data,
      };

  setUpAll(() async {
    // TestWidgetsFlutterBinding installs a global HttpOverrides whose client
    // answers every request with an empty 400 response (see
    // flutter_test/src/_binding_io.dart). Restore the real HttpClient so the
    // requests below actually reach the local test server.
    HttpOverrides.global = null;

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://${server.address.address}:${server.port}';
    ApiEndpoints.setCustomBaseUrl(baseUrl);

    server.listen((request) async {
      lastRequestUri = request.uri.toString();
      await request.drain<void>();
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
    lastRequestUri = null;
    handler = null;
  });

  group('MedicineService — no mock fallback', () {
    test('fresh patient: success with zero records => empty list, no error', () async {
      handler = (req) async {
        respond(req, 200, ok([]));
      };

      final result = await MedicineService().fetchMedicines();

      expect(result, isEmpty);
      expect(MedicineService().medicines, isEmpty);
      expect(MedicineService().hasError, isFalse);
    });

    test('existing patient: success with real records parses real data only', () async {
      handler = (req) async {
        respond(req, 200, ok([
          {
            'id': 7,
            'patient_id': 42,
            'medicine_name': 'Panadol 500mg',
            'dosage': '1 Tablet',
            'frequency': 'Twice daily',
            'time_of_day': '08:00 AM',
            'start_date': '2026-01-01',
            'end_date': '2026-01-08',
            'is_active': true,
            'instructions': 'After meals',
          },
        ]));
      };

      final result = await MedicineService().fetchMedicines();

      expect(result.length, 1);
      expect(result.first.id, '7');
      expect(result.first.medicineName, 'Panadol 500mg');
      expect(MedicineService().hasError, isFalse);
    });

    test('API failure (HTTP 500) => real error state, never demo medicines', () async {
      handler = (req) async {
        respond(req, 500, {'status': 'error', 'message': 'Internal Server Error'});
      };

      final result = await MedicineService().fetchMedicines();

      expect(result, isEmpty);
      expect(MedicineService().medicines, isEmpty);
      expect(MedicineService().hasError, isTrue);
      expect(MedicineService().errorMessage, isNotNull);
    });

    test('network failure (server unreachable) => real error state', () async {
      ApiEndpoints.setCustomBaseUrl('http://127.0.0.1:1');

      final result = await MedicineService().fetchMedicines();

      expect(result, isEmpty);
      expect(MedicineService().hasError, isTrue);
      expect(MedicineService().medicines, isEmpty);

      ApiEndpoints.setCustomBaseUrl(baseUrl);
    });

    test('doctor patient detail: explicit patient_id is sent to the API', () async {
      handler = (req) async {
        respond(req, 200, ok([]));
      };

      await MedicineService().fetchMedicines(patientId: 42);

      expect(lastRequestUri, isNotNull);
      expect(lastRequestUri, contains('patient_id=42'));
    });
  });

  group('MedicalRecordsService — no mock fallback', () {
    test('fresh patient: success with zero records => empty list, no error', () async {
      handler = (req) async {
        respond(req, 200, ok([]));
      };

      final result = await MedicalRecordsService().fetchRecords();

      expect(result, isEmpty);
      expect(MedicalRecordsService().records, isEmpty);
      expect(MedicalRecordsService().hasError, isFalse);
    });

    test('existing patient: success with real records parses real data', () async {
      handler = (req) async {
        respond(req, 200, ok([
          {
            'id': 3,
            'patient_id': 42,
            'title': 'Annual Checkup',
            'category': 'consultation',
            'doctor_or_lab': 'Dr. Ayesha Siddiqui',
            'description': 'Routine review',
            'diagnosis': 'Healthy',
            'date': '2026-01-05',
          },
        ]));
      };

      final result = await MedicalRecordsService().fetchRecords();

      expect(result.length, 1);
      expect(result.first.title, 'Annual Checkup');
      expect(result.first.doctorOrLab, 'Dr. Ayesha Siddiqui');
      expect(MedicalRecordsService().hasError, isFalse);
    });

    test('API failure => real error state, never demo records', () async {
      handler = (req) async {
        respond(req, 500, {'status': 'error', 'message': 'Internal Server Error'});
      };

      final result = await MedicalRecordsService().fetchRecords();

      expect(result, isEmpty);
      expect(MedicalRecordsService().records, isEmpty);
      expect(MedicalRecordsService().hasError, isTrue);
    });

    test('doctor patient detail: explicit patient_id and category are sent to the API', () async {
      handler = (req) async {
        respond(req, 200, ok([]));
      };

      await MedicalRecordsService().fetchRecords(category: 'prescription', patientId: 7);

      expect(lastRequestUri, contains('patient_id=7'));
      expect(lastRequestUri, contains('category=prescription'));
    });
  });

  group('PrescriptionService — no mock fallback', () {
    test('fresh patient: success with zero records => empty list, no error', () async {
      handler = (req) async {
        respond(req, 200, ok([]));
      };

      final result = await PrescriptionService().fetchPrescriptions();

      expect(result, isEmpty);
      expect(PrescriptionService().prescriptions, isEmpty);
      expect(PrescriptionService().hasError, isFalse);
    });

    test('existing patient: success with real prescriptions parses real data', () async {
      handler = (req) async {
        respond(req, 200, ok([
          {
            'id': 5,
            'consultation_id': 12,
            'patient_id': 42,
            'doctor_name': 'Dr. Ayesha Siddiqui',
            'doctor_specialty': 'Cardiology',
            'is_verified': true,
            'created_at': '2026-01-05 10:00:00',
            'medicines': [
              {
                'id': 9,
                'medicine_name': 'Augmentin 625mg',
                'dosage': '1 Tablet',
                'frequency': 'Twice daily',
                'duration': '5 Days',
                'instructions': 'After meals',
              },
            ],
          },
        ]));
      };

      final result = await PrescriptionService().fetchPrescriptions();

      expect(result.length, 1);
      expect(result.first.doctorName, 'Dr. Ayesha Siddiqui');
      expect(result.first.items.first.medicineName, 'Augmentin 625mg');
      expect(PrescriptionService().hasError, isFalse);
    });

    test('API failure => real error state, never demo prescriptions', () async {
      handler = (req) async {
        respond(req, 500, {'status': 'error', 'message': 'Internal Server Error'});
      };

      final result = await PrescriptionService().fetchPrescriptions();

      expect(result, isEmpty);
      expect(PrescriptionService().prescriptions, isEmpty);
      expect(PrescriptionService().hasError, isTrue);
    });

    test('doctor context: explicit patient_id is sent to the API', () async {
      handler = (req) async {
        respond(req, 200, ok([]));
      };

      await PrescriptionService().fetchPrescriptions(patientId: 42);

      expect(lastRequestUri, contains('patient_id=42'));
    });
  });

  group('ConsultationService — no offline/demo consultation creation', () {
    test('API failure returns false and never fabricates a consultation', () async {
      handler = (req) async {
        respond(req, 500, {'status': 'error', 'message': 'Internal Server Error'});
      };

      final before = List.of(ConsultationService().consultations);
      final success = await ConsultationService().requestConsultation(
        symptoms: 'Chest pain and shortness of breath',
        riskLevel: 'high',
      );

      expect(success, isFalse);
      final after = ConsultationService().consultations;
      expect(after.length, before.length);
      expect(after.where((c) => c.id.startsWith('cons_')), isEmpty,
          reason: 'No locally fabricated consultation IDs may be created.');
    });

    test('network failure returns false and never fabricates a consultation', () async {
      ApiEndpoints.setCustomBaseUrl('http://127.0.0.1:1');

      final success = await ConsultationService().requestConsultation(
        symptoms: 'High fever for three days',
      );

      expect(success, isFalse);
      expect(ConsultationService().consultations.where((c) => c.id.startsWith('cons_')), isEmpty);

      ApiEndpoints.setCustomBaseUrl(baseUrl);
    });

    test('API success returns true and stores the server consultation', () async {
      handler = (req) async {
        if (req.method == 'POST' && req.uri.path == '/consultations/request') {
          respond(req, 201, {
            'status': 'success',
            'message': 'Consultation request submitted successfully.',
            'data': {'consultation_id': 15, 'doctor_id': 2, 'status': 'pending', 'risk_level': 'high'},
          });
        } else {
          respond(req, 200, ok([
            {'id': 15, 'patient_id': 42, 'doctor_id': 2, 'symptoms': 'High fever', 'status': 'pending'},
          ]));
        }
      };

      final success = await ConsultationService().requestConsultation(
        symptoms: 'High fever for three days',
      );

      expect(success, isTrue);
      expect(ConsultationService().consultations, isNotEmpty);
      expect(ConsultationService().consultations.first.id, '15');
    });

    test('missing patient_id in payload never maps to demo patient #6', () async {
      handler = (req) async {
        respond(req, 200, ok([
          {'id': 21, 'doctor_id': 2, 'symptoms': 'Fever', 'status': 'pending'},
        ]));
      };

      await ConsultationService().fetchPatientConsultations();

      final patient = ConsultationService().consultations.first.patient;
      expect(patient.id, isNot('6'),
          reason: 'A missing patient_id must not silently become demo patient #6.');
    });
  });

  group('EmergencyService — SOS never reports fake success', () {
    test('API failure (HTTP 500) reports failure, no local_sos id', () async {
      handler = (req) async {
        respond(req, 500, {'status': 'error', 'message': 'Internal Server Error'});
      };

      final result = await EmergencyService().sendSos(symptoms: 'Severe chest pain');

      expect(result['success'], isFalse);
      expect(result['message'], isNot(contains('local_sos')));
      expect(result.containsKey('data'), isFalse);
    });

    test('network failure reports failure, no local_sos id', () async {
      ApiEndpoints.setCustomBaseUrl('http://127.0.0.1:1');

      final result = await EmergencyService().sendSos(symptoms: 'Unconscious after fall');

      expect(result['success'], isFalse);
      expect(result['message'], isNot(contains('local_sos')));
      expect(result.containsKey('data'), isFalse);

      ApiEndpoints.setCustomBaseUrl(baseUrl);
    });

    test('API success reports real success with server alert data', () async {
      handler = (req) async {
        respond(req, 201, {
          'status': 'success',
          'message': 'Emergency SOS alert logged.',
          'data': {'alert_id': 99, 'status': 'pending', 'helpline': '1122'},
        });
      };

      final result = await EmergencyService().sendSos(symptoms: 'Snake bite');

      expect(result['success'], isTrue);
      expect((result['data'] as Map)['alert_id'], 99);
      expect(EmergencyService().isTriggering, isFalse);
    });
  });

  group('DoctorService / doctor list — real verified doctors only', () {
    test('success: only doctors returned by the API are listed', () async {
      handler = (req) async {
        respond(req, 200, ok([
          {
            'id': 2,
            'name': 'Dr. Ayesha Siddiqui',
            'specialty': 'Cardiology',
            'hospital': 'DHQ Hospital Gilgit',
            'experience': 12,
            'is_available': true,
            'languages': ['Urdu', 'English'],
            'pmdc_number': 'PMDC-48920-P',
            'verification_status': 'verified',
            'availability': 'Available Today',
            'city': 'Gilgit',
            'phone': '+92 300 1111111',
            'bio': 'Consultant cardiologist.',
          },
        ]));
      };

      final result = await DoctorService().fetchDoctors();

      expect(result.length, 1);
      expect(result.first.name, 'Dr. Ayesha Siddiqui');
      expect(result.first.isVerified, isTrue);
      expect(DoctorService().hasError, isFalse);
    });

    test('zero verified doctors => empty list (proper empty state)', () async {
      handler = (req) async {
        respond(req, 200, ok([]));
      };

      final result = await DoctorService().fetchDoctors();

      expect(result, isEmpty);
      expect(DoctorService().doctors, isEmpty);
      expect(DoctorService().hasError, isFalse);
    });

    test('API failure => real error state, never demo doctors', () async {
      handler = (req) async {
        respond(req, 500, {'status': 'error', 'message': 'Internal Server Error'});
      };

      final result = await DoctorService().fetchDoctors();

      expect(result, isEmpty);
      expect(DoctorService().doctors, isEmpty);
      expect(DoctorService().hasError, isTrue);
      expect(DoctorService().errorMessage, isNotNull);
    });
  });

  group('MockDataService facade — no mock fallback', () {
    test('getters expose real service state, never seeded demo lists', () async {
      handler = (req) async {
        respond(req, 200, ok([]));
      };

      await MedicineService().fetchMedicines();
      await MedicalRecordsService().fetchRecords();
      await PrescriptionService().fetchPrescriptions();

      expect(MockDataService().medicines, isEmpty);
      expect(MockDataService().records, isEmpty);
      expect(MockDataService().prescriptions, isEmpty);
      expect(MockDataService().doctors, isEmpty);
    });
  });

  group('Screen empty / error states', () {
    testWidgets('MedicinesScreen shows empty state for a fresh patient', (tester) async {
      handler = (req) async {
        respond(req, 200, ok([]));
      };

      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: MedicinesScreen()));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();
        await tester.pump();
      });

      expect(find.text('No medicines scheduled.'), findsOneWidget);
      expect(find.text('Could not load your medicines.'), findsNothing);
    });

    testWidgets('MedicinesScreen shows real error state with retry on API failure', (tester) async {
      handler = (req) async {
        respond(req, 500, {'status': 'error', 'message': 'Internal Server Error'});
      };

      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: MedicinesScreen()));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();
        await tester.pump();
      });

      expect(find.text('Could not load your medicines.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('No medicines scheduled.'), findsNothing);
    });

    testWidgets('DoctorListScreen renders only real doctors returned by the API', (tester) async {
      handler = (req) async {
        respond(req, 200, ok([
          {
            'id': 2,
            'name': 'Dr. Ayesha Siddiqui',
            'specialty': 'Cardiology',
            'hospital': 'DHQ Hospital Gilgit',
            'experience': 12,
            'is_available': true,
            'languages': ['Urdu', 'English'],
            'pmdc_number': 'PMDC-48920-P',
            'verification_status': 'verified',
            'availability': 'Available Today',
            'city': 'Gilgit',
            'phone': '+92 300 1111111',
            'bio': 'Consultant cardiologist.',
          },
        ]));
      };

      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: DoctorListScreen()));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();
        await tester.pump();
      });

      expect(find.text('Dr. Ayesha Siddiqui'), findsOneWidget);
      expect(find.text('No verified doctors available yet. Please check back later.'), findsNothing);
    });

    testWidgets('DoctorListScreen shows empty state when zero doctors exist', (tester) async {
      handler = (req) async {
        respond(req, 200, ok([]));
      };

      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: DoctorListScreen()));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();
        await tester.pump();
      });

      expect(find.text('No verified doctors available yet. Please check back later.'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('DoctorListScreen shows real error state with retry on API failure', (tester) async {
      handler = (req) async {
        respond(req, 500, {'status': 'error', 'message': 'Internal Server Error'});
      };

      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: DoctorListScreen()));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();
        await tester.pump();
      });

      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Dr. Ayesha Siddiqui'), findsNothing);
      expect(find.text('No verified doctors available yet. Please check back later.'), findsNothing);
    });
  });
}
