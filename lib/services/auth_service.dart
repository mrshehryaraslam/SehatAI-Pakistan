import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_endpoints.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _keyToken = 'sehat_auth_token';
  static const String _keyUser = 'sehat_user_data';

  final ApiService _api = ApiService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _verificationStatus;
  String? _lastError;

  UserModel get currentUser =>
      _currentUser ??
      const UserModel(
        id: '0',
        fullName: 'Guest User',
        email: '',
        phone: '',
        role: UserRole.patient,
        city: 'Gilgit',
      );

  UserModel? get currentUserOrNull => _currentUser;
  bool get isLoading => _isLoading;
  String? get verificationStatus => _verificationStatus;
  String? get lastError => _lastError;
  bool get isAuthenticated => _currentUser != null && ApiService.authToken != null;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  /// Load session from SharedPreferences on app startup
  Future<bool> loadPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      final userJson = prefs.getString(_keyUser);

      if (token != null && token.isNotEmpty && userJson != null && userJson.isNotEmpty) {
        ApiService.setAuthToken(token);
        final Map<String, dynamic> decoded = jsonDecode(userJson);
        _currentUser = UserModel.fromJson(decoded);
        _verificationStatus = _currentUser?.verificationStatus;
        notifyListeners();

        // Refresh latest profile data from MySQL in background
        refreshProfile();
        return true;
      }
    } catch (e) {
      debugPrint('[AuthService] Error loading persisted session: $e');
    }
    return false;
  }

  /// Save session to SharedPreferences
  Future<void> _saveSession(String token, UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('[AuthService] Error saving session: $e');
    }
  }

  /// Authenticate against live PHP/MySQL backend
  Future<bool> login(String identifier, String password) async {
    _setLoading(true);
    _lastError = null;

    try {
      final res = await _api.post(
        ApiEndpoints.login,
        {
          'identifier': identifier.trim(),
          'password': password,
        },
        authRequired: false,
      );

      if (res.isSuccess && res.data != null) {
        final userData = res.data['user'];
        final profileData = res.data['profile'];
        final token = res.data['token']?.toString();

        if (token == null || token.isEmpty) {
          _lastError = 'Invalid server response: No token received.';
          _setLoading(false);
          return false;
        }

        ApiService.setAuthToken(token);

        _verificationStatus = profileData?['verification_status']?.toString() ??
            userData['verification_status']?.toString() ??
            'verified';

        _currentUser = UserModel.fromJson(
          userData is Map<String, dynamic> ? userData : <String, dynamic>{},
          profile: profileData is Map<String, dynamic> ? profileData : null,
        );

        await _saveSession(token, _currentUser!);

        _setLoading(false);
        return true;
      } else {
        _lastError = res.message.isNotEmpty ? res.message : 'Invalid credentials. Please verify your phone/email and password.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint('[AuthService] Login API error: $e');
      _lastError = 'Network error: Could not reach SehatAI server.';
      _setLoading(false);
      return false;
    }
  }

  /// Register new user in live MySQL database
  Future<bool> register({
    required String fullName,
    required String phone,
    required String password,
    required UserRole role,
    String? email,
    String? city,
    String? pmdcNumber,
    String? specialization,
    String? qualification,
    int? experienceYears,
    int? age,
    String? gender,
    String? bloodGroup,
    String? emergencyContact,
    String? allergies,
    String? chronicConditions,
  }) async {
    _setLoading(true);
    _lastError = null;

    final payload = <String, dynamic>{
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'email': email?.trim() ?? '',
      'password': password,
      'role': role == UserRole.doctor ? 'doctor' : 'patient',
      'city': city ?? 'Gilgit',
    };

    if (role == UserRole.doctor) {
      payload['pmdc_number'] = pmdcNumber ?? 'PMDC-${DateTime.now().millisecondsSinceEpoch % 100000}';
      payload['specialization'] = specialization ?? 'General Physician';
      payload['qualification'] = qualification ?? 'MBBS';
      payload['experience_years'] = experienceYears ?? 3;
    } else {
      payload['age'] = age ?? 30;
      payload['gender'] = gender ?? 'Male';
      payload['blood_group'] = bloodGroup ?? 'B+';
      payload['emergency_contact'] = emergencyContact ?? '';
      if (allergies != null) payload['allergies'] = allergies;
      if (chronicConditions != null) payload['chronic_conditions'] = chronicConditions;
    }

    try {
      final res = await _api.post(
        ApiEndpoints.register,
        payload,
        authRequired: false,
      );

      if (res.isSuccess && res.data != null) {
        final userData = res.data['user'];
        final token = res.data['token']?.toString();

        if (token == null || token.isEmpty) {
          _lastError = 'Registration succeeded but no session token was provided.';
          _setLoading(false);
          return false;
        }

        ApiService.setAuthToken(token);

        _verificationStatus = res.data['verification_status']?.toString() ??
            (role == UserRole.doctor ? 'pending' : 'verified');

        final profileMap = <String, dynamic>{
          'age': age,
          'gender': gender,
          'blood_group': bloodGroup,
          'emergency_contact': emergencyContact,
          'allergies': allergies,
          'chronic_conditions': chronicConditions,
          'verification_status': _verificationStatus,
        };

        _currentUser = UserModel.fromJson(
          userData is Map<String, dynamic> ? userData : <String, dynamic>{},
          profile: profileMap,
        );

        await _saveSession(token, _currentUser!);

        _setLoading(false);
        return true;
      } else {
        _lastError = res.message.isNotEmpty ? res.message : 'Registration failed. Please check your details.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      debugPrint('[AuthService] Register API error: $e');
      _lastError = 'Network error: Could not connect to SehatAI server.';
      _setLoading(false);
      return false;
    }
  }

  /// Fetch fresh profile data from MySQL using current Bearer token
  Future<bool> refreshProfile() async {
    if (ApiService.authToken == null) return false;

    try {
      final res = await _api.get(ApiEndpoints.me, authRequired: true);
      if (res.isSuccess && res.data != null) {
        final userData = res.data['user'];
        final profileData = res.data['profile'];

        if (userData is Map<String, dynamic>) {
          _currentUser = UserModel.fromJson(
            userData,
            profile: profileData is Map<String, dynamic> ? profileData : null,
          );
          _verificationStatus = profileData?['verification_status']?.toString() ??
              userData['verification_status']?.toString() ??
              _currentUser?.verificationStatus;

          if (ApiService.authToken != null && _currentUser != null) {
            await _saveSession(ApiService.authToken!, _currentUser!);
          }
          notifyListeners();
          return true;
        }
      } else if (res.statusCode == 401) {
        // Token expired or invalid
        await logout();
      }
    } catch (e) {
      debugPrint('[AuthService] refreshProfile error: $e');
    }
    return false;
  }

  /// Sign out and clear stored session & token
  Future<void> logout() async {
    ApiService.setAuthToken(null);
    _currentUser = null;
    _verificationStatus = null;
    _lastError = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
    } catch (e) {
      debugPrint('[AuthService] Error during logout cleanup: $e');
    }

    notifyListeners();
  }
}
