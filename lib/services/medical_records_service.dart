import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';
import '../models/medical_record_model.dart';
import 'api_service.dart';

class MedicalRecordsService extends ChangeNotifier {
  static final MedicalRecordsService _instance = MedicalRecordsService._internal();
  factory MedicalRecordsService() => _instance;
  MedicalRecordsService._internal();

  final ApiService _api = ApiService();
  List<MedicalRecordModel> _records = [];
  bool _isLoading = false;
  String? _error;

  /// Real API data only. Empty list means no records exist on the server.
  List<MedicalRecordModel> get records => _records;
  bool get isLoading => _isLoading;

  /// Non-null when the last fetch failed. Screens should show an error/retry
  /// state instead of any placeholder data.
  String? get errorMessage => _error;
  bool get hasError => _error != null;

  Future<List<MedicalRecordModel>> fetchRecords({String? category, int? patientId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = ApiEndpoints.records;
      final params = <String>[];
      if (patientId != null) {
        params.add('patient_id=$patientId');
      }
      if (category != null && category.isNotEmpty) {
        params.add('category=${Uri.encodeComponent(category)}');
      }
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final res = await _api.get(url);
      if (res.isSuccess && res.data is List) {
        final list = res.data as List;
        _records = list.map((item) {
          final map = item as Map<String, dynamic>;
          RecordCategory cat = RecordCategory.consultation;
          final catStr = map['category']?.toString().toLowerCase();
          if (catStr == 'lab_report' || catStr == 'labreport') {
            cat = RecordCategory.labReport;
          } else if (catStr == 'prescription') {
            cat = RecordCategory.prescription;
          } else if (catStr == 'allergy') {
            cat = RecordCategory.allergy;
          } else if (catStr == 'history') {
            cat = RecordCategory.history;
          }

          return MedicalRecordModel(
            id: map['id'].toString(),
            title: map['title'] ?? 'Medical Record',
            category: cat,
            date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
            doctorOrLab: map['doctor_or_lab'] ?? 'SehatAI Health Facility',
            description: map['description'] ?? '',
            diagnosis: map['diagnosis'],
            tags: [map['category']?.toString() ?? 'Record'],
          );
        }).toList();

        _isLoading = false;
        notifyListeners();
        return _records;
      }

      _error = res.message.isNotEmpty ? res.message : 'Failed to load medical records.';
    } catch (e) {
      debugPrint('[MedicalRecordsService] Fetch error: $e');
      _error = 'Failed to load medical records. Please check your connection and try again.';
    }

    // Real failure: expose the error, never fall back to demo data.
    _records = [];
    _isLoading = false;
    notifyListeners();
    return _records;
  }

  Future<bool> addRecord(MedicalRecordModel record) async {
    try {
      final res = await _api.post(
        ApiEndpoints.records,
        {
          'title': record.title,
          'category': record.category.name,
          'doctor_or_lab': record.doctorOrLab,
          'description': record.description,
          'diagnosis': record.diagnosis ?? '',
          'date': record.date.toIso8601String().split('T').first,
        },
      );

      if (res.isSuccess) {
        await fetchRecords();
        return true;
      }

      debugPrint('[MedicalRecordsService] Add record failed: ${res.message}');
      return false;
    } catch (e) {
      debugPrint('[MedicalRecordsService] Add record error: $e');
      return false;
    }
  }
}
