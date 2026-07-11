import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/backup_service.dart';
import '../services/export_service.dart';
import '../services/history_provider.dart';
import '../services/settings_provider.dart';
import '../services/theme_provider.dart';
import '../utils/constants.dart';
import 'rules_screen.dart';

/// Local settings page: theme, defaults, rules access, export, and
/// backup/restore - all fully on-device.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();
    final history = context.watch<HistoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Appearance'),
          Container(
            decoration: _cardDecoration(context),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Light'),
                  value: ThemeMode.light,
                  groupValue: theme.mode,
                  onChanged: (v) => theme.setMode(v!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark'),
                  value: ThemeMode.dark,
                  groupValue: theme.mode,
                  onChanged: (v) => theme.setMode(v!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('System Default'),
                  value: ThemeMode.system,
                  groupValue: theme.mode,
                  onChanged: (v) => theme.setMode(v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader('Prediction Engine'),
          Container(
            decoration: _cardDecoration(context),
            child: ListTile(
              leading: const Icon(Icons.rule_folder_outlined),
              title: const Text('Editable Rules'),
              subtitle: const Text('Manage Time / Browser / Device / Streak rules'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RulesScreen()),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader('Defaults'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: _cardDecoration(context),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: settings.defaultDevice.isEmpty ? null : settings.defaultDevice,
                  decoration: const InputDecoration(labelText: 'Default Device'),
                  items: AppConstants.exampleDevices
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => settings.setDefaultDevice(v ?? ''),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: settings.defaultBrowser.isEmpty ? null : settings.defaultBrowser,
                  decoration: const InputDecoration(labelText: 'Default Browser'),
                  items: AppConstants.exampleBrowsers
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) => settings.setDefaultBrowser(v ?? ''),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader('Behavior'),
          Container(
            decoration: _cardDecoration(context),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Confirm before delete'),
                  value: settings.confirmBeforeDelete,
                  onChanged: settings.setConfirmBeforeDelete,
                ),
                SwitchListTile(
                  title: const Text('Show confidence on dashboard'),
                  value: settings.showConfidenceOnDashboard,
                  onChanged: settings.setShowConfidenceOnDashboard,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader('Export'),
          Container(
            decoration: _cardDecoration(context),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.table_chart_outlined),
                  title: const Text('Export History as CSV'),
                  onTap: () async {
                    await ExportService().exportCsv();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.data_object_outlined),
                  title: const Text('Export History as JSON'),
                  onTap: () async {
                    await ExportService().exportJson();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader('Backup & Restore'),
          Container(
            decoration: _cardDecoration(context),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Backup Database'),
                  subtitle: const Text('Saves and shares a copy of your local database'),
                  onTap: () async {
                    await BackupService().backup();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('Restore Database'),
                  subtitle: const Text('Replaces current data with a backup file'),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Restore database?'),
                        content: const Text('This will replace all current history and rules. Continue?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore')),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final ok = await BackupService().restore();
                      if (context.mounted) {
                        if (ok) await history.load();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Database restored' : 'Restore cancelled or failed')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader('Danger Zone'),
          Container(
            decoration: _cardDecoration(context),
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
              title: const Text('Clear All History', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Clear all history?'),
                    content: const Text('This permanently deletes every recorded result. Rules are not affected.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete All'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) await history.clearAll();
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text('KB Predictor AI', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'v1.0.0 \u2022 100% Offline \u2022 Local Rule Engine',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      );
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
