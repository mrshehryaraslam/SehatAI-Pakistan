import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/doctor_model.dart';
import '../models/consultation_model.dart';
import '../models/medicine_reminder_model.dart';
import '../models/medical_record_model.dart';
import '../models/prescription_model.dart';
import 'auth_service.dart';
import 'doctor_service.dart';
import 'consultation_service.dart';
import 'medicine_service.dart';
import 'medical_records_service.dart';
import 'prescription_service.dart';

/// Compatibility facade over the real API-backed services.
///
/// NOTE: This class must NEVER fabricate or fall back to demo/mock data.
/// All getters return whatever the real services hold (possibly an empty
/// list, which screens render as a proper empty state).
class MockDataService extends ChangeNotifier {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  /// Prescriptions captured by the OCR scanner (local working storage only).
  final List<PrescriptionModel> _scannedPrescriptions = [];

  UserModel get currentUser => AuthService().currentUser;

  List<DoctorModel> get doctors => DoctorService().doctors;
  List<ConsultationModel> get consultations => ConsultationService().consultations;
  List<MedicineReminderModel> get medicines => MedicineService().medicines;
  List<MedicalRecordModel> get records => MedicalRecordsService().records;
  List<PrescriptionModel> get prescriptions => PrescriptionService().prescriptions;
  bool get isDoctorOnline => DoctorService().isDoctorOnline;

  void setUserRole(UserRole role) {
    notifyListeners();
  }

  void toggleDoctorOnlineStatus() {
    DoctorService().toggleOnlineStatus();
    notifyListeners();
  }

  Future<bool> addMedicine(MedicineReminderModel reminder) {
    return MedicineService().addMedicine(reminder);
  }

  void addPrescription(PrescriptionModel prescription) {
    _scannedPrescriptions.insert(0, prescription);
    notifyListeners();
  }
}
