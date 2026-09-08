import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_ai_pakistan/models/medicine_reminder_model.dart';
import 'package:sehat_ai_pakistan/models/daily_adherence_model.dart';
import 'package:sehat_ai_pakistan/services/medicine_service.dart';
import 'package:sehat_ai_pakistan/services/api_service.dart';
import 'package:sehat_ai_pakistan/core/constants/api_endpoints.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Allow real HTTP in tests (per learned_skill_experience memory).
  setUpAll(() {
    HttpOverrides.global = null;
  });

  group('Phase 6 — DailyAdherenceModel', () {
    test('parses adherence response correctly', () {
      final json = {
        'date': '2026-09-07',
        'total_active': 3,
        'taken': 2,
        'missed': 1,
        'pending': 0,
        'adherence_percent': 67,
        'medicines': [
          {
            'reminder_id': 1,
            'medicine_name': 'Aspirin 75mg',
            'dosage': '75mg',
            'frequency': 'Once daily',
            'time_of_day': '01:00 PM',
            'intake_status': 'taken',
          },
          {
            'reminder_id': 2,
            'medicine_name': 'Metformin 500mg',
            'dosage': '500mg',
            'frequency': 'Twice daily',
            'time_of_day': '08:00 AM',
            'intake_status': 'taken',
          },
          {
            'reminder_id': 3,
            'medicine_name': 'Omeprazole 20mg',
            'dosage': '20mg',
            'frequency': 'Once daily',
            'time_of_day': '07:30 AM',
            'intake_status': 'missed',
          },
        ],
      };

      final adherence = DailyAdherenceModel.fromJson(json);

      expect(adherence.date, '2026-09-07');
      expect(adherence.totalActive, 3);
      expect(adherence.taken, 2);
      expect(adherence.missed, 1);
      expect(adherence.pending, 0);
      expect(adherence.adherencePercent, 67);
      expect(adherence.medicines.length, 3);

      expect(adherence.medicines[0].isTaken, isTrue);
      expect(adherence.medicines[1].isTaken, isTrue);
      expect(adherence.medicines[2].isMissed, isTrue);
      expect(adherence.medicines[0].medicineName, 'Aspirin 75mg');
    });

    test('handles empty adherence response', () {
      final json = {
        'date': '2026-09-07',
        'total_active': 0,
        'taken': 0,
        'missed': 0,
        'pending': 0,
        'adherence_percent': 0,
        'medicines': <dynamic>[],
      };

      final adherence = DailyAdherenceModel.fromJson(json);
      expect(adherence.totalActive, 0);
      expect(adherence.medicines, isEmpty);
    });

    test('handles null/missing fields gracefully', () {
      final json = <String, dynamic>{};
      final adherence = DailyAdherenceModel.fromJson(json);
      expect(adherence.totalActive, 0);
      expect(adherence.adherencePercent, 0);
      expect(adherence.medicines, isEmpty);
    });
  });

  group('Phase 6 — MedicineReminderModel', () {
    test('parses backend response correctly', () {
      final json = {
        'id': 42,
        'medicine_name': 'Loprin (Aspirin)',
        'dosage': '75mg',
        'frequency': 'Once daily',
        'time_of_day': '01:00 PM',
        'start_date': '2026-09-01',
        'end_date': '2026-10-01',
        'is_active': 1,
        'instructions': 'Post lunch daily',
      };

      final model = MedicineReminderModel.fromJson(json);
      expect(model.id, '42');
      expect(model.medicineName, 'Loprin (Aspirin)');
      expect(model.dosage, '75mg');
      expect(model.isReminderActive, isTrue);
      expect(model.startDate.year, 2026);
    });

    test('toJson produces correct API payload', () {
      final model = MedicineReminderModel(
        id: '5',
        medicineName: 'Test Med',
        dosage: '100mg',
        frequency: 'Twice daily',
        timeOfDay: '08:00 AM',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 10, 1),
        isReminderActive: true,
        instructions: 'Take after meals',
      );

      final json = model.toJson();
      expect(json['medicine_name'], 'Test Med');
      expect(json['dosage'], '100mg');
      expect(json['is_active'], isTrue);
      expect(json['start_date'], '2026-09-01');
    });

    test('copyWith creates correct modified copy', () {
      final original = MedicineReminderModel(
        id: '1',
        medicineName: 'Original',
        dosage: '50mg',
        frequency: 'Once daily',
        timeOfDay: '08:00 AM',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 2, 1),
        isReminderActive: true,
        instructions: 'Original instructions',
      );

      final toggled = original.copyWith(isReminderActive: false);
      expect(toggled.isReminderActive, isFalse);
      expect(toggled.medicineName, 'Original');

      final renamed = original.copyWith(medicineName: 'Renamed');
      expect(renamed.medicineName, 'Renamed');
      expect(renamed.id, '1');
    });
  });

  group('Phase 6 — MedicineService endpoints', () {
    test('new endpoint constants resolve correctly', () {
      ApiEndpoints.setCustomBaseUrl('http://127.0.0.1:1/api');

      expect(ApiEndpoints.medicines, contains('/medicines'));
      expect(ApiEndpoints.medicineAdherence, contains('/medicines/adherence'));
      expect(ApiEndpoints.medicineDetail(5), contains('/medicines/5'));
      expect(ApiEndpoints.toggleMedicine(5), contains('/medicines/5/toggle'));
      expect(ApiEndpoints.markMedicineIntake(5), contains('/medicines/5/intake'));
    });

    test('MedicineService has no mock/fallback data', () {
      final svc = MedicineService();
      // Fresh instance should have empty list — no mock data leaked.
      expect(svc.medicines, isEmpty);
      expect(svc.hasError, isFalse);
      expect(svc.adherence, isNull);
    });

    test('fetchMedicines against closed port returns error, not mock data', () async {
      // Point to a port that is guaranteed to refuse connections.
      ApiEndpoints.setCustomBaseUrl('http://127.0.0.1:1/api');
      ApiService.setAuthToken('fake_token_for_test');

      final svc = MedicineService();
      final result = await svc.fetchMedicines();

      // Must NOT return any mock/demo data on failure.
      expect(result, isEmpty);
      expect(svc.hasError, isTrue);
      expect(svc.errorMessage, isNotNull);

      // Cleanup
      ApiService.setAuthToken(null);
    });

    test('toggleReminder on closed port returns false (no silent state flip)', () async {
      ApiEndpoints.setCustomBaseUrl('http://127.0.0.1:1/api');
      ApiService.setAuthToken('fake_token');

      final svc = MedicineService();
      final result = await svc.toggleReminder('999');

      // Must return false — API failure should NOT flip local state.
      expect(result, isFalse);
      expect(svc.medicines, isEmpty);

      ApiService.setAuthToken(null);
    });

    test('deleteMedicine on closed port returns false', () async {
      ApiEndpoints.setCustomBaseUrl('http://127.0.0.1:1/api');
      ApiService.setAuthToken('fake_token');

      final svc = MedicineService();
      final result = await svc.deleteMedicine('999');
      expect(result, isFalse);

      ApiService.setAuthToken(null);
    });

    test('markIntake on closed port returns false', () async {
      ApiEndpoints.setCustomBaseUrl('http://127.0.0.1:1/api');
      ApiService.setAuthToken('fake_token');

      final svc = MedicineService();
      final result = await svc.markIntake('999', status: 'taken');
      expect(result, isFalse);

      ApiService.setAuthToken(null);
    });

    test('fetchDailyAdherence on closed port returns null', () async {
      ApiEndpoints.setCustomBaseUrl('http://127.0.0.1:1/api');
      ApiService.setAuthToken('fake_token');

      final svc = MedicineService();
      final result = await svc.fetchDailyAdherence();
      expect(result, isNull);
      expect(svc.adherence, isNull);

      ApiService.setAuthToken(null);
    });
  });

  group('Phase 6 — MedicineIntakeStatus', () {
    test('status getters work correctly', () {
      const taken = MedicineIntakeStatus(
        reminderId: 1,
        medicineName: 'Test',
        dosage: '10mg',
        frequency: 'Daily',
        timeOfDay: '8AM',
        intakeStatus: 'taken',
      );
      expect(taken.isTaken, isTrue);
      expect(taken.isMissed, isFalse);
      expect(taken.isPending, isFalse);

      const missed = MedicineIntakeStatus(
        reminderId: 2,
        medicineName: 'Test',
        dosage: '10mg',
        frequency: 'Daily',
        timeOfDay: '8AM',
        intakeStatus: 'missed',
      );
      expect(missed.isMissed, isTrue);
      expect(missed.isTaken, isFalse);

      const pending = MedicineIntakeStatus(
        reminderId: 3,
        medicineName: 'Test',
        dosage: '10mg',
        frequency: 'Daily',
        timeOfDay: '8AM',
        intakeStatus: 'pending',
      );
      expect(pending.isPending, isTrue);
    });
  });
}
