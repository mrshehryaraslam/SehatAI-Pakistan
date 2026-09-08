import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';
import '../models/patient_brief_model.dart';
import '../models/care_plan_model.dart';
import 'api_service.dart';

/// Health Continuity Engine service — manages AI Patient Briefs and Care Plans.
/// Singleton + ApiService pattern. Real API data only: when generation or
/// fetching fails, callers receive null so they can show a real error/empty
/// state. Never fabricates demo care plans or briefs locally.
class HealthContinuityService extends ChangeNotifier {
  static final HealthContinuityService _instance = HealthContinuityService._internal();
  factory HealthContinuityService() => _instance;
  HealthContinuityService._internal();

  final ApiService _api = ApiService();

  PatientBriefModel? _currentBrief;
  CarePlanModel? _currentCarePlan;
  bool _isBriefLoading = false;
  bool _isCarePlanLoading = false;

  PatientBriefModel? get currentBrief => _currentBrief;
  CarePlanModel? get currentCarePlan => _currentCarePlan;
  bool get isBriefLoading => _isBriefLoading;
  bool get isCarePlanLoading => _isCarePlanLoading;

  // =================================================================
  // PATIENT BRIEF
  // =================================================================

  /// Fetch an existing AI Patient Brief for a consultation.
  Future<PatientBriefModel?> fetchPatientBrief(int consultationId) async {
    _isBriefLoading = true;
    notifyListeners();

    try {
      final res = await _api.get(
        ApiEndpoints.patientBriefByConsultation(consultationId),
        timeout: const Duration(seconds: 8),
      );

      if (res.isSuccess && res.data is Map<String, dynamic>) {
        _currentBrief = PatientBriefModel.fromJson(res.data as Map<String, dynamic>);
        _isBriefLoading = false;
        notifyListeners();
        return _currentBrief;
      }
    } catch (e) {
      debugPrint('[HealthContinuity] Fetch brief error: $e');
    }

    _isBriefLoading = false;
    notifyListeners();
    return null;
  }

  /// Trigger (re)generation of an AI Patient Brief via the backend.
  /// Returns null when the backend cannot generate the brief — no local demo fallback.
  Future<PatientBriefModel?> generatePatientBrief(
    int consultationId, {
    String language = 'english',
  }) async {
    _isBriefLoading = true;
    notifyListeners();

    try {
      final res = await _api.post(
        ApiEndpoints.patientBrief,
        {
          'consultation_id': consultationId,
          'language': language,
        },
        timeout: const Duration(seconds: 15),
      );

      if (res.isSuccess && res.data is Map<String, dynamic>) {
        _currentBrief = PatientBriefModel.fromJson(res.data as Map<String, dynamic>);
        _isBriefLoading = false;
        notifyListeners();
        return _currentBrief;
      }
    } catch (e) {
      debugPrint('[HealthContinuity] Generate brief error: $e');
    }

    // Real failure: expose absence of data, never a fabricated demo brief.
    _currentBrief = null;
    _isBriefLoading = false;
    notifyListeners();
    return null;
  }

  // =================================================================
  // CARE PLAN
  // =================================================================

  /// Fetch an existing AI Care Plan for a consultation.
  Future<CarePlanModel?> fetchCarePlan(int consultationId) async {
    _isCarePlanLoading = true;
    notifyListeners();

    try {
      final res = await _api.get(
        ApiEndpoints.carePlanByConsultation(consultationId),
        timeout: const Duration(seconds: 8),
      );

      if (res.isSuccess && res.data is Map<String, dynamic>) {
        _currentCarePlan = CarePlanModel.fromJson(res.data as Map<String, dynamic>);
        _isCarePlanLoading = false;
        notifyListeners();
        return _currentCarePlan;
      }
    } catch (e) {
      debugPrint('[HealthContinuity] Fetch care plan error: $e');
    }

    _isCarePlanLoading = false;
    notifyListeners();
    return null;
  }

  /// Trigger (re)generation of an AI Care Plan via the backend.
  /// Returns null when the backend cannot generate the plan — no local demo fallback.
  Future<CarePlanModel?> generateCarePlan(
    int consultationId, {
    String language = 'english',
  }) async {
    _isCarePlanLoading = true;
    notifyListeners();

    try {
      final res = await _api.post(
        ApiEndpoints.carePlan,
        {
          'consultation_id': consultationId,
          'language': language,
        },
        timeout: const Duration(seconds: 15),
      );

      if (res.isSuccess && res.data is Map<String, dynamic>) {
        _currentCarePlan = CarePlanModel.fromJson(res.data as Map<String, dynamic>);
        _isCarePlanLoading = false;
        notifyListeners();
        return _currentCarePlan;
      }
    } catch (e) {
      debugPrint('[HealthContinuity] Generate care plan error: $e');
    }

    // Real failure: expose absence of data, never a fabricated demo care plan.
    _currentCarePlan = null;
    _isCarePlanLoading = false;
    notifyListeners();
    return null;
  }
}
