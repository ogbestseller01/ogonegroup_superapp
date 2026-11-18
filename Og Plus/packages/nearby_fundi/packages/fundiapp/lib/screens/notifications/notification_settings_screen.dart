import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../config/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;
  bool _requestUpdates = true;
  bool _chatMessages = true;
  bool _subscriptionAlerts = true;
  bool _promotionalAlerts = false;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _pushEnabled = settings.notificationsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ─── Notification Channels ──────────────────────────────
              _buildSectionHeader(context, 'Notification Channels'),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      context,
                      icon: Icons.notifications_active_rounded,
                      title: 'Push Notifications',
                      subtitle: 'Receive instant alerts on your device',
                      value: _pushEnabled,
                      onChanged: (val) => setState(() => _pushEnabled = val),
                      color: Colors.blue,
                    ),
                    _buildDivider(context),
                    _buildSwitchTile(
                      context,
                      icon: Icons.email_rounded,
                      title: 'Email Notifications',
                      subtitle: 'Get updates via email',
                      value: _emailEnabled,
                      onChanged: (val) => setState(() => _emailEnabled = val),
                      color: Colors.red,
                    ),
                    _buildDivider(context),
                    _buildSwitchTile(
                      context,
                      icon: Icons.sms_rounded,
                      title: 'SMS Notifications',
                      subtitle: 'Receive text messages for important updates',
                      value: _smsEnabled,
                      onChanged: (val) => setState(() => _smsEnabled = val),
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Notification Types ─────────────────────────────────
              _buildSectionHeader(context, 'Alert Preferences'),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      context,
                      icon: Icons.request_page_rounded,
                      title: 'Request Updates',
                      subtitle: 'Get notified about request status changes',
                      value: _requestUpdates,
                      onChanged: (val) => setState(() => _requestUpdates = val),
                      color: Colors.orange,
                    ),
                    _buildDivider(context),
                    _buildSwitchTile(
                      context,
                      icon: Icons.chat_bubble_rounded,
                      title: 'Chat Messages',
                      subtitle: 'Receive notifications for new messages',
                      value: _chatMessages,
                      onChanged: (val) => setState(() => _chatMessages = val),
                      color: Colors.green,
                    ),
                    _buildDivider(context),
                    _buildSwitchTile(
                      context,
                      icon: Icons.subscriptions_rounded,
                      title: 'Subscription Alerts',
                      subtitle: 'Get notified about subscription status',
                      value: _subscriptionAlerts,
                      onChanged: (val) => setState(() => _subscriptionAlerts = val),
                      color: Colors.purple,
                    ),
                    _buildDivider(context),
                    _buildSwitchTile(
                      context,
                      icon: Icons.discount_rounded,
                      title: 'Promotional Alerts',
                      subtitle: 'Receive offers, deals, and promotions',
                      value: _promotionalAlerts,
                      onChanged: (val) => setState(() => _promotionalAlerts = val),
                      color: Colors.pink,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Sound & Vibration ──────────────────────────────────
              _buildSectionHeader(context, 'Sound & Vibration'),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      context,
                      icon: Icons.volume_up_rounded,
                      title: 'Sound Alerts',
                      subtitle: 'Play sound for incoming notifications',
                      value: _soundEnabled,
                      onChanged: (val) => setState(() => _soundEnabled = val),
                      color: Colors.amber,
                    ),
                    _buildDivider(context),
                    _buildSelectTile(
                      context,
                      icon: Icons.volume_down_rounded,
                      title: 'Notification Tone',
                      subtitle: 'Select your preferred notification sound',
                      value: 'Default',
                      onTap: () => _showSoundPicker(context),
                      color: Colors.blueGrey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Save Button ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    _saveSettings();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification settings saved successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Save Settings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required bool value,
        required ValueChanged<bool> onChanged,
        required Color color,
      }) {
    final theme = Theme.of(context);
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall,
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primary,
      activeTrackColor: AppTheme.primary.withOpacity(0.3),
    );
  }

  Widget _buildSelectTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required String value,
        required VoidCallback onTap,
        required Color color,
      }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, size: 14, color: theme.hintColor),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = Theme.of(context);
    return Divider(height: 1, color: theme.dividerColor, indent: 16, endIndent: 16);
  }

  void _showSoundPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select Notification Tone',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.blue),
                title: const Text('Default'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.circle, color: Colors.blue),
                title: const Text('Chime'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.circle, color: Colors.green),
                title: const Text('Notification'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.circle, color: Colors.orange),
                title: const Text('Alert'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.circle, color: Colors.purple),
                title: const Text('Gentle'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _saveSettings() {
    // Save all settings to provider or local storage
    final settings = context.read<SettingsProvider>();
    settings.updateNotificationStatus(_pushEnabled);
    // Add more save logic as needed
  }
}