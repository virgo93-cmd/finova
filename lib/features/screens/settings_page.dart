import 'package:finova/core/models/models.dart';
import 'package:finova/core/services/notification_service.dart';
import 'package:finova/features/screens/finance_screens.dart';
import 'package:finova/features/state/finova_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(finovaControllerProvider).value?.settings;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final notifier = ref.read(finovaControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
        children: [
          _header(context, 'General'),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Currency'),
            trailing: DropdownButton<String>(
              value: settings.currency,
              items: [
                'IDR',
                'USD',
                'EUR',
                'GBP',
                'SGD',
                'MYR',
              ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
              onChanged: (v) =>
                  notifier.updateSettings(settings.copyWith(currency: v)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            trailing: DropdownButton<AppThemeMode>(
              value: settings.themeMode,
              items: AppThemeMode.values
                  .map((x) => DropdownMenuItem(value: x, child: Text(x.name)))
                  .toList(),
              onChanged: (v) =>
                  notifier.updateSettings(settings.copyWith(themeMode: v)),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Reminders'),
            subtitle: const Text('Daily review at 7:00 PM'),
            value: settings.notificationsEnabled,
            onChanged: (value) async {
              final allowed = await NotificationService.setDailyReminder(value);
              await notifier.updateSettings(
                settings.copyWith(notificationsEnabled: value && allowed),
              );
              if (!allowed && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification permission was not granted.'),
                  ),
                );
              }
            },
          ),
          _header(context, 'Data & privacy'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Terms of Use'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsPage()),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Reset all data',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text('Permanently removes local records and setup'),
            onTap: () async {
              if (await confirmDelete(
                context,
                'Reset all Finova data? This cannot be undone.',
              )) {
                await notifier.resetAll();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          _header(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Finova'),
            subtitle: const Text('Track Money. Track Life.'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Finova',
              applicationVersion: '1.0.0',
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext c, String value) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 22, 16, 6),
    child: Text(
      value.toUpperCase(),
      style: Theme.of(
        c,
      ).textTheme.labelLarge?.copyWith(color: Theme.of(c).colorScheme.primary),
    ),
  );
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacy')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Your data, kept simple',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        const Text(
          'Finova stores core financial and productivity data locally on your device. Finova does not require an account and does not upload these records to a Finova server.',
        ),
        const SizedBox(height: 16),
        const Text(
          'The app can display advertisements using the Google Mobile Ads SDK. Google may process device and advertising information under its own terms. Where required, an applicable consent mechanism must be configured before release.',
        ),
        const SizedBox(height: 16),
        const Text(
          'A public privacy policy URL and final legal text must be supplied by the publisher before Play Store release.',
        ),
      ],
    ),
  );
}

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Terms of Use')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Finova Terms of Use',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text('Effective September 2, 2026'),
        const SizedBox(height: 20),
        const Text(
          'Finova provides personal recordkeeping, budgeting, task, habit, and informational summary tools. It is not a bank, accounting service, financial adviser, investment adviser, tax adviser, medical provider, or emergency service.',
        ),
        const SizedBox(height: 16),
        const Text(
          'You are responsible for the accuracy of your entries, protecting your device, keeping any backups you require, and using the app lawfully. Calculations may contain mistakes or omissions and must not be the sole basis for important decisions.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Core records are stored locally and may be lost if you reset the app, clear storage, uninstall it, lose the device, or encounter device failure. The app may display advertisements governed by third-party terms.',
        ),
        const SizedBox(height: 16),
        const Text(
          'To the maximum extent permitted by law, Finova is provided “as is” and “as available.” Mandatory consumer rights remain unaffected. The complete publisher-ready terms are included with the project documentation.',
        ),
      ],
    ),
  );
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 42,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.show_chart, color: Colors.white, size: 42),
          ),
          const SizedBox(height: 18),
          Text(
            'Finova',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Text('Track Money. Track Life.'),
          const SizedBox(height: 8),
          const Text('Version 1.0.0'),
          const Spacer(),
          const Text(
            'Built for calm, local-first money and productivity tracking.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
