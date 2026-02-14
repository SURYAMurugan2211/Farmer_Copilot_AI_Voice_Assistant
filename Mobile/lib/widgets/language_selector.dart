import 'package:flutter/material.dart';
import '../models/api_models.dart';

class LanguageSelector extends StatelessWidget {
  final List<Language> languages;
  final String selectedLanguage;
  final Function(String) onLanguageChanged;

  const LanguageSelector({
    super.key,
    required this.languages,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.language,
            color: Colors.green.shade600,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Language:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedLanguage,
                isExpanded: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.green.shade600,
                ),
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 14,
                ),
                items: languages.map((Language language) {
                  return DropdownMenuItem<String>(
                    value: language.code,
                    child: Row(
                      children: [
                        Text(
                          _getFlagEmoji(language.code),
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${language.name} (${language.native})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onLanguageChanged(newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFlagEmoji(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇺🇸';
      case 'ta':
        return '🇮🇳';
      case 'hi':
        return '🇮🇳';
      case 'te':
        return '🇮🇳';
      case 'kn':
        return '🇮🇳';
      case 'ml':
        return '🇮🇳';
      default:
        return '🌐';
    }
  }
}