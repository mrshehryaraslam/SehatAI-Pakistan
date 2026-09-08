import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';
import 'api_service.dart';

class EmergencyService extends ChangeNotifier {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  final ApiService _api = ApiService();
  bool _isTriggering = false;
  bool get isTriggering => _isTriggering;

  /// Sends a real SOS alert to the server for the authenticated patient.
  ///
  /// Only data that is actually known is transmitted: the location is never
  /// fabricated on this side (the server stores NULL for missing coordinates
  /// instead of inventing a position).
  ///
  /// Returns {'success': false, ...} when the server rejected or could not be
  /// reached — the SOS was NOT recorded and callers must show an error state.
  Future<Map<String, dynamic>> sendSos({
    required String symptoms,
    String riskLevel = 'high',
    String? city,
    double? latitude,
    double? longitude,
  }) async {
    _isTriggering = true;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'symptoms': symptoms,
        'risk_level': riskLevel,
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      final res = await _api.post(ApiEndpoints.emergencySos, body);

      _isTriggering = false;
      notifyListeners();

      if (res.isSuccess && res.data is Map<String, dynamic>) {
        return {
          'success': true,
          'message': res.message,
          'data': res.data,
        };
      }

      // Real server rejection — never claim the SOS was created.
      return {
        'success': false,
        'message': res.message.isNotEmpty
            ? res.message
            : 'Emergency SOS could not be delivered. Please call 1122 directly.',
      };
    } catch (e) {
      debugPrint('[EmergencyService] SOS error: $e');

      _isTriggering = false;
      notifyListeners();

      return {
        'success': false,
        'message':
            'Emergency SOS failed: could not reach the server. Please call 1122 directly.',
      };
    }
  }

  /// Fetches the authenticated patient's own emergency alerts.
  ///
  /// The server enforces patient scoping — alerts belonging to other patients
  /// are never returned. Failures are surfaced as real errors.
  Future<Map<String, dynamic>> fetchMyAlerts() async {
    try {
      final res = await _api.get(ApiEndpoints.emergencyAlerts);

      if (res.isSuccess) {
        return {
          'success': true,
          'message': res.message,
          'data': res.data,
        };
      }

      return {
        'success': false,
        'message': res.message.isNotEmpty
            ? res.message
            : 'Emergency alerts could not be retrieved.',
      };
    } catch (e) {
      debugPrint('[EmergencyService] Fetch alerts error: $e');
      return {
        'success': false,
        'message': 'Emergency alerts could not be retrieved. Please try again.',
      };
    }
  }
}
