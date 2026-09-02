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
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
        children: [
          _header(context, 'Umum'),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Mata uang'),
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
            title: const Text('Tema'),
            trailing: DropdownButton<AppThemeMode>(
              value: settings.themeMode,
              items: AppThemeMode.values
                  .map(
                    (x) => DropdownMenuItem(
                      value: x,
                      child: Text(switch (x) {
                        AppThemeMode.system => 'Sistem',
                        AppThemeMode.light => 'Terang',
                        AppThemeMode.dark => 'Gelap',
                      }),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  notifier.updateSettings(settings.copyWith(themeMode: v)),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Pengingat'),
            subtitle: const Text('Tinjauan harian pukul 19.00'),
            value: settings.notificationsEnabled,
            onChanged: (value) async {
              final allowed = await NotificationService.setDailyReminder(value);
              await notifier.updateSettings(
                settings.copyWith(notificationsEnabled: value && allowed),
              );
              if (!allowed && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Izin notifikasi tidak diberikan.'),
                  ),
                );
              }
            },
          ),
          _header(context, 'Data & privasi'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Kebijakan Privasi'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Ketentuan Penggunaan'),
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
              'Hapus semua data',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text(
              'Menghapus permanen seluruh data lokal dan pengaturan',
            ),
            onTap: () async {
              if (await confirmDelete(
                context,
                'Hapus seluruh data Finova? Tindakan ini tidak dapat dibatalkan.',
              )) {
                await notifier.resetAll();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          _header(context, 'Tentang'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang Finova'),
            subtitle: const Text('Keuangan tertata. Hidup terarah.'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Lisensi'),
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
    appBar: AppBar(title: const Text('Privasi')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Data Anda, tetap sederhana',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        const Text(
          'Finova menyimpan data inti keuangan dan produktivitas secara lokal di perangkat Anda. Finova tidak memerlukan akun dan tidak mengunggah catatan tersebut ke server Finova.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Aplikasi dapat menampilkan iklan menggunakan Google Mobile Ads SDK. Google dapat memproses informasi perangkat dan iklan sesuai kebijakannya. Mekanisme persetujuan diterapkan bila diwajibkan.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Kebijakan privasi publik tersedia melalui situs resmi Finova.',
        ),
      ],
    ),
  );
}

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ketentuan Penggunaan')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Ketentuan Penggunaan Finova',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text('Berlaku sejak 2 September 2026'),
        const SizedBox(height: 20),
        const Text(
          'Finova menyediakan pencatatan pribadi, anggaran, tugas, kebiasaan, serta ringkasan informasi. Finova bukan bank, layanan akuntansi, penasihat keuangan, investasi, pajak, medis, atau layanan darurat.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Anda bertanggung jawab atas keakuratan catatan, keamanan perangkat, cadangan data yang diperlukan, dan penggunaan aplikasi secara sah. Perhitungan tidak boleh menjadi satu-satunya dasar keputusan penting.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Catatan inti disimpan secara lokal dan dapat hilang bila aplikasi direset, penyimpanan dibersihkan, aplikasi dihapus, perangkat hilang, atau mengalami kerusakan. Iklan tunduk pada ketentuan pihak ketiga.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Sejauh diizinkan hukum, Finova disediakan “sebagaimana adanya” dan “sebagaimana tersedia”. Hak konsumen yang wajib tetap berlaku.',
        ),
      ],
    ),
  );
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tentang')),
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
          const Text('Keuangan tertata. Hidup terarah.'),
          const SizedBox(height: 8),
          const Text('Versi 1.1.0'),
          const Spacer(),
          const Text(
            'Dibuat untuk pencatatan keuangan dan produktivitas yang tenang serta tersimpan lokal.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
