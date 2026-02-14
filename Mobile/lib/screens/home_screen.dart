import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/voice_input_widget.dart';
import '../widgets/text_input_widget.dart';
import '../widgets/language_selector.dart';
import '../widgets/query_response_widget.dart';
import '../widgets/connection_status_widget.dart';
import 'settings_screen.dart';
import 'history_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQuery = ref.watch(currentQueryProvider);
    final selectedLanguage = ref.watch(selectedLanguageProvider);
    final supportedLanguages = ref.watch(supportedLanguagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🌾 Farmer Copilot'),
        actions: [
          const ConnectionStatusWidget(),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.mic), text: 'Voice'),
            Tab(icon: Icon(Icons.keyboard), text: 'Text'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Language Selector
          Container(
            padding: const EdgeInsets.all(16),
            child: supportedLanguages.when(
              data: (languages) => LanguageSelector(
                languages: languages,
                selectedLanguage: selectedLanguage,
                onLanguageChanged: (language) {
                  ref.read(selectedLanguageProvider.notifier).setLanguage(language);
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error loading languages: $error'),
            ),
          ),
          
          // Input Section
          Expanded(
            flex: 1,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Voice Input Tab
                VoiceInputWidget(
                  language: selectedLanguage,
                  onVoiceQuery: (audioPath) {
                    final user = ref.read(currentUserProvider).value;
                    ref.read(currentQueryProvider.notifier).sendVoiceQuery(
                      audioPath: audioPath,
                      language: selectedLanguage,
                      userId: user?.id,
                    );
                  },
                ),
                
                // Text Input Tab
                TextInputWidget(
                  controller: _textController,
                  language: selectedLanguage,
                  onTextQuery: (text) {
                    final user = ref.read(currentUserProvider).value;
                    ref.read(currentQueryProvider.notifier).sendTextQuery(
                      text: text,
                      language: selectedLanguage,
                      userId: user?.id,
                    );
                    _textController.clear();
                  },
                ),
              ],
            ),
          ),
          
          // Response Section
          Expanded(
            flex: 2,
            child: QueryResponseWidget(queryState: currentQuery),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(currentQueryProvider.notifier).clearQuery();
        },
        child: const Icon(Icons.clear),
        tooltip: 'Clear Response',
      ),
    );
  }
}