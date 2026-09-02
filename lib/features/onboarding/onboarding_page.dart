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
      'Track your money.',
      'Capture income and spending in seconds.',
    ),
    (
      Icons.auto_awesome_outlined,
      'Build better routines.',
      'Tasks and habits, naturally part of your day.',
    ),
    (
      Icons.insights_outlined,
      'See your progress.',
      'Clear insights for money and momentum.',
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
                  child: Text(_page == 3 ? 'Start Finova' : 'Continue'),
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
        'A quick setup',
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text('You can change these later in Settings.'),
      const SizedBox(height: 28),
      DropdownButtonFormField<String>(
        initialValue: _currency,
        decoration: const InputDecoration(labelText: 'Currency'),
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
          labelText: 'Starting balance (optional)',
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
