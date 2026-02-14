import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/language_selector.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final selectedLanguage = ref.watch(selectedLanguageProvider);
    final supportedLanguages = ref.watch(supportedLanguagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Profile',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    currentUser.when(
                      data: (user) {
                        if (user == null) {
                          return _buildRegistrationForm();
                        } else {
                          return _buildUserProfile(user);
                        }
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Column(
                        children: [
                          Text('Error: $error'),
                          const SizedBox(height: 16),
                          _buildRegistrationForm(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Language Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Language Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    supportedLanguages.when(
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
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // App Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('Version'),
                      subtitle: const Text('1.0.0'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.agriculture),
                      title: const Text('About Farmer Copilot'),
                      subtitle: const Text('AI-powered agricultural assistant'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text('Supported Languages'),
                      subtitle: const Text('English, Tamil, Hindi, Telugu, Kannada, Malayalam'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      leading: const Icon(Icons.refresh),
                      title: const Text('Check Connection'),
                      subtitle: const Text('Test connection to Farmer Copilot server'),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        ref.read(connectionStatusProvider.notifier).checkConnection();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Checking connection...')),
                        );
                      },
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.clear_all),
                      title: const Text('Clear History'),
                      subtitle: const Text('Remove all query history'),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        _showClearHistoryDialog();
                      },
                    ),
                    
                    if (currentUser.value != null)
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        subtitle: const Text('Sign out of your account'),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          _showLogoutDialog();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Location (Optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _registerUser,
            child: const Text('Register'),
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfile(user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Name'),
          subtitle: Text(user.name),
          contentPadding: EdgeInsets.zero,
        ),
        
        ListTile(
          leading: const Icon(Icons.phone),
          title: const Text('Phone'),
          subtitle: Text(user.phoneNumber),
          contentPadding: EdgeInsets.zero,
        ),
        
        if (user.location != null)
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Location'),
            subtitle: Text(user.location!),
            contentPadding: EdgeInsets.zero,
          ),
        
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Language'),
          subtitle: Text(user.language),
          contentPadding: EdgeInsets.zero,
        ),
        
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Member Since'),
          subtitle: Text(user.createdAt.toString().split(' ')[0]),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  void _registerUser() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final location = _locationController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in required fields')),
      );
      return;
    }

    ref.read(currentUserProvider.notifier).registerUser(
      phoneNumber: phone,
      name: name,
      language: ref.read(selectedLanguageProvider),
      location: location.isEmpty ? null : location,
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all query history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(queryHistoryProvider.notifier).clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(currentUserProvider.notifier).logout();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}