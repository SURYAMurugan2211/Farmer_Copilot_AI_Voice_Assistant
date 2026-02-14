import 'package:flutter/material.dart';

class TextInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String language;
  final Function(String text) onTextQuery;

  const TextInputWidget({
    super.key,
    required this.controller,
    required this.language,
    required this.onTextQuery,
  });

  @override
  State<TextInputWidget> createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _sendQuery() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      widget.onTextQuery(text);
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Text(
            'Ask your farming question',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Text Input Field
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: _getHintText(widget.language),
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.all(16),
                suffixIcon: IconButton(
                  onPressed: _sendQuery,
                  icon: const Icon(Icons.send, color: Color(0xFF2E7D32)),
                ),
              ),
              onSubmitted: (_) => _sendQuery(),
              textInputAction: TextInputAction.send,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Send Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendQuery,
              icon: const Icon(Icons.send),
              label: const Text('Send Query'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Language: ${_getLanguageName(widget.language)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Example Questions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Example Questions:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._getExampleQuestions(widget.language).map(
                  (question) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: GestureDetector(
                      onTap: () {
                        widget.controller.text = question;
                      },
                      child: Text(
                        '• $question',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ta':
        return 'Tamil';
      case 'hi':
        return 'Hindi';
      case 'te':
        return 'Telugu';
      case 'kn':
        return 'Kannada';
      case 'ml':
        return 'Malayalam';
      default:
        return code.toUpperCase();
    }
  }

  String _getHintText(String language) {
    switch (language) {
      case 'ta':
        return 'உங்கள் விவசாய கேள்வியை இங்கே தட்டச்சு செய்யுங்கள்...';
      case 'hi':
        return 'अपना कृषि प्रश्न यहाँ टाइप करें...';
      case 'te':
        return 'మీ వ్యవసాయ ప్రశ్నను ఇక్కడ టైప్ చేయండి...';
      case 'kn':
        return 'ನಿಮ್ಮ ಕೃಷಿ ಪ್ರಶ್ನೆಯನ್ನು ಇಲ್ಲಿ ಟೈಪ್ ಮಾಡಿ...';
      case 'ml':
        return 'നിങ്ങളുടെ കൃഷി ചോദ്യം ഇവിടെ ടൈപ്പ് ചെയ്യുക...';
      default:
        return 'Type your farming question here...';
    }
  }

  List<String> _getExampleQuestions(String language) {
    switch (language) {
      case 'ta':
        return [
          'நெல் விளைவிக்க என்ன செய்ய வேண்டும்?',
          'தக்காளி செடியில் பூச்சி தாக்குதல் எப்படி கட்டுப்படுத்துவது?',
          'மண்சூன் காலத்தில் என்ன பயிர் செய்யலாம்?',
        ];
      case 'hi':
        return [
          'धान की खेती कैसे करें?',
          'टमाटर में कीट नियंत्रण कैसे करें?',
          'मानसून में कौन सी फसल उगाएं?',
        ];
      case 'te':
        return [
          'వరి వ్యవసాయం ఎలా చేయాలి?',
          'టమాటోలో కీటకాలను ఎలా నియంత్రించాలి?',
          'వర్షాకాలంలో ఏ పంట పండించాలి?',
        ];
      case 'kn':
        return [
          'ಅಕ್ಕಿ ಬೆಳೆ ಹೇಗೆ ಮಾಡಬೇಕು?',
          'ಟೊಮೇಟೊದಲ್ಲಿ ಕೀಟ ನಿಯಂತ್ರಣ ಹೇಗೆ?',
          'ಮಾನ್ಸೂನ್‌ನಲ್ಲಿ ಯಾವ ಬೆಳೆ ಬೆಳೆಯಬೇಕು?',
        ];
      case 'ml':
        return [
          'നെല്ല് കൃഷി എങ്ങനെ ചെയ്യാം?',
          'തക്കാളിയിൽ കീട നിയന്ത്രണം എങ്ങനെ?',
          'മൺസൂണിൽ ഏത് വിള വളർത്താം?',
        ];
      default:
        return [
          'How to grow rice in monsoon season?',
          'What fertilizer is best for tomatoes?',
          'How to control pests in wheat crop?',
          'When is the best time to plant corn?',
        ];
    }
  }
}