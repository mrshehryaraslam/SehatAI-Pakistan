import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';
import '../models/prescription_model.dart';
import 'api_service.dart';

class PrescriptionService extends ChangeNotifier {
  static final PrescriptionService _instance = PrescriptionService._internal();
  factory PrescriptionService() => _instance;
  PrescriptionService._internal();

  final ApiService _api = ApiService();
  List<PrescriptionModel> _prescriptions = [];
  bool _isLoading = false;
  String? _error;

  /// Real API data only. Empty list means no prescriptions exist on the server.
  List<PrescriptionModel> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;

  /// Non-null when the last fetch failed. Screens should show an error/retry
  /// state instead of any placeholder data.
  String? get errorMessage => _error;
  bool get hasError => _error != null;

  Future<List<PrescriptionModel>> fetchPrescriptions({int? patientId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = ApiEndpoints.prescriptions;
      if (patientId != null) {
        url += '?patient_id=$patientId';
      }

      final res = await _api.get(url);
      if (res.isSuccess && res.data is List) {
        final list = res.data as List;
        _prescriptions = list
            .map((item) => PrescriptionModel.fromJson(item as Map<String, dynamic>))
            .toList();

        _isLoading = false;
        notifyListeners();
        return _prescriptions;
      }

      _error = res.message.isNotEmpty ? res.message : 'Failed to load prescriptions.';
    } catch (e) {
      debugPrint('[PrescriptionService] Fetch error: $e');
      _error = 'Failed to load prescriptions. Please check your connection and try again.';
    }

    // Real failure: expose the error, never fall back to demo data.
    _prescriptions = [];
    _isLoading = false;
    notifyListeners();
    return _prescriptions;
  }

  Future<bool> createPrescription({
    required int patientId,
    int? consultationId,
    required List<PrescriptionItem> medicines,
  }) async {
    try {
      final res = await _api.post(
        ApiEndpoints.prescriptions,
        {
          'patient_id': patientId,
          'consultation_id': consultationId,
          'medicines': medicines.map((m) => m.toJson()).toList(),
        },
      );

      if (res.isSuccess) {
        await fetchPrescriptions();
        return true;
      }
    } catch (e) {
      debugPrint('[PrescriptionService] Create error: $e');
    }

    return false;
  }
}
