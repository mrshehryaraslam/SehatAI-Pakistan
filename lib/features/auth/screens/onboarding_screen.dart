import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'AI Healthcare Assistance',
      'titleUrdu': 'مصنوعی ذہانت سے فوری رہنمائی',
      'description':
          'Describe your symptoms in English, Urdu, or Roman Urdu to receive immediate preliminary AI triage and clinical guidance.',
      'icon': Icons.psychology_rounded,
      'badge': 'Smart Triage',
      'color': AppColors.primary,
      'bgColor': AppColors.primaryContainer,
    },
    {
      'title': 'Connect With Doctors',
      'titleUrdu': 'ماہر ڈاکٹروں سے آن لائن مشورہ',
      'description':
          'Consult with PMDC registered doctors and specialists remotely from the comfort of your home in remote and rural areas.',
      'icon': Icons.medical_services_rounded,
      'badge': 'PMDC Verified',
      'color': AppColors.secondary,
      'bgColor': AppColors.secondaryContainer,
    },
    {
      'title': 'Emergency Assistance',
      'titleUrdu': 'ہنگامی طبی امداد اور ایمبولینس',
      'description':
          'High-risk critical symptoms are detected instantly and escalated to emergency doctors and local health rescue response.',
      'icon': Icons.emergency_rounded,
      'badge': '24/7 Rapid Response',
      'color': AppColors.emergency,
      'bgColor': AppColors.emergencyLight,
    },
  ];

  void _onNext() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentIndex < _pages.length - 1)
            TextButton(
              onPressed: _goToLogin,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration Circle
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: page['bgColor'] as Color,
                            border: Border.all(
                              color: (page['color'] as Color).withOpacity(0.25),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              page['icon'] as IconData,
                              size: 80,
                              color: page['color'] as Color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (page['color'] as Color).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            page['badge'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: page['color'] as Color,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Title
                        Text(
                          page['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Urdu Title
                        Text(
                          page['titleUrdu'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Description
                        Text(
                          page['description'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom Controls
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Next / Get Started Button
                  AppButton(
                    text: _currentIndex == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    trailingIcon: _currentIndex == _pages.length - 1
                        ? Icons.check_circle_outline
                        : Icons.arrow_forward_rounded,
                    onPressed: _onNext,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
