import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../patient/screens/patient_main_screen.dart';
import '../../doctor/screens/doctor_main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pmdcController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedCity = 'Gilgit / Hunza Valley';
  UserRole _selectedRole = UserRole.patient;
  DateTime _selectedDob = DateTime(1996, 5, 14);
  bool _isLoading = false;

  final List<String> _pakistaniCities = [
    'Gilgit / Hunza Valley',
    'Skardu, Baltistan',
    'Quetta, Balochistan',
    'Khuzdar, Balochistan',
    'Gwadar, Balochistan',
    'Tharparkar, Sindh',
    'Sukkur, Sindh',
    'Swat / Mingora, KP',
    'Peshawar, KP',
    'Dera Ismail Khan, KP',
    'Muzaffarabad, AJK',
    'Mirpur, AJK',
    'Lahore, Punjab',
    'Multan, Punjab',
    'Karachi, Sindh',
    'Islamabad / Rawalpindi',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pmdcController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match!'),
            backgroundColor: AppColors.emergency,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final success = await AuthService().register(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
        city: _selectedCity,
        pmdcNumber: _selectedRole == UserRole.doctor ? _pmdcController.text.trim() : null,
        gender: _selectedGender,
        age: DateTime.now().year - _selectedDob.year,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          final isPendingDoc = _selectedRole == UserRole.doctor &&
              AuthService().verificationStatus != 'verified';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isPendingDoc
                    ? 'Doctor account created! Your PMDC license is pending Admin approval.'
                    : 'Account created successfully! Welcome to SehatAI.',
              ),
              backgroundColor: isPendingDoc ? AppColors.warning : AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => _selectedRole == UserRole.doctor
                  ? const DoctorMainScreen()
                  : const PatientMainScreen(),
            ),
            (route) => false,
          );
        } else {
          final errorMsg = AuthService().lastError ??
              'Registration failed. Please check your information.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.emergency,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create SehatAI Account'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join Pakistan\'s Digital Healthcare Network',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Instant access to AI symptom triage, verified doctors, and emergency response.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Role selection chips
                const Text(
                  'I am registering as:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRoleChip(UserRole.patient, 'Patient (مریض)'),
                    const SizedBox(width: 12),
                    _buildRoleChip(UserRole.doctor, 'Doctor (ڈاکٹر)'),
                  ],
                ),
                const SizedBox(height: 20),

                if (_selectedRole == UserRole.doctor) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Doctor accounts require valid PMDC/PMC license verification before taking consultations.',
                            style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomTextField(
                    label: 'PMDC Registration Number',
                    hintText: 'e.g. PMDC-12345-P',
                    controller: _pmdcController,
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) => v?.isEmpty ?? true ? 'Enter PMDC license' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Full Name
                CustomTextField(
                  label: 'Full Name',
                  hintText: 'Enter your full name',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => v?.isEmpty ?? true ? 'Enter your full name' : null,
                ),
                const SizedBox(height: 16),

                // Phone
                CustomTextField(
                  label: 'Mobile Phone Number',
                  hintText: 'e.g. 03001234567',
                  controller: _phoneController,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v?.isEmpty ?? true ? 'Enter phone number' : null,
                ),
                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  label: 'Email Address (Optional)',
                  hintText: 'e.g. name@domain.com',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // City / Area Dropdown
                const Text(
                  'City / District / Area',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCity,
                      items: _pakistaniCities.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(
                            city,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCity = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Gender & Date of Birth Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gender',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedGender,
                                items: ['Male', 'Female', 'Other'].map((g) {
                                  return DropdownMenuItem(
                                    value: g,
                                    child: Text(g, style: const TextStyle(fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedGender = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date of Birth',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDob,
                                firstDate: DateTime(1930),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _selectedDob = picked);
                              }
                            },
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_selectedDob.day}/${_selectedDob.month}/${_selectedDob.year}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  label: 'Password',
                  hintText: 'At least 6 characters',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                CustomTextField(
                  label: 'Confirm Password',
                  hintText: 'Re-enter password',
                  controller: _confirmPasswordController,
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 28),

                // Submit
                AppButton(
                  text: 'Register Account',
                  isLoading: _isLoading,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 20),

                // Back to login
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(UserRole role, String label) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
