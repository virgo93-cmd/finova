import 'package:finova/core/models/models.dart';
import 'package:finova/core/services/account_service.dart';
import 'package:finova/core/services/auth_service.dart';
import 'package:finova/core/services/notification_service.dart';
import 'package:finova/features/screens/finance_screens.dart';
import 'package:finova/features/state/finova_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with WidgetsBindingObserver {
  bool _authBusy = false;
  bool _dataBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        AuthService.instance.user != null) {
      ref.invalidate(accountProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(finovaControllerProvider).value?.settings;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final notifier = ref.read(finovaControllerProvider.notifier);
    final account = ref.watch(accountProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
        children: [
          _header(context, 'Akun & pencadangan'),
          _accountCard(context, account),
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
              applicationVersion: '2.1.0',
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountCard(
    BuildContext context,
    AsyncValue<AccountState> accountValue,
  ) {
    final currentUser = AuthService.instance.user;
    final account =
        accountValue.value ??
        (currentUser == null
            ? const AccountState()
            : AccountState.fromUser(currentUser));
    final user = account.user;
    final name = account.displayName ?? user?.email ?? 'Pengguna Finova';
    final avatar = account.avatarUrl;
    final lastBackup = DateTime.tryParse(
      ref.read(preferencesProvider).getString('last_backup_at') ?? '',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: user == null
            ? ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: const Text('Masuk dengan Google'),
                subtitle: const Text(
                  'Buat profil dan siapkan pencadangan pribadi ke Google Drive.',
                ),
                trailing: _authBusy
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: _authBusy ? null : _signIn,
              )
            : Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: avatar == null
                          ? null
                          : NetworkImage(avatar),
                      child: avatar == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(name),
                    subtitle: Text(user.email ?? 'Akun Google terhubung'),
                    trailing: account.isPremium
                        ? const Chip(
                            avatar: Icon(Icons.workspace_premium, size: 18),
                            label: Text('Premium'),
                          )
                        : const Icon(Icons.verified, color: Color(0xFF087F68)),
                    onTap: () => _editProfile(account),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.cloud_done_outlined),
                    title: const Text('Backup Google Drive'),
                    subtitle: const Text(
                      'Simpan seluruh data lokal ke folder pribadi Finova.',
                    ),
                    trailing: lastBackup == null
                        ? null
                        : Text(
                            _dateTime(lastBackup.toLocal()),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _dataBusy ? null : _createBackup,
                            icon: const Icon(Icons.cloud_upload_outlined),
                            label: const Text('Backup'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _dataBusy ? null : _restoreBackup,
                            icon: const Icon(Icons.cloud_download_outlined),
                            label: const Text('Pulihkan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!account.isPremium)
                    ListTile(
                      leading: const Icon(Icons.workspace_premium_outlined),
                      title: const Text('Finova Premium — 30 hari'),
                      subtitle: const Text(
                        'Nikmati Finova tanpa banner dan iklan interstisial.',
                      ),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: _authBusy ? null : _buyPremium,
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.block),
                      title: const Text('Semua iklan dinonaktifkan'),
                      subtitle: Text(
                        'Premium aktif hingga ${_date(account.premiumExpiresAt!)}',
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _authBusy ? null : _signOut,
                      child: const Text('Keluar dari akun'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() => _authBusy = true);
    try {
      final signedInUser = await AuthService.instance.signInWithGoogle();
      if (AuthService.instance.user?.id != signedInUser.id) {
        throw StateError('Sesi Google tidak tersimpan. Silakan coba kembali.');
      }
      await ref.read(accountProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun Google berhasil terhubung.')),
        );
      }
    } catch (error) {
      if (mounted) _showAuthError(error.toString());
    } finally {
      if (mounted) setState(() => _authBusy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _authBusy = true);
    try {
      await AuthService.instance.signOut();
      ref.invalidate(accountProvider);
    } catch (error) {
      if (mounted) _showAuthError(error.toString());
    } finally {
      if (mounted) setState(() => _authBusy = false);
    }
  }

  Future<void> _createBackup() async {
    setState(() => _dataBusy = true);
    try {
      final at = await ref
          .read(finovaControllerProvider.notifier)
          .createCloudBackup();
      if (mounted) _showMessage('Backup berhasil dibuat ${_dateTime(at)}.');
    } catch (error) {
      if (mounted) _showMessage('Backup gagal: $error');
    } finally {
      if (mounted) setState(() => _dataBusy = false);
    }
  }

  Future<void> _restoreBackup() async {
    final confirmed = await confirmDelete(
      context,
      'Pulihkan backup Google Drive? Semua data lokal saat ini akan diganti.',
    );
    if (!confirmed || !mounted) return;
    setState(() => _dataBusy = true);
    try {
      final at = await ref
          .read(finovaControllerProvider.notifier)
          .restoreCloudBackup();
      if (mounted) {
        _showMessage('Data berhasil dipulihkan dari ${_dateTime(at)}.');
      }
    } catch (error) {
      if (mounted) _showMessage('Pemulihan gagal: $error');
    } finally {
      if (mounted) setState(() => _dataBusy = false);
    }
  }

  Future<void> _buyPremium() async {
    final user = AuthService.instance.user;
    if (user?.email == null) return;
    try {
      await openPremiumCheckout(user!.id, user.email!);
    } catch (error) {
      if (mounted) _showMessage('Checkout gagal dibuka: $error');
    }
  }

  Future<void> _editProfile(AccountState account) async {
    final controller = TextEditingController(text: account.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah profil'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nama tampilan'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref.read(accountProvider.notifier).updateDisplayName(name);
      if (mounted) _showMessage('Profil berhasil diperbarui.');
    } catch (error) {
      if (mounted) _showMessage('Profil gagal diperbarui: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _dateTime(DateTime value) =>
      '${_date(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  void _showAuthError(String detail) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Login gagal: $detail')));
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
          'Finova menyimpan data inti keuangan dan produktivitas secara lokal di perangkat Anda. Akun bersifat opsional. Jika Anda menekan Backup, salinan terenkripsi dalam transit dikirim ke folder aplikasi pribadi Finova di Google Drive Anda.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Aplikasi gratis dapat menampilkan banner dan iklan interstisial terbatas menggunakan Google Mobile Ads SDK. Google dapat memproses informasi perangkat dan iklan sesuai kebijakannya. Mekanisme persetujuan diterapkan bila diwajibkan.',
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
          'Catatan inti disimpan secara lokal dan dapat hilang bila aplikasi direset, penyimpanan dibersihkan, aplikasi dihapus, perangkat hilang, atau mengalami kerusakan. Backup Google Drive dilakukan hanya atas tindakan pengguna. Pembayaran Premium diproses Lemon Squeezy dan iklan tunduk pada ketentuan pihak ketiga.',
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
          const Text('Versi 2.1.0'),
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
