import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../models/chat_message.dart';
import '../providers/app_providers.dart';
import '../providers/chat_provider.dart';
import '../services/audio_service.dart';
import '../widgets/chat_bubble_widget.dart';
import '../widgets/voice_orb_widget.dart';
import 'history_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'mandi_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final AudioService _audioService = AudioService();

  bool _showVoiceOverlay = false;
  OrbState _orbState = OrbState.idle;
  double _amplitude = 0.0;
  Timer? _amplitudeTimer;
  int _currentNavIndex = 0;

  late AnimationController _overlayController;
  late Animation<double> _overlayFade;

  @override
  void initState() {
    super.initState();
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _overlayFade = CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeOut,
    );

    // Auto-login guest if not authenticated
    Future.microtask(() {
      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        ref.read(currentUserProvider.notifier).loginAsGuest();
      }
    });

    // Add welcome message
    Future.microtask(() {
      ref.read(chatMessagesProvider.notifier).addWelcome();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _audioService.dispose();
    _amplitudeTimer?.cancel();
    _overlayController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendTextQuery([String? presetText]) {
    final text = presetText ?? _textController.text.trim();
    if (text.isEmpty) return;

    final language = ref.read(selectedLanguageProvider);
    final user = ref.read(currentUserProvider).value;

    if (presetText == null) _textController.clear();
    _focusNode.unfocus();

    ref.read(chatMessagesProvider.notifier).sendTextQuery(
          text: text,
          language: language,
          userId: user?.id,
        );

    _scrollToBottom();
  }

  Future<void> _toggleVoiceRecording() async {
    if (_orbState == OrbState.idle) {
      try {
        await _audioService.startRecording();
        setState(() {
          _showVoiceOverlay = true;
          _orbState = OrbState.listening;
        });
        _overlayController.forward();

        _amplitudeTimer = Timer.periodic(
          const Duration(milliseconds: 100),
          (_) async {
            if (_orbState == OrbState.listening) {
              final amp = await _audioService.getAmplitude();
              if (mounted) setState(() => _amplitude = amp);
            }
          },
        );
      } catch (e) {
        _showSnackbar('Microphone permission required');
      }
    } else if (_orbState == OrbState.listening) {
      _amplitudeTimer?.cancel();
      setState(() {
        _orbState = OrbState.processing;
        _amplitude = 0.0;
      });

      try {
        final path = await _audioService.stopRecording();
        if (path != null && path.isNotEmpty) {
          final language = ref.read(selectedLanguageProvider);
          final user = ref.read(currentUserProvider).value;

          await Future.delayed(const Duration(milliseconds: 500));
          _closeVoiceOverlay();

          ref.read(chatMessagesProvider.notifier).sendVoiceQuery(
                audioPath: path,
                language: language,
                userId: user?.id,
              );

          _scrollToBottom();
        }
      } catch (e) {
        _closeVoiceOverlay();
        _showSnackbar('Recording failed. Please try again.');
      }

      _audioService.setIdle();
    }
  }

  void _closeVoiceOverlay() {
    _overlayController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showVoiceOverlay = false;
          _orbState = OrbState.idle;
          _amplitude = 0.0;
        });
      }
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final selectedLanguage = ref.watch(selectedLanguageProvider);
    final supportedLanguages = ref.watch(supportedLanguagesProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            SafeArea(
              child: IndexedStack(
                index: _currentNavIndex,
                children: [
                  // ─── Chat Tab ───
                  Column(
                    children: [
                      _buildAppBar(selectedLanguage, supportedLanguages),
                      Expanded(child: _buildChatArea(messages)),
                      _buildInputBar(),
                    ],
                  ),
                  // ─── Mandi Tab ───
                  const MandiScreen(),
                  // ─── History Tab ───
                  const HistoryScreen(),
                  // ─── Settings Tab ───
                  const SettingsScreen(),
                ],
              ),
            ),
            if (_showVoiceOverlay) _buildVoiceOverlay(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar(String selectedLanguage, AsyncValue<dynamic> supportedLanguages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceColor.withValues(alpha: 0.95),
            AppTheme.surfaceColor.withValues(alpha: 0.85),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppTheme.accentGreen.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.accentGreen, AppTheme.emerald],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGreen.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Farmer Copilot',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: AppTheme.accentGreen.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentGreen,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentGreen.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'AI Ready • Speak or Type',
                      style: TextStyle(
                        color: AppTheme.textMuted.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Language picker
          supportedLanguages.when(
            data: (languages) => _buildLanguagePill(selectedLanguage, languages),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePill(String selected, dynamic languages) {
    String langName = selected.toUpperCase();
    if (languages is List) {
      for (var l in languages) {
        if (l.code == selected) {
          langName = l.name;
          break;
        }
      }
    }

    return GestureDetector(
      onTap: () => _showLanguageSheet(languages),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentGreen.withValues(alpha: 0.15),
              AppTheme.emerald.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getFlagEmoji(selected),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              langName,
              style: const TextStyle(
                color: AppTheme.accentGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more_rounded, color: AppTheme.accentGreen, size: 18),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(dynamic languages) {
    if (languages is! List) return;
    final selected = ref.read(selectedLanguageProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.15)),
        ),
        child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '🌐 Select Language',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: AppTheme.accentGreen.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Voice & text will work in your language',
                style: TextStyle(
                  color: AppTheme.textMuted.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              ...languages.map<Widget>((lang) {
                final isSelected = lang.code == selected;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentGreen.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: isSelected
                        ? Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Text(
                      _getFlagEmoji(lang.code),
                      style: const TextStyle(fontSize: 26),
                    ),
                    title: Text(
                      lang.name,
                      style: TextStyle(
                        color: isSelected ? AppTheme.accentGreen : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      lang.native,
                      style: TextStyle(
                        color: isSelected ? AppTheme.emerald : AppTheme.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    trailing: isSelected
                        ? Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accentGreen.withValues(alpha: 0.2),
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: AppTheme.accentGreen, size: 18),
                          )
                        : null,
                    onTap: () {
                      ref.read(selectedLanguageProvider.notifier).setLanguage(lang.code);
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildChatArea(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return _buildEmptyChat();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ChatBubbleWidget(message: messages[index]);
      },
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentGreen.withValues(alpha: 0.2),
                    AppTheme.emerald.withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: const Icon(
                Icons.agriculture_rounded,
                size: 44,
                color: AppTheme.accentGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'How can I help today?',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Voice or text — in any language',
              style: TextStyle(
                color: AppTheme.textMuted.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Quick suggestion chips
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _suggestionChip('🌿 Pest control for tomato'),
                _suggestionChip('🌾 Best rice varieties'),
                _suggestionChip('💧 Drip irrigation tips'),
                _suggestionChip('🌱 Soil health test'),
                _suggestionChip('📅 Crop calendar'),
                _suggestionChip('🐛 Organic pesticides'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(String label) {
    return GestureDetector(
      onTap: () => _sendTextQuery(label.replaceAll(RegExp(r'^[^\s]+ '), '')),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.cardColor.withValues(alpha: 0.8),
              AppTheme.cardLight.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surfaceColor.withValues(alpha: 0.95),
            AppTheme.surfaceColor,
          ],
        ),
        border: Border(
          top: BorderSide(color: AppTheme.accentGreen.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text input
            Expanded(
              child: Container(
                decoration: AppTheme.glassInput(),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: _getHintText(ref.read(selectedLanguageProvider)),
                          hintStyle: TextStyle(
                            color: AppTheme.textMuted.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _sendTextQuery(),
                        textInputAction: TextInputAction.send,
                        maxLines: 1,
                      ),
                    ),
                    // Send button
                    GestureDetector(
                      onTap: _sendTextQuery,
                      child: Container(
                        width: 42,
                        height: 42,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.accentGreen, AppTheme.emerald],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentGreen.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Mic button
            GestureDetector(
              onTap: _toggleVoiceRecording,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.cardLight,
                      AppTheme.cardColor,
                    ],
                  ),
                  border: Border.all(
                    color: AppTheme.accentGreen.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGreen.withValues(alpha: 0.2),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: AppTheme.accentGreen,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceOverlay() {
    return FadeTransition(
      opacity: _overlayFade,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBg.withValues(alpha: 0.97),
              const Color(0xFF0A150E).withValues(alpha: 0.98),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _amplitudeTimer?.cancel();
                        if (_orbState == OrbState.listening) {
                          _audioService.stopRecording();
                          _audioService.setIdle();
                        }
                        _closeVoiceOverlay();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: AppTheme.textSecondary, size: 22),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Title
              Text(
                _orbState == OrbState.listening
                    ? 'Listening...'
                    : _orbState == OrbState.processing
                        ? 'Thinking...'
                        : 'Tap to Speak',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: AppTheme.accentGreen.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Voice orb
              VoiceOrbWidget(
                orbState: _orbState,
                amplitude: _amplitude,
                size: 130,
                onTap: _toggleVoiceRecording,
              ),

              const SizedBox(height: 40),

              // Language indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getFlagEmoji(ref.read(selectedLanguageProvider)),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getLanguageName(ref.read(selectedLanguageProvider)),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Help text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _orbState == OrbState.listening
                      ? 'Speak clearly in your language.\nTap the orb again when done.'
                      : _orbState == OrbState.processing
                          ? 'Analyzing your question...'
                          : 'Ask about crops, pests, soil, irrigation\nor any farming question.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textMuted.withValues(alpha: 0.6),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: AppTheme.accentGreen.withValues(alpha: 0.08)),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (i) => setState(() => _currentNavIndex = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.accentGreen,
        unselectedItemColor: AppTheme.textMuted.withValues(alpha: 0.5),
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_rounded),
            activeIcon: Icon(Icons.analytics_rounded),
            label: 'Mandi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            activeIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getHintText(String lang) {
    switch (lang) {
      case 'ta': return 'உங்கள் கேள்வியை தட்டச்சு செய்யுங்கள்...';
      case 'hi': return 'अपना प्रश्न टाइप करें...';
      case 'te': return 'మీ ప్రశ్నను టైప్ చేయండి...';
      case 'kn': return 'ನಿಮ್ಮ ಪ್ರಶ್ನೆ ಟೈಪ್ ಮಾಡಿ...';
      case 'ml': return 'നിങ്ങളുടെ ചോദ്യം ടൈപ്പ് ചെയ്യുക...';
      default: return 'Ask about crops, pests, soil...';
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'ta': return 'Tamil (தமிழ்)';
      case 'hi': return 'Hindi (हिन्दी)';
      case 'te': return 'Telugu (తెలుగు)';
      case 'kn': return 'Kannada (ಕನ್ನಡ)';
      case 'ml': return 'Malayalam (മലയാളം)';
      default: return code.toUpperCase();
    }
  }

  String _getFlagEmoji(String code) {
    switch (code) {
      case 'en': return '🇺🇸';
      case 'ta': case 'hi': case 'te': case 'kn': case 'ml': return '🇮🇳';
      default: return '🌐';
    }
  }
}