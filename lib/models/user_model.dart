enum UserRole { patient, doctor, admin }

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final String? city;
  final String? bloodGroup;
  final int? age;
  final String? gender;
  final String? emergencyContact;
  final String? allergies;
  final String? chronicConditions;
  final String? verificationStatus;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.city,
    this.bloodGroup,
    this.age,
    this.gender,
    this.emergencyContact,
    this.allergies,
    this.chronicConditions,
    this.verificationStatus,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? profile}) {
    UserRole role = UserRole.patient;
    final roleStr = (json['role'] ?? 'patient').toString().toLowerCase();
    if (roleStr == 'doctor') role = UserRole.doctor;
    if (roleStr == 'admin') role = UserRole.admin;

    return UserModel(
      id: json['id']?.toString() ?? '0',
      fullName: json['full_name'] ?? json['name'] ?? 'User',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: role,
      city: json['city'] ?? profile?['city'] ?? 'Gilgit',
      bloodGroup: profile?['blood_group']?.toString() ?? json['blood_group']?.toString(),
      age: profile?['age'] != null
          ? int.tryParse(profile!['age'].toString())
          : (json['age'] != null ? int.tryParse(json['age'].toString()) : null),
      gender: profile?['gender']?.toString() ?? json['gender']?.toString(),
      emergencyContact: profile?['emergency_contact']?.toString() ?? json['emergency_contact']?.toString(),
      allergies: profile?['allergies']?.toString() ?? json['allergies']?.toString(),
      chronicConditions: profile?['chronic_conditions']?.toString() ?? json['chronic_conditions']?.toString(),
      verificationStatus: profile?['verification_status']?.toString() ?? json['verification_status']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role.name,
      'city': city,
      'blood_group': bloodGroup,
      'age': age,
      'gender': gender,
      'emergency_contact': emergencyContact,
      'allergies': allergies,
      'chronic_conditions': chronicConditions,
      'verification_status': verificationStatus,
      'avatar_url': avatarUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    String? city,
    String? bloodGroup,
    int? age,
    String? gender,
    String? emergencyContact,
    String? allergies,
    String? chronicConditions,
    String? verificationStatus,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      city: city ?? this.city,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
