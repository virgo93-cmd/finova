import 'package:finova/features/state/finova_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});
  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  final _balance = TextEditingController();
  int _page = 0;
  String _currency = 'IDR';
  static const _pages = [
    (
      Icons.account_balance_wallet_outlined,
      'Catat keuangan Anda.',
      'Simpan pemasukan dan pengeluaran dalam hitungan detik.',
    ),
    (
      Icons.auto_awesome_outlined,
      'Bangun rutinitas yang lebih baik.',
      'Tugas dan kebiasaan menjadi bagian alami dari hari Anda.',
    ),
    (
      Icons.insights_outlined,
      'Lihat perkembangan Anda.',
      'Insight yang jelas untuk keuangan dan produktivitas.',
    ),
  ];
  @override
  void dispose() {
    _controller.dispose();
    _balance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  ..._pages.map(
                    (item) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.$1,
                          size: 84,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          item.$2,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.$3,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  _setup(context),
                ],
              ),
            ),
            Row(
              children: [
                ...List.generate(
                  4,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    height: 7,
                    width: _page == index ? 24 : 7,
                    decoration: BoxDecoration(
                      color: _page == index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _next,
                  child: Text(_page == 3 ? 'Mulai Finova' : 'Lanjut'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  Widget _setup(BuildContext context) => ListView(
    padding: const EdgeInsets.only(top: 80),
    children: [
      Text(
        'Pengaturan singkat',
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text('Anda dapat mengubahnya nanti di Pengaturan.'),
      const SizedBox(height: 28),
      DropdownButtonFormField<String>(
        initialValue: _currency,
        decoration: const InputDecoration(labelText: 'Mata uang'),
        items: [
          'IDR',
          'USD',
          'EUR',
          'GBP',
          'SGD',
          'MYR',
        ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) => setState(() => _currency = v!),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _balance,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Saldo awal (opsional)',
          prefixIcon: Icon(Icons.savings_outlined),
        ),
      ),
    ],
  );
  Future<void> _next() async {
    if (_page < 3) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }
    final raw = _balance.text.replaceAll(RegExp(r'[^0-9]'), '');
    await ref
        .read(finovaControllerProvider.notifier)
        .completeOnboarding(_currency, int.tryParse(raw) ?? 0);
  }
}
