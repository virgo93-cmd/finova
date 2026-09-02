import 'package:finova/core/models/models.dart';
import 'package:finova/features/screens/finance_screens.dart';
import 'package:finova/features/screens/debt_screen.dart';
import 'package:finova/features/screens/home_page.dart';
import 'package:finova/features/screens/productivity_screens.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  static const _pages = [
    HomePage(),
    TransactionsPage(),
    DebtPage(),
    ProductivityPage(),
    InsightsPage(),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _index, children: _pages),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        NavigationDestination(icon: Icon(Icons.swap_horiz), label: 'Transaksi'),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Hutang',
        ),
        NavigationDestination(
          icon: Icon(Icons.check_circle_outline),
          label: 'Aktivitas',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          label: 'Insight',
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _quickActions,
      child: const Icon(Icons.add),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
  );
  void _quickActions() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tambah cepat', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _action(
                  sheet,
                  Icons.arrow_upward,
                  'Pengeluaran',
                  () => TransactionFormPage.show(
                    context,
                    TransactionType.expense,
                  ),
                ),
                _action(
                  sheet,
                  Icons.arrow_downward,
                  'Pemasukan',
                  () =>
                      TransactionFormPage.show(context, TransactionType.income),
                ),
                _action(
                  sheet,
                  Icons.task_alt,
                  'Tugas',
                  () => TaskFormPage.show(context),
                ),
                _action(
                  sheet,
                  Icons.repeat,
                  'Kebiasaan',
                  () => HabitFormPage.show(context),
                ),
                _action(
                  sheet,
                  Icons.handshake_outlined,
                  'Hutang/Piutang',
                  () => DebtFormPage.show(context),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  Widget _action(
    BuildContext sheet,
    IconData icon,
    String label,
    VoidCallback action,
  ) => ActionChip(
    avatar: Icon(icon),
    label: Text(label),
    onPressed: () {
      Navigator.pop(sheet);
      action();
    },
  );
}
