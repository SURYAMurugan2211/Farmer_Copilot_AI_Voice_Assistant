import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../config/theme.dart';
import '../models/chat_message.dart';

class ChatBubbleWidget extends StatefulWidget {
  final ChatMessage message;

  const ChatBubbleWidget({super.key, required this.message});

  @override
  State<ChatBubbleWidget> createState() => _ChatBubbleWidgetState();
}

class _ChatBubbleWidgetState extends State<ChatBubbleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  // Audio player for AI responses
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _audioLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    _slideAnim = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward();

    // Listen to audio player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _isPlaying = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (widget.message.audioUrl == null || widget.message.audioUrl!.isEmpty) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() => _audioLoading = true);
        await _audioPlayer.play(UrlSource(widget.message.audioUrl!));
        setState(() => _audioLoading = false);
      }
    } catch (e) {
      setState(() {
        _audioLoading = false;
        _isPlaying = false;
      });
      debugPrint('Audio play error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;

    if (msg.isLoading) return _buildLoadingBubble();

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(msg.isUser ? _slideAnim.value : -_slideAnim.value, 0),
          child: Opacity(
            opacity: _fadeAnim.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: msg.isUser ? 52 : 0,
          right: msg.isUser ? 0 : 52,
          bottom: 14,
        ),
        child: Align(
          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment:
                msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Main bubble
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  gradient: msg.isUser
                      ? AppTheme.userBubbleGradient
                      : msg.status == MessageStatus.error
                          ? LinearGradient(
                              colors: [
                                Colors.red.withValues(alpha: 0.12),
                                Colors.red.withValues(alpha: 0.06),
                              ],
                            )
                          : AppTheme.aiBubbleGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
                    bottomRight: Radius.circular(msg.isUser ? 4 : 20),
                  ),
                  border: Border.all(
                    color: msg.isUser
                        ? Colors.blue.withValues(alpha: 0.15)
                        : msg.status == MessageStatus.error
                            ? Colors.red.withValues(alpha: 0.2)
                            : AppTheme.accentGreen.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (msg.isUser ? Colors.blue : AppTheme.accentGreen)
                          .withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI label
                    if (!msg.isUser && msg.status != MessageStatus.error) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppTheme.accentGreen, AppTheme.emerald],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentGreen.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.eco_rounded,
                                color: Colors.white, size: 11),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'Farmer Copilot',
                            style: TextStyle(
                              color: AppTheme.accentGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Voice badge for voice messages
                    if (msg.type == MessageType.voice && msg.isUser) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_rounded,
                              size: 13, color: Colors.white.withValues(alpha: 0.5)),
                          const SizedBox(width: 5),
                          Text(
                            'Voice',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Message text
                    SelectableText(
                      msg.text ?? '',
                      style: TextStyle(
                        color: msg.isUser
                            ? Colors.white
                            : msg.status == MessageStatus.error
                                ? Colors.red.shade200
                                : AppTheme.textPrimary,
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),

                    // Audio playback button for AI responses
                    if (!msg.isUser &&
                        msg.audioUrl != null &&
                        msg.audioUrl!.isNotEmpty &&
                        msg.status != MessageStatus.error) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _playAudio,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isPlaying
                                  ? [
                                      AppTheme.orbRecording.withValues(alpha: 0.2),
                                      AppTheme.orbRecording.withValues(alpha: 0.1),
                                    ]
                                  : [
                                      AppTheme.accentGreen.withValues(alpha: 0.15),
                                      AppTheme.emerald.withValues(alpha: 0.08),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _isPlaying
                                  ? AppTheme.orbRecording.withValues(alpha: 0.3)
                                  : AppTheme.accentGreen.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_audioLoading)
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.accentGreen,
                                    backgroundColor:
                                        AppTheme.accentGreen.withValues(alpha: 0.1),
                                  ),
                                )
                              else
                                Icon(
                                  _isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.volume_up_rounded,
                                  size: 16,
                                  color: _isPlaying
                                      ? AppTheme.orbRecording
                                      : AppTheme.accentGreen,
                                ),
                              const SizedBox(width: 7),
                              Text(
                                _isPlaying ? 'Playing...' : '🔊 Listen',
                                style: TextStyle(
                                  color: _isPlaying
                                      ? AppTheme.orbRecording
                                      : AppTheme.accentGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Metadata tags
              if (!msg.isUser && msg.intent != null && msg.intent != 'welcome')
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (msg.intent != null && msg.intent!.isNotEmpty) ...[
                        _metaTag(msg.intent!, AppTheme.emerald),
                        const SizedBox(width: 5),
                      ],
                      if (msg.processingTime != null)
                        _metaTag(
                          '${msg.processingTime!.toStringAsFixed(1)}s',
                          AppTheme.gold,
                        ),
                      if (msg.language != null && msg.language != 'en') ...[
                        const SizedBox(width: 5),
                        _metaTag(msg.language!.toUpperCase(), AppTheme.tealAccent),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(right: 52, bottom: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: AppTheme.aiBubbleGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(
              color: AppTheme.accentGreen.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TypingDot(delay: 0),
              const SizedBox(width: 5),
              _TypingDot(delay: 150),
              const SizedBox(width: 5),
              _TypingDot(delay: 300),
              const SizedBox(width: 10),
              Text(
                'Thinking...',
                style: TextStyle(
                  color: AppTheme.textMuted.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Typing dot animation
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounce = Tween<double>(begin: 0, end: -7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _bounce.value),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentGreen.withValues(alpha: 0.5),
            ),
          ),
        );
      },
    );
  }
}
