import '../models/prescription_model.dart';

class MockPrescriptions {
  static final List<PrescriptionModel> samplePrescriptions = [
    PrescriptionModel(
      id: 'rx_01',
      doctorName: 'Dr. Ayesha Siddiqui',
      doctorSpecialty: 'Internal Medicine',
      date: DateTime.now().subtract(const Duration(days: 3)),
      isVerifiedByUser: true,
      items: const [
        PrescriptionItem(
          medicineName: 'Panadol (Paracetamol)',
          dosage: '500 mg Tablet',
          frequency: '3 times daily (After meals)',
          duration: '5 Days',
          instructions: 'Take with full glass of water. Do not exceed 4000mg/day.',
        ),
        PrescriptionItem(
          medicineName: 'Augmentin (Amoxicillin/Clavulanate)',
          dosage: '625 mg Tablet',
          frequency: 'Twice daily (Every 12 hours)',
          duration: '7 Days',
          instructions: 'Complete full course even if fever resolves.',
        ),
        PrescriptionItem(
          medicineName: 'Risek (Omeprazole)',
          dosage: '20 mg Capsule',
          frequency: 'Once daily (Before breakfast)',
          duration: '7 Days',
          instructions: 'Take 30 minutes before first meal of the day.',
        ),
      ],
    ),
    PrescriptionModel(
      id: 'rx_02',
      doctorName: 'Dr. Farhan Qureshi',
      doctorSpecialty: 'Cardiology',
      date: DateTime.now().subtract(const Duration(days: 28)),
      isVerifiedByUser: true,
      items: const [
        PrescriptionItem(
          medicineName: 'Concor (Bisoprolol)',
          dosage: '2.5 mg Tablet',
          frequency: 'Once daily (Morning)',
          duration: '30 Days',
          instructions: 'Monitor blood pressure weekly. Do not stop abruptly.',
        ),
        PrescriptionItem(
          medicineName: 'Ascard (Aspirin)',
          dosage: '75 mg Tablet',
          frequency: 'Once daily (After lunch)',
          duration: '30 Days',
          instructions: 'Take strictly after meals to prevent gastric irritation.',
        ),
      ],
    ),
  ];
}
