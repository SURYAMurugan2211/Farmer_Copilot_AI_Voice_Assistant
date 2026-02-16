import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final isConnected = ref.watch(connectionStatusProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentGreen.withValues(alpha: 0.12),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: AppTheme.accentGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Manage your account',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Connection status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: AppTheme.glassCard(opacity: 0.08),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? AppTheme.accentGreen : Colors.red,
                        boxShadow: [
                          BoxShadow(
                            color: (isConnected ? AppTheme.accentGreen : Colors.red)
                                .withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isConnected ? 'Connected to Server' : 'Disconnected',
                            style: TextStyle(
                              color: isConnected
                                  ? AppTheme.accentGreen
                                  : Colors.red.shade300,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            isConnected
                                ? 'All services running'
                                : 'Check your connection',
                            style: TextStyle(
                              color: AppTheme.textMuted.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          ref.read(connectionStatusProvider.notifier).checkConnection(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accentGreen.withValues(alpha: 0.1),
                        ),
                        child: const Icon(Icons.refresh_rounded,
                            color: AppTheme.accentGreen, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // User profile section
              userAsync.when(
                data: (user) {
                  if (user != null) {
                    return _buildUserCard(user);
                  }
                  return _buildRegistrationForm();
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppTheme.accentGreen),
                  ),
                ),
                error: (e, _) => _buildRegistrationForm(),
              ),

              const SizedBox(height: 24),

              // Features section
              const Text(
                'Features',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              _featureTile(Icons.mic_rounded, 'Voice Queries',
                  'Ask in your own language', AppTheme.accentGreen),
              _featureTile(Icons.translate_rounded, 'Multi-Language',
                  'English, Tamil, Hindi & more', AppTheme.tealAccent),
              _featureTile(Icons.agriculture_rounded, 'Farming AI',
                  'Expert crop & pest advice', AppTheme.emerald),
              _featureTile(Icons.history_rounded, 'Query History',
                  'Track all your questions', AppTheme.gold),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard(opacity: 0.08),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.accentGreen, AppTheme.emerald],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGreen.withValues(alpha: 0.3),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Center(
              child: Text(
                (user.name ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name ?? 'Farmer',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.phoneNumber ?? '',
            style: TextStyle(
              color: AppTheme.textMuted.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          if (user.location != null) ...[
            const SizedBox(height: 2),
            Text(
              '📍 ${user.location}',
              style: TextStyle(
                color: AppTheme.textMuted.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => ref.read(currentUserProvider.notifier).logout(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard(opacity: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Registration',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Optional — saves your query history',
            style: TextStyle(
              color: AppTheme.textMuted.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          _inputField(_nameController, 'Full Name', Icons.person_outline_rounded),
          const SizedBox(height: 12),
          _inputField(_phoneController, 'Phone Number', Icons.phone_outlined),
          const SizedBox(height: 12),
          _inputField(_locationController, 'Location (optional)', Icons.location_on_outlined),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _register,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentGreen, AppTheme.emerald],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Register',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(
      TextEditingController controller, String hint, IconData icon) {
    return Container(
      decoration: AppTheme.glassInput(),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppTheme.textMuted.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _featureTile(IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textMuted.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: color, size: 20),
        ],
      ),
    );
  }

  void _register() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final location = _locationController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Name and phone are required'),
          backgroundColor: AppTheme.cardColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final language = ref.read(selectedLanguageProvider);
    ref.read(currentUserProvider.notifier).registerUser(
          phoneNumber: phone,
          name: name,
          language: language,
          location: location.isEmpty ? null : location,
        );
  }
}