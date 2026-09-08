import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sehat_ai_pakistan/models/user_model.dart';
import 'package:sehat_ai_pakistan/services/auth_service.dart';
import 'package:sehat_ai_pakistan/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3 Step 1 - UserModel & Auth Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      ApiService.setAuthToken(null);
    });

    test('UserModel serializes and deserializes full patient profile correctly', () {
      final user = const UserModel(
        id: '42',
        fullName: 'Zainab Bibi',
        email: 'zainab@example.com',
        phone: '03123456789',
        role: UserRole.patient,
        city: 'Skardu',
        bloodGroup: 'A+',
        age: 28,
        gender: 'Female',
        emergencyContact: '+92 333 9998887 (Brother)',
        allergies: 'Penicillin',
        chronicConditions: 'None',
        verificationStatus: 'verified',
      );

      final json = user.toJson();
      expect(json['id'], '42');
      expect(json['full_name'], 'Zainab Bibi');
      expect(json['role'], 'patient');
      expect(json['blood_group'], 'A+');
      expect(json['allergies'], 'Penicillin');

      final fromJsonUser = UserModel.fromJson(json);
      expect(fromJsonUser.id, '42');
      expect(fromJsonUser.fullName, 'Zainab Bibi');
      expect(fromJsonUser.role, UserRole.patient);
      expect(fromJsonUser.bloodGroup, 'A+');
      expect(fromJsonUser.allergies, 'Penicillin');
      expect(fromJsonUser.chronicConditions, 'None');
    });

    test('AuthService loads persisted session from SharedPreferences correctly', () async {
      final userJson = '{"id":"42","full_name":"Zainab Bibi","email":"zainab@example.com","phone":"03123456789","role":"patient","city":"Skardu","blood_group":"A+","age":28,"gender":"Female","emergency_contact":"+92 333 9998887","allergies":"Penicillin","chronic_conditions":"None","verification_status":"verified"}';
      
      SharedPreferences.setMockInitialValues({
        'sehat_auth_token': 'test_jwt_token_123',
        'sehat_user_data': userJson,
      });

      final auth = AuthService();
      final loaded = await auth.loadPersistedSession();

      expect(loaded, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.currentUser.fullName, 'Zainab Bibi');
      expect(auth.currentUser.phone, '03123456789');
      expect(auth.currentUser.bloodGroup, 'A+');
      expect(auth.currentUser.allergies, 'Penicillin');
      expect(ApiService.authToken, 'test_jwt_token_123');
    });

    test('AuthService logout clears session, token, and resets state', () async {
      SharedPreferences.setMockInitialValues({
        'sehat_auth_token': 'test_jwt_token_123',
        'sehat_user_data': '{"id":"42","full_name":"Zainab Bibi","role":"patient"}',
      });

      final auth = AuthService();
      await auth.loadPersistedSession();
      expect(auth.isAuthenticated, isTrue);

      await auth.logout();

      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUserOrNull, isNull);
      expect(ApiService.authToken, isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sehat_auth_token'), isNull);
      expect(prefs.getString('sehat_user_data'), isNull);
    });
  });
}
