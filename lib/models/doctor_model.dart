class DoctorModel {
  final String id;
  final String name;
  final String specialization;
  final String qualification;
  final int experienceYears;
  final String pmdcNumber;
  final bool isVerified;
  final bool isOnline;
  final double rating;
  final int reviewCount;
  final double consultationFee;
  final List<String> languages;
  final String availability;
  final String hospitalAffiliation;
  final String about;
  final String avatarUrl;

  const DoctorModel({
    required this.id,
    required this.name,
    required this.specialization,
    required this.qualification,
    required this.experienceYears,
    required this.pmdcNumber,
    this.isVerified = true,
    this.isOnline = true,
    this.rating = 4.9,
    this.reviewCount = 120,
    required this.consultationFee,
    required this.languages,
    required this.availability,
    required this.hospitalAffiliation,
    required this.about,
    required this.avatarUrl,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    List<String> langs;
    if (json['languages'] is List) {
      langs = List<String>.from(json['languages']);
    } else {
      langs = (json['languages']?.toString() ?? 'Urdu, English').split(',').map((s) => s.trim()).toList();
    }
    return DoctorModel(
      id: json['id']?.toString() ?? '0',
      name: json['name'] ?? json['full_name'] ?? 'Doctor',
      specialization: json['specialty'] ?? json['specialization'] ?? 'General Physician',
      qualification: json['qualification'] ?? 'MBBS',
      experienceYears: int.tryParse(json['experience']?.toString() ?? json['experience_years']?.toString() ?? '5') ?? 5,
      pmdcNumber: json['pmdc_number'] ?? 'PMDC-00000',
      isVerified: json['verification_status'] == 'verified' || json['is_verified'] == true,
      isOnline: json['is_available'] == true || json['is_online'] == 1 || json['is_online'] == true,
      rating: double.tryParse(json['rating']?.toString() ?? '4.9') ?? 4.9,
      reviewCount: int.tryParse(json['review_count']?.toString() ?? '80') ?? 80,
      consultationFee: 0.0, // Strictly FREE in SehatAI
      languages: langs,
      availability: json['availability'] ?? 'Available Today • 9 AM - 6 PM',
      hospitalAffiliation: json['hospital'] ?? json['hospital_affiliation'] ?? 'Civil Hospital',
      about: json['bio'] ?? json['about'] ?? 'Medical practitioner dedicated to telehealth support.',
      avatarUrl: json['avatar_url'] ?? 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=150',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialization': specialization,
      'qualification': qualification,
      'experience_years': experienceYears,
      'pmdc_number': pmdcNumber,
      'is_verified': isVerified,
      'is_online': isOnline,
      'rating': rating,
      'review_count': reviewCount,
      'languages': languages.join(', '),
      'availability': availability,
      'hospital_affiliation': hospitalAffiliation,
      'about': about,
      'avatar_url': avatarUrl,
    };
  }
}

