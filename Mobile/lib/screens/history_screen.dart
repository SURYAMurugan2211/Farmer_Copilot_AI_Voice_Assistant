import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import '../config/theme.dart';
import '../providers/app_providers.dart';
import '../providers/chat_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _error;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(currentUserProvider).value;
      final userId = user?.id ?? 5;

      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);
      final baseUrl = ref.read(apiServiceProvider).baseUrl;
      final response = await dio.get('$baseUrl/api/mobile/history/$userId?limit=50');

      if (response.data['success'] == true) {
        setState(() {
          _history = List<Map<String, dynamic>>.from(response.data['history'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Could not load history. Check server connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auto-refresh when new messages appear in chat
    final messages = ref.watch(chatMessagesProvider);
    if (messages.length != _lastMessageCount && messages.isNotEmpty) {
      _lastMessageCount = messages.length;
      // Only reload if there are AI messages (query completed)
      final aiMessages = messages.where((m) => !m.isUser && !m.isLoading).length;
      if (aiMessages > 0) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _loadHistory();
        });
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentGreen.withValues(alpha: 0.12),
                    ),
                    child: const Icon(Icons.history_rounded,
                        color: AppTheme.accentGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'History',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Your past farming queries',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _loadHistory,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentGreen.withValues(alpha: 0.12),
                        border: Border.all(
                          color: AppTheme.accentGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: AppTheme.accentGreen,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Stats bar
            if (_history.isNotEmpty && !_isLoading)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentGreen.withValues(alpha: 0.08),
                      AppTheme.emerald.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('${_history.length}', 'Queries'),
                    Container(
                      width: 1,
                      height: 24,
                      color: AppTheme.accentGreen.withValues(alpha: 0.2),
                    ),
                    _statItem(
                      '${_history.where((h) => h['query_type'] == 'voice').length}',
                      'Voice',
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: AppTheme.accentGreen.withValues(alpha: 0.2),
                    ),
                    _statItem(
                      '${_history.where((h) => h['query_type'] == 'text').length}',
                      'Text',
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 4),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : _error != null
                      ? _buildError()
                      : _history.isEmpty
                          ? _buildEmpty()
                          : _buildHistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.accentGreen,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textMuted.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: AppTheme.accentGreen,
              strokeWidth: 3,
              backgroundColor: AppTheme.accentGreen.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading history...',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.cloud_off_rounded,
                  size: 34, color: Colors.red.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.7), fontSize: 14),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _loadHistory,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentGreen, AppTheme.emerald],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentGreen.withValues(alpha: 0.12),
                  AppTheme.emerald.withValues(alpha: 0.06),
                ],
              ),
            ),
            child: const Icon(Icons.forum_outlined,
                size: 40, color: AppTheme.accentGreen),
          ),
          const SizedBox(height: 20),
          const Text(
            'No conversations yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask your first farming question!\nYour history will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted.withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppTheme.accentGreen,
      backgroundColor: AppTheme.surfaceColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          return _buildHistoryCard(item, index);
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, int index) {
    final originalText = item['original_text'] ?? '';
    final responseText = item['response_text'] ?? '';
    final language = (item['language'] ?? 'en').toString().toUpperCase();
    final intent = item['intent'] ?? '';
    final processingTime = item['processing_time'];
    final queryType = item['query_type'] ?? 'text';
    final createdAt = item['created_at'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.glassCard(opacity: 0.08),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: queryType == 'voice'
                    ? [const Color(0xFF7C3AED), const Color(0xFF5B21B6)]
                    : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
              ),
            ),
            child: Icon(
              queryType == 'voice' ? Icons.mic_rounded : Icons.edit_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            originalText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                _miniChip(language, AppTheme.accentGreen),
                const SizedBox(width: 6),
                if (intent.isNotEmpty) ...[
                  _miniChip(intent, AppTheme.emerald),
                  const SizedBox(width: 6),
                ],
                if (processingTime != null)
                  _miniChip(
                    '${processingTime is double ? processingTime.toStringAsFixed(1) : processingTime}s',
                    AppTheme.gold,
                  ),
              ],
            ),
          ),
          iconColor: AppTheme.textMuted,
          collapsedIconColor: AppTheme.textMuted,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentGreen.withValues(alpha: 0.06),
                    AppTheme.emerald.withValues(alpha: 0.03),
                  ],
                ),
                border: Border(
                  top: BorderSide(color: AppTheme.accentGreen.withValues(alpha: 0.1)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accentGreen.withValues(alpha: 0.15),
                        ),
                        child: const Icon(Icons.eco_rounded,
                            size: 14, color: AppTheme.accentGreen),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI Response',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentGreen,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    responseText,
                    style: TextStyle(
                      color: AppTheme.textPrimary.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  if (item['response_audio_url'] != null &&
                      item['response_audio_url'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        // Play audio using a temporary player
                        final player = AudioPlayer();
                        player.play(UrlSource(item['response_audio_url']));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.accentGreen.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.volume_up_rounded,
                                color: AppTheme.accentGreen, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Play Response',
                              style: TextStyle(
                                color: AppTheme.accentGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (createdAt.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      createdAt,
                      style: TextStyle(
                        color: AppTheme.textMuted.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}