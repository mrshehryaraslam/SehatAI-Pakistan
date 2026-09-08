import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum AppLanguage { english, urdu, romanUrdu }

class LanguageSelector extends StatelessWidget {
  final AppLanguage selectedLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const LanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLangOption(AppLanguage.english, 'English'),
          _buildLangOption(AppLanguage.romanUrdu, 'Roman Urdu'),
          _buildLangOption(AppLanguage.urdu, 'اردو'),
        ],
      ),
    );
  }

  Widget _buildLangOption(AppLanguage lang, String label) {
    final isSelected = selectedLanguage == lang;
    return GestureDetector(
      onTap: () => onLanguageChanged(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
