import '../models/user_model.dart';

class MockPatients {
  static const UserModel currentPatient = UserModel(
    id: 'p_101',
    fullName: 'Ali Raza Khan',
    email: 'aliraza.khan@gmail.com',
    phone: '03001234567',
    role: UserRole.patient,
    city: 'Gilgit / Hunza Valley',
    bloodGroup: 'B+',
    age: 34,
    gender: 'Male',
    emergencyContact: '+92 321 9876543 (Brother - Tariq)',
    avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
  );

  static const List<UserModel> samplePatients = [
    UserModel(
      id: 'p_101',
      fullName: 'Ali Raza Khan',
      email: 'aliraza.khan@gmail.com',
      phone: '03001234567',
      role: UserRole.patient,
      city: 'Gilgit / Hunza Valley',
      bloodGroup: 'B+',
      age: 34,
      gender: 'Male',
      emergencyContact: '+92 321 9876543 (Brother)',
    ),
    UserModel(
      id: 'p_102',
      fullName: 'Zainab Bibi',
      email: 'zainab.bibi@yahoo.com',
      phone: '03123456789',
      role: UserRole.patient,
      city: 'Tharparkar, Sindh',
      bloodGroup: 'O+',
      age: 28,
      gender: 'Female',
      emergencyContact: '+92 333 4567890 (Husband)',
    ),
    UserModel(
      id: 'p_103',
      fullName: 'Muhammad Usman',
      email: 'usman.quetta@gmail.com',
      phone: '03337890123',
      role: UserRole.patient,
      city: 'Khuzdar, Balochistan',
      bloodGroup: 'A+',
      age: 45,
      gender: 'Male',
      emergencyContact: '+92 314 9988776 (Son)',
    ),
    UserModel(
      id: 'p_104',
      fullName: 'Fatima Gul',
      email: 'fatima.gul@gmail.com',
      phone: '03456789012',
      role: UserRole.patient,
      city: 'Swat, KP',
      bloodGroup: 'AB+',
      age: 52,
      gender: 'Female',
      emergencyContact: '+92 300 5544332 (Daughter)',
    ),
  ];
}
