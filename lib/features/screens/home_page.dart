import 'package:finova/core/models/models.dart';
import 'package:finova/core/services/calculations.dart';
import 'package:finova/core/utils/formatters.dart';
import 'package:finova/core/widgets/common_widgets.dart';
import 'package:finova/features/screens/finance_screens.dart';
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
                          const Text("Here's your day at a glance."),
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
                        'Current balance',
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
                              'Income this month',
                              formatMoney(
                                month.income,
                                state.settings.currency,
                              ),
                              Colors.greenAccent,
                            ),
                          ),
                          Expanded(
                            child: _metric(
                              'Expense this month',
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
                SectionTitle(
                  'Monthly budget',
                  action: overall == null ? 'Set budget' : 'Edit',
                  onAction: () => BudgetFormPage.show(context),
                ),
                const SizedBox(height: 10),
                if (overall == null)
                  const EmptyState(
                    icon: Icons.savings_outlined,
                    title: 'Plan this month',
                    message: 'Set a monthly budget to keep spending in view.',
                  )
                else
                  _budgetCard(
                    context,
                    overall.amount,
                    month.expense,
                    state.settings.currency,
                  ),
                const SizedBox(height: 24),
                const SectionTitle('Quick actions'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _quick(
                      context,
                      Icons.remove,
                      'Expense',
                      () => TransactionFormPage.show(
                        context,
                        TransactionType.expense,
                      ),
                    ),
                    _quick(
                      context,
                      Icons.add,
                      'Income',
                      () => TransactionFormPage.show(
                        context,
                        TransactionType.income,
                      ),
                    ),
                    _quick(
                      context,
                      Icons.task_alt,
                      'Task',
                      () => TaskFormPage.show(context),
                    ),
                    _quick(
                      context,
                      Icons.repeat,
                      'Habit',
                      () => HabitFormPage.show(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionTitle('Productivity today'),
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
                            '${today.where((task) => task.completed).length} of ${today.length} tasks completed',
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
                const SectionTitle('Recent transactions'),
                if (state.transactions.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No transactions yet',
                    message: 'Start by adding your first expense or income.',
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
                '${formatMoney((amount - spent).clamp(0, amount), currency)} remaining',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
