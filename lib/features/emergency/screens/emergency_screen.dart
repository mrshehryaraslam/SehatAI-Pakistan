import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../services/ai_triage_service.dart';
import '../../../services/auth_service.dart';
import '../emergency_triage_mapper.dart';
import 'triage_result_screen.dart';

class EmergencyScreen extends StatefulWidget {
  final String? initialSymptom;
  const EmergencyScreen({super.key, this.initialSymptom});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  late final TextEditingController _symptomController;
  bool _isAnalyzing = false;

  final List<String> _quickSymptomChips = [
    'Chest pain & sweating (سینے میں درد)',
    'Difficulty breathing (سانس میں تنگی)',
    'High fever in child (بچے کو تیز بخار)',
    'Severe bleeding (شدید خون بہنا)',
    'Snake bite / Poison (سانپ کاٹنا / زہر)',
    'Acute abdominal pain (پیٹ کا شدید درد)',
    'Unconsciousness / Dizziness (بے ہوشی)',
  ];

  @override
  void initState() {
    super.initState();
    _symptomController = TextEditingController(text: widget.initialSymptom ?? '');
  }

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  /// Runs the REAL backend triage (POST /ai/triage). When the server cannot
  /// be reached, AiTriageService falls back to the offline deterministic rule
  /// engine — the result is never fabricated as a blind success.
  ///
  /// The deterministic critical-symptom safety rule in the mapper may only
  /// ESCALATE the risk level — critical red-flag symptoms always result in
  /// HIGH risk, independent of the AI verdict.
  Future<void> _analyzeSymptoms() async {
    final text = _symptomController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe what is happening or select a symptom chip.'),
          backgroundColor: AppColors.emergency,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    final aiResult = await AiTriageService().analyzeSymptoms(
      message: text,
      patientProfile: AuthService().currentUserOrNull,
    );

    if (!mounted) return;
    setState(() => _isAnalyzing = false);

    final triageResult = triageModelFromAiResult(aiResult, symptomText: text);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TriageResultScreen(triage: triageResult),
      ),
    );
  }

  /// Voice input is not implemented yet — the app honestly says so instead
  /// of fabricating a simulated transcription.
  void _toggleVoiceInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Voice input is not available yet — please type the symptoms in English, Urdu or Roman Urdu.'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.emergency_rounded, color: AppColors.emergency, size: 22),
            SizedBox(width: 8),
            Text(
              'Emergency Help',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.emergency,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emergency Banner
              AppCard(
                backgroundColor: AppColors.emergencyLight,
                borderColor: AppColors.emergency.withOpacity(0.3),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.emergency,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sos_rounded, color: AppColors.textWhite, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rapid Emergency Triage',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.emergencyDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'State the symptoms immediately for AI risk assessment & direct doctor routing.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.emergencyDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Main Question
              const Text(
                'What is happening?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'کیا تکلیف ہو رہی ہے؟ علامات بیان کریں۔',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Input box with voice button
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _symptomController,
                      hintText: 'Describe patient\'s symptoms in English, Urdu or Roman Urdu (e.g. chest pain, tez bukhar, vomiting)...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Voice Input Button (not yet implemented — honest state)
                        OutlinedButton.icon(
                          onPressed: _toggleVoiceInput,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(
                            Icons.mic_none_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            'Voice Input (بول کر بتائیں)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (_symptomController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20, color: AppColors.textMuted),
                            onPressed: () => setState(() => _symptomController.clear()),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Symptom Chips
              const Text(
                'Or select common emergency indicators:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickSymptomChips.map((chip) {
                  return ActionChip(
                    label: Text(
                      chip,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: () {
                      setState(() {
                        _symptomController.text = chip;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Analyze Button
              AppButton(
                text: 'Analyze Symptoms & Triage',
                variant: AppButtonVariant.danger,
                leadingIcon: Icons.auto_awesome_rounded,
                isLoading: _isAnalyzing,
                onPressed: _analyzeSymptoms,
              ),
              const SizedBox(height: 16),

              // Medical Safety Notice
              const Text(
                AppStrings.medicalDisclaimer,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
