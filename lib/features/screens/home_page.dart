import 'package:finova/core/models/models.dart';
import 'package:finova/core/services/calculations.dart';
import 'package:finova/core/utils/formatters.dart';
import 'package:finova/core/widgets/common_widgets.dart';
import 'package:finova/features/screens/finance_screens.dart';
import 'package:finova/features/screens/goals_screen.dart';
import 'package:finova/features/screens/productivity_screens.dart';
import 'package:finova/features/screens/settings_page.dart';
import 'package:finova/features/state/finova_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(finovaControllerProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (state) {
        final now = DateTime.now();
        final monthItems = state.transactions.where(
          (item) => item.date.year == now.year && item.date.month == now.month,
        );
        final all = calculateFinance(
          state.transactions,
          initialBalance: state.settings.initialBalance,
        );
        final month = calculateFinance(monthItems);
        final today = state.tasks
            .where((task) => dateOnly(task.dueDate) == dateOnly(now))
            .toList();
        final overall = state.budgets
            .where(
              (budget) =>
                  budget.categoryId == null &&
                  budget.month.year == now.year &&
                  budget.month.month == now.month,
            )
            .firstOrNull;
        final expenseTrend = List<int>.generate(7, (index) {
          final day = dateOnly(now.subtract(Duration(days: 6 - index)));
          return state.transactions
              .where(
                (item) =>
                    item.type == TransactionType.expense &&
                    dateOnly(item.date) == day,
              )
              .fold(0, (sum, item) => sum + item.amount);
        });
        final incomeTrend = List<int>.generate(7, (index) {
          final day = dateOnly(now.subtract(Duration(days: 6 - index)));
          return state.transactions
              .where(
                (item) =>
                    item.type == TransactionType.income &&
                    dateOnly(item.date) == day,
              )
              .fold(0, (sum, item) => sum + item.amount);
        });
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(finovaControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting(),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Text('Ringkasan aktivitas Anda hari ini.'),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      ),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF087F68), Color(0xFF075C50)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo saat ini',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatMoney(all.balance, state.settings.currency),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: _metric(
                              'Pemasukan bulan ini',
                              formatMoney(
                                month.income,
                                state.settings.currency,
                              ),
                              Colors.greenAccent,
                            ),
                          ),
                          Expanded(
                            child: _metric(
                              'Pengeluaran bulan ini',
                              formatMoney(
                                month.expense,
                                state.settings.currency,
                              ),
                              Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionTitle('Tren arus kas 7 hari'),
                const SizedBox(height: 10),
                _CashflowChart(
                  incomeValues: incomeTrend,
                  expenseValues: expenseTrend,
                ),
                const SizedBox(height: 24),
                SectionTitle(
                  'Anggaran bulanan',
                  action: overall == null ? 'Atur anggaran' : 'Ubah',
                  onAction: () => BudgetFormPage.show(context),
                ),
                const SizedBox(height: 10),
                if (overall == null)
                  const EmptyState(
                    icon: Icons.savings_outlined,
                    title: 'Rencanakan bulan ini',
                    message:
                        'Atur anggaran bulanan agar pengeluaran tetap terpantau.',
                  )
                else
                  _budgetCard(
                    context,
                    overall.amount,
                    month.expense,
                    state.settings.currency,
                  ),
                const SizedBox(height: 24),
                const SectionTitle('Aksi cepat'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _quick(
                      context,
                      Icons.remove,
                      'Pengeluaran',
                      () => TransactionFormPage.show(
                        context,
                        TransactionType.expense,
                      ),
                    ),
                    _quick(
                      context,
                      Icons.add,
                      'Pemasukan',
                      () => TransactionFormPage.show(
                        context,
                        TransactionType.income,
                      ),
                    ),
                    _quick(
                      context,
                      Icons.task_alt,
                      'Tugas',
                      () => TaskFormPage.show(context),
                    ),
                    _quick(
                      context,
                      Icons.repeat,
                      'Kebiasaan',
                      () => HabitFormPage.show(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionTitle('Produktivitas hari ini'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Icon(
                          Icons.task_alt,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${today.where((task) => task.completed).length} dari ${today.length} tugas selesai',
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: LinearProgressIndicator(
                            value: taskCompletion(today),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SectionTitle(
                  'Target keuangan',
                  action: 'Lihat semua',
                  onAction: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GoalsPage()),
                  ),
                ),
                if (state.goals.isEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.flag_outlined),
                    ),
                    title: const Text('Mulai target tabungan'),
                    subtitle: const Text(
                      'Pantau progres tujuan keuangan Anda.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => GoalFormPage.show(context),
                  )
                else
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.flag)),
                      title: Text(state.goals.first.title),
                      subtitle: LinearProgressIndicator(
                        value: state.goals.first.progress,
                      ),
                      trailing: Text(
                        '${(state.goals.first.progress * 100).round()}%',
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GoalsPage()),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                const SectionTitle('Transaksi terbaru'),
                if (state.transactions.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum ada transaksi',
                    message:
                        'Mulai dengan menambahkan pemasukan atau pengeluaran pertama.',
                  )
                else
                  ...state.transactions
                      .take(5)
                      .map(
                        (item) => TransactionTile(
                          transaction: item,
                          currency: state.settings.currency,
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metric(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    ],
  );
  Widget _quick(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          CircleAvatar(child: Icon(icon)),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    ),
  );
  Widget _budgetCard(
    BuildContext context,
    int amount,
    int spent,
    String currency,
  ) {
    final progress = budgetProgress(spent: spent, budget: amount);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  formatMoney(spent, currency),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text('${(progress * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress.clamp(0, 1),
              color: progress > 1
                  ? Theme.of(context).colorScheme.error
                  : progress > .8
                  ? Colors.amber
                  : null,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sisa ${formatMoney((amount - spent).clamp(0, amount), currency)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashflowChart extends StatelessWidget {
  const _CashflowChart({
    required this.incomeValues,
    required this.expenseValues,
  });
  final List<int> incomeValues;
  final List<int> expenseValues;

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      ...incomeValues,
      ...expenseValues,
    ].fold(0, (a, b) => a > b ? a : b);
    return Semantics(
      label: 'Grafik pemasukan dan pengeluaran tujuh hari terakhir',
      child: Container(
        height: 178,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _legend(context, const Color(0xFF159B7D), 'Pemasukan'),
                const SizedBox(width: 12),
                _legend(context, const Color(0xFFE76F51), 'Pengeluaran'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: maxValue == 0
                  ? const Center(
                      child: Text('Belum ada transaksi dalam 7 hari.'),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(incomeValues.length, (index) {
                        final incomeRatio = incomeValues[index] / maxValue;
                        final expenseRatio = expenseValues[index] / maxValue;
                        final day = DateTime.now().subtract(
                          Duration(days: 6 - index),
                        );
                        const labels = [
                          'Sen',
                          'Sel',
                          'Rab',
                          'Kam',
                          'Jum',
                          'Sab',
                          'Min',
                        ];
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: FractionallySizedBox(
                                            heightFactor: incomeRatio.clamp(
                                              .03,
                                              1,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF159B7D),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: FractionallySizedBox(
                                            heightFactor: expenseRatio.clamp(
                                              .03,
                                              1,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE76F51),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  labels[day.weekday - 1],
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(BuildContext context, Color color, String label) => Row(
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}
