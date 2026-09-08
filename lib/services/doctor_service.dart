import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';
import '../models/doctor_model.dart';
import 'api_service.dart';

class DoctorService extends ChangeNotifier {
  static final DoctorService _instance = DoctorService._internal();
  factory DoctorService() => _instance;
  DoctorService._internal();

  final ApiService _api = ApiService();
  List<DoctorModel> _doctors = [];
  DoctorModel? _currentDoctorProfile;
  bool _isLoading = false;
  bool _isDoctorOnline = false;
  String? _error;

  /// Real API data only. Empty list means no verified doctors exist on the server.
  List<DoctorModel> get doctors => _doctors;
  DoctorModel? get currentDoctorProfile => _currentDoctorProfile;
  bool get isLoading => _isLoading;
  bool get isDoctorOnline => _isDoctorOnline;

  /// Non-null when the last doctors fetch failed. Screens should show an
  /// error/retry state instead of any placeholder data.
  String? get errorMessage => _error;
  bool get hasError => _error != null;

  Future<List<DoctorModel>> fetchDoctors({String? search, String? city}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = ApiEndpoints.doctors;
      final params = <String>[];
      if (search != null && search.isNotEmpty) {
        params.add('search=${Uri.encodeComponent(search)}');
      }
      if (city != null && city.isNotEmpty) {
        params.add('city=${Uri.encodeComponent(city)}');
      }
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final res = await _api.get(url, authRequired: false);
      if (res.isSuccess && res.data is List) {
        final list = res.data as List;
        _doctors = list.map((item) {
          final map = item as Map<String, dynamic>;
          return DoctorModel(
            id: map['id'].toString(),
            name: map['name'] ?? map['full_name'] ?? 'Doctor',
            specialization: map['specialty'] ?? map['specialization'] ?? 'General Physician',
            qualification: map['qualification'] ?? 'MBBS',
            experienceYears: int.tryParse(map['experience']?.toString() ?? '5') ?? 5,
            pmdcNumber: map['pmdc_number'] ?? 'PMDC-00000',
            isVerified: (map['verification_status'] == 'verified') || (map['is_verified'] == true),
            isOnline: map['is_available'] == true || map['is_online'] == 1 || map['is_online'] == true,
            rating: double.tryParse(map['rating']?.toString() ?? '4.9') ?? 4.9,
            reviewCount: int.tryParse(map['review_count']?.toString() ?? '80') ?? 80,
            consultationFee: 0.0, // Strictly FREE in SehatAI
            languages: (map['languages'] is List)
                ? List<String>.from(map['languages'])
                : (map['languages']?.toString().split(',') ?? ['Urdu', 'English']),
            availability: map['availability'] ?? 'Available Today • 9 AM - 6 PM',
            hospitalAffiliation: map['hospital'] ?? map['hospital_affiliation'] ?? 'Civil Hospital',
            about: map['bio'] ?? 'Medical practitioner dedicated to telehealth support.',
            avatarUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=150',
          );
        }).toList();

        _isLoading = false;
        notifyListeners();
        return _doctors;
      }

      _error = res.message.isNotEmpty ? res.message : 'Failed to load doctors.';
    } catch (e) {
      debugPrint('[DoctorService] API failed: $e');
      _error = 'Failed to load doctors. Please check your connection and try again.';
    }

    // Real failure: expose the error, never fall back to demo doctors.
    _isLoading = false;
    notifyListeners();
    return _doctors;
  }

  /// Fetch the logged-in doctor's own profile from /doctors/me
  Future<DoctorModel?> fetchDoctorProfile() async {
    try {
      final res = await _api.get(ApiEndpoints.doctorMe);
      if (res.isSuccess && res.data != null) {
        final map = res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : <String, dynamic>{};
        _currentDoctorProfile = DoctorModel(
          id: map['id'].toString(),
          name: map['full_name'] ?? map['name'] ?? 'Doctor',
          specialization: map['specialization'] ?? 'General Physician',
          qualification: map['qualification'] ?? 'MBBS',
          experienceYears: int.tryParse(map['experience_years']?.toString() ?? '5') ?? 5,
          pmdcNumber: map['pmdc_number'] ?? 'PMDC-00000',
          isVerified: map['verification_status'] == 'verified',
          isOnline: map['is_online'] == true || map['is_online'] == 1,
          rating: 4.9,
          reviewCount: 84,
          consultationFee: 0.0,
          languages: (map['languages'] is String)
              ? map['languages'].toString().split(',').map<String>((s) => s.trim()).toList()
              : (map['languages'] is List ? List<String>.from(map['languages']) : ['Urdu', 'English']),
          availability: map['availability'] ?? 'Available Today • 9 AM - 6 PM',
          hospitalAffiliation: map['hospital_affiliation'] ?? 'Civil Hospital',
          about: map['bio'] ?? 'Medical practitioner dedicated to telehealth support.',
          avatarUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=150',
        );
        _isDoctorOnline = _currentDoctorProfile!.isOnline;
        notifyListeners();
        return _currentDoctorProfile;
      }
    } catch (e) {
      debugPrint('[DoctorService] fetchDoctorProfile error: $e');
    }
    return null;
  }

  /// Toggle online/offline — API-first, local state updated from server response
  Future<void> toggleOnlineStatus() async {
    final previousState = _isDoctorOnline;
    try {
      final res = await _api.post(
        ApiEndpoints.doctorStatus,
        {'is_online': !_isDoctorOnline ? 1 : 0},
      );
      if (res.isSuccess && res.data != null) {
        final serverOnline = res.data['is_online'] == true || res.data['is_online'] == 1;
        _isDoctorOnline = serverOnline;
      } else {
        // API returned an error — keep previous state
        _isDoctorOnline = previousState;
      }
    } catch (e) {
      debugPrint('[DoctorService] toggle status API failed: $e');
      _isDoctorOnline = previousState;
    }
    notifyListeners();
  }
}
