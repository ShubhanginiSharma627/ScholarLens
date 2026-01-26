import 'package:flutter/material.dart';
import '../../models/models.dart';

/// Settings section providing options for notifications, audio preferences, and app behavior
class SettingsSection extends StatelessWidget {
  final AppSettings settings;
  final Function(AppSettings) onSettingsChanged;

  const SettingsSection({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Card(
          child: Column(
            children: [
              // Notifications
              _buildSettingTile(
                context,
                title: 'Notifications',
                subtitle: 'Receive learning reminders and updates',
                icon: Icons.notifications,
                trailing: Switch(
                  value: settings.notificationsEnabled,
                  onChanged: (value) {
                    onSettingsChanged(settings.copyWith(notificationsEnabled: value));
                  },
                ),
              ),
              
              const Divider(height: 1),
              
              // Text-to-Speech
              _buildSettingTile(
                context,
                title: 'Text-to-Speech',
                subtitle: 'Enable audio explanations',
                icon: Icons.volume_up,
                trailing: Switch(
                  value: settings.ttsEnabled,
                  onChanged: (value) {
                    onSettingsChanged(settings.copyWith(ttsEnabled: value));
                  },
                ),
              ),
              
              const Divider(height: 1),
              
              // TTS Speed
              _buildSettingTile(
                context,
                title: 'Speech Speed',
                subtitle: 'Adjust audio playback speed',
                icon: Icons.speed,
                trailing: DropdownButton<double>(
                  value: settings.ttsSpeed,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                    DropdownMenuItem(value: 0.75, child: Text('0.75x')),
                    DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                    DropdownMenuItem(value: 1.25, child: Text('1.25x')),
                    DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onSettingsChanged(settings.copyWith(ttsSpeed: value));
                    }
                  },
                ),
              ),
              
              const Divider(height: 1),
              
              // Dark Mode
              _buildSettingTile(
                context,
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                icon: Icons.dark_mode,
                trailing: Switch(
                  value: settings.darkModeEnabled,
                  onChanged: (value) {
                    onSettingsChanged(settings.copyWith(darkModeEnabled: value));
                  },
                ),
              ),
              
              const Divider(height: 1),
              
              // Offline Mode
              _buildSettingTile(
                context,
                title: 'Offline Mode',
                subtitle: 'Enable offline learning features',
                icon: Icons.offline_bolt,
                trailing: Switch(
                  value: settings.offlineModeEnabled,
                  onChanged: (value) {
                    onSettingsChanged(settings.copyWith(offlineModeEnabled: value));
                  },
                ),
              ),
              
              const Divider(height: 1),
              
              // Language
              _buildSettingTile(
                context,
                title: 'Language',
                subtitle: 'App language preference',
                icon: Icons.language,
                trailing: DropdownButton<String>(
                  value: settings.preferredLanguage,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'es', child: Text('Spanish')),
                    DropdownMenuItem(value: 'fr', child: Text('French')),
                    DropdownMenuItem(value: 'de', child: Text('German')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onSettingsChanged(settings.copyWith(preferredLanguage: value));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Additional Settings
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                subtitle: const Text('Get help and contact support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showHelpDialog(context),
              ),
              
              const Divider(height: 1),
              
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                subtitle: const Text('App version and information'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAboutDialog(context),
              ),
              
              const Divider(height: 1),
              
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                subtitle: const Text('View privacy policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPrivacyDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help with ScholarLens?'),
            SizedBox(height: 16),
            Text('• Check our FAQ section'),
            Text('• Contact support at help@scholarlens.com'),
            Text('• Visit our website for tutorials'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'ScholarLens',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.school, size: 48),
      children: const [
        Text('ScholarLens is a multimodal AI tutor app that helps students learn through interactive lessons, quizzes, and personalized explanations.'),
      ],
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Privacy Policy Summary:'),
              SizedBox(height: 16),
              Text('• We collect learning data to improve your experience'),
              Text('• Your personal information is kept secure'),
              Text('• We do not share data with third parties'),
              Text('• You can delete your data at any time'),
              SizedBox(height: 16),
              Text('For the full privacy policy, visit our website.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}