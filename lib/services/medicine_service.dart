import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';
import '../models/medicine_reminder_model.dart';
import '../models/daily_adherence_model.dart';
import 'api_service.dart';

class MedicineService extends ChangeNotifier {
  static final MedicineService _instance = MedicineService._internal();
  factory MedicineService() => _instance;
  MedicineService._internal();

  final ApiService _api = ApiService();
  List<MedicineReminderModel> _medicines = [];
  bool _isLoading = false;
  String? _error;
  DailyAdherenceModel? _adherence;

  /// Real API data only. Empty list means no reminders exist on the server.
  List<MedicineReminderModel> get medicines => _medicines;
  bool get isLoading => _isLoading;

  /// Non-null when the last fetch failed. Screens should show an error/retry
  /// state instead of any placeholder data.
  String? get errorMessage => _error;
  bool get hasError => _error != null;

  /// Latest daily adherence data, or null if not yet fetched.
  DailyAdherenceModel? get adherence => _adherence;

  Future<List<MedicineReminderModel>> fetchMedicines({int? patientId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = ApiEndpoints.medicines;
      if (patientId != null) {
        url += '?patient_id=$patientId';
      }

      final res = await _api.get(url);
      if (res.isSuccess && res.data is List) {
        final list = res.data as List;
        _medicines = list.map((item) {
          final map = item as Map<String, dynamic>;
          return MedicineReminderModel(
            id: map['id'].toString(),
            medicineName: map['medicine_name'] ?? 'Medicine',
            dosage: map['dosage'] ?? '1 Tablet',
            frequency: map['frequency'] ?? 'Once daily',
            timeOfDay: map['time_of_day'] ?? '08:00 AM',
            startDate: DateTime.tryParse(map['start_date']?.toString() ?? '') ?? DateTime.now(),
            endDate: DateTime.tryParse(map['end_date']?.toString() ?? '') ??
                DateTime.now().add(const Duration(days: 30)),
            isReminderActive: map['is_active'] == true || map['is_active'] == 1,
            instructions: map['instructions'] ?? '',
          );
        }).toList();

        _isLoading = false;
        notifyListeners();
        return _medicines;
      }

      _error = res.message.isNotEmpty ? res.message : 'Failed to load medicines.';
    } catch (e) {
      debugPrint('[MedicineService] Fetch error: $e');
      _error = 'Failed to load medicines. Please check your connection and try again.';
    }

    // Real failure: expose the error, never fall back to demo data.
    _medicines = [];
    _isLoading = false;
    notifyListeners();
    return _medicines;
  }

  Future<bool> addMedicine(MedicineReminderModel reminder) async {
    try {
      final res = await _api.post(
        ApiEndpoints.medicines,
        {
          'medicine_name': reminder.medicineName,
          'dosage': reminder.dosage,
          'frequency': reminder.frequency,
          'time_of_day': reminder.timeOfDay,
          'start_date': reminder.startDate.toIso8601String().split('T').first,
          'end_date': reminder.endDate.toIso8601String().split('T').first,
          'instructions': reminder.instructions,
        },
      );

      if (res.isSuccess) {
        await fetchMedicines();
        return true;
      }

      debugPrint('[MedicineService] Add failed: ${res.message}');
      return false;
    } catch (e) {
      debugPrint('[MedicineService] Add error: $e');
      return false;
    }
  }

  /// Toggle active/inactive. Only flips local state on API success.
  Future<bool> toggleReminder(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return false;

    try {
      final res = await _api.post(ApiEndpoints.toggleMedicine(intId), {});
      if (res.isSuccess) {
        final index = _medicines.indexWhere((m) => m.id == id);
        if (index != -1) {
          _medicines[index] = _medicines[index].copyWith(
            isReminderActive: !_medicines[index].isReminderActive,
          );
          notifyListeners();
        }
        return true;
      }
      debugPrint('[MedicineService] Toggle failed: ${res.message}');
    } catch (e) {
      debugPrint('[MedicineService] Toggle API error: $e');
    }
    return false;
  }

  /// Update a medicine reminder via PUT.
  Future<bool> updateMedicine(String id, MedicineReminderModel updated) async {
    final intId = int.tryParse(id);
    if (intId == null) return false;

    try {
      final res = await _api.put(
        ApiEndpoints.medicineDetail(intId),
        updated.toJson()..remove('id'),
      );
      if (res.isSuccess) {
        await fetchMedicines();
        return true;
      }
      debugPrint('[MedicineService] Update failed: ${res.message}');
    } catch (e) {
      debugPrint('[MedicineService] Update error: $e');
    }
    return false;
  }

  /// Delete a medicine reminder via DELETE.
  Future<bool> deleteMedicine(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return false;

    try {
      final res = await _api.delete(ApiEndpoints.medicineDetail(intId));
      if (res.isSuccess) {
        _medicines.removeWhere((m) => m.id == id);
        notifyListeners();
        return true;
      }
      debugPrint('[MedicineService] Delete failed: ${res.message}');
    } catch (e) {
      debugPrint('[MedicineService] Delete error: $e');
    }
    return false;
  }

  /// Mark a medicine as taken or missed for today.
  Future<bool> markIntake(String id, {required String status}) async {
    final intId = int.tryParse(id);
    if (intId == null) return false;

    try {
      final res = await _api.post(
        ApiEndpoints.markMedicineIntake(intId),
        {'status': status},
      );
      if (res.isSuccess) {
        // Refresh adherence data to reflect the change
        await fetchDailyAdherence();
        return true;
      }
      debugPrint('[MedicineService] Mark intake failed: ${res.message}');
    } catch (e) {
      debugPrint('[MedicineService] Mark intake error: $e');
    }
    return false;
  }

  /// Fetch daily adherence/progress from the API.
  Future<DailyAdherenceModel?> fetchDailyAdherence({int? patientId}) async {
    try {
      String url = ApiEndpoints.medicineAdherence;
      if (patientId != null) {
        url += '?patient_id=$patientId';
      }

      final res = await _api.get(url);
      if (res.isSuccess && res.data is Map<String, dynamic>) {
        _adherence = DailyAdherenceModel.fromJson(res.data as Map<String, dynamic>);
        notifyListeners();
        return _adherence;
      }
      debugPrint('[MedicineService] Adherence fetch failed: ${res.message}');
    } catch (e) {
      debugPrint('[MedicineService] Adherence error: $e');
    }
    return null;
  }
}
