import 'dart:io';

import 'package:finova/core/models/models.dart';
import 'package:finova/core/services/account_service.dart';
import 'package:finova/core/services/calculations.dart';
import 'package:finova/core/utils/formatters.dart';
import 'package:finova/core/widgets/common_widgets.dart';
import 'package:finova/core/widgets/finova_line_chart.dart';
import 'package:finova/features/screens/finance_screens.dart';
import 'package:finova/features/screens/goals_screen.dart';
import 'package:finova/features/screens/productivity_screens.dart';
import 'package:finova/features/screens/settings_page.dart';
import 'package:finova/features/state/finova_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _trendRange = 'Harian';
  DateTimeRange? _customRange;

  @override
  Widget build(BuildContext context) {
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
        final account = ref.watch(accountProvider).value;
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
        final trend = _trend(state.transactions);
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(finovaControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: account?.localAvatarPath != null
                          ? FileImage(File(account!.localAvatarPath!))
                          : account?.avatarUrl != null
                          ? NetworkImage(account!.avatarUrl!)
                          : null,
                      child:
                          account?.localAvatarPath == null &&
                              account?.avatarUrl == null
                          ? const Icon(Icons.person_outline)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account?.displayName ?? 'Pengguna Finova',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            greeting(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () => _showNotifications(context, state),
                      tooltip: 'Pengingat',
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      ),
                      icon: const Icon(Icons.settings_outlined, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 158,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF087F68), Color(0xFF075C50)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        top: 16,
                        right: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Colors.white70,
                                  size: 19,
                                ),
                                SizedBox(width: 7),
                                Text(
                                  'Saldo',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatMoney(
                                  all.balance,
                                  state.settings.currency,
                                ),
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 18,
                        bottom: 12,
                        child: Row(
                          children: [
                            Expanded(
                              child: _highlightMetric(
                                'Pengeluaran',
                                formatMoney(
                                  all.expense,
                                  state.settings.currency,
                                ),
                                const Color(0xFFFFA17A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _highlightMetric(
                                'Pemasukan',
                                formatMoney(
                                  all.income,
                                  state.settings.currency,
                                ),
                                const Color(0xFF70E8BD),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const SectionTitle('Aksi cepat'),
                const SizedBox(height: 8),
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
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(child: SectionTitle('Tren arus kas')),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _trendRange,
                        items:
                            ['Harian', 'Mingguan', 'Bulanan', 'Pilih tanggal']
                                .map(
                                  (x) => DropdownMenuItem(
                                    value: x,
                                    child: Text(x),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) async {
                          if (value == 'Pilih tanggal') {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              initialDateRange:
                                  _customRange ??
                                  DateTimeRange(
                                    start: now.subtract(
                                      const Duration(days: 6),
                                    ),
                                    end: now,
                                  ),
                            );
                            if (picked != null)
                              setState(() {
                                _customRange = picked;
                                _trendRange = value!;
                              });
                          } else if (value != null)
                            setState(() => _trendRange = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 155,
                  child: FinovaLineChart(
                    income: trend.$1,
                    expense: trend.$2,
                    labels: trend.$3,
                  ),
                ),
                const SizedBox(height: 18),
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

  (List<int>, List<int>, List<String>) _trend(List<MoneyTransaction> items) {
    final now = DateTime.now();
    final custom = _trendRange == 'Pilih tanggal' && _customRange != null;
    final count = custom
        ? 7
        : _trendRange == 'Mingguan'
        ? 8
        : _trendRange == 'Bulanan'
        ? 6
        : 7;
    final step = custom
        ? ((_customRange!.duration.inDays + 1) / count).ceil()
        : _trendRange == 'Mingguan'
        ? 7
        : _trendRange == 'Bulanan'
        ? 30
        : 1;
    final end = custom ? dateOnly(_customRange!.end) : dateOnly(now);
    final income = <int>[];
    final expense = <int>[];
    final labels = <String>[];
    for (var i = count - 1; i >= 0; i--) {
      final bucketEnd = end.subtract(Duration(days: i * step));
      final bucketStart = bucketEnd.subtract(Duration(days: step - 1));
      final values = items.where((item) {
        final day = dateOnly(item.date);
        return !day.isBefore(bucketStart) && !day.isAfter(bucketEnd);
      });
      income.add(
        values
            .where((x) => x.type == TransactionType.income)
            .fold(0, (a, x) => a + x.amount),
      );
      expense.add(
        values
            .where((x) => x.type == TransactionType.expense)
            .fold(0, (a, x) => a + x.amount),
      );
      labels.add(
        _trendRange == 'Bulanan'
            ? '${bucketEnd.month}/${bucketEnd.year % 100}'
            : '${bucketEnd.day}/${bucketEnd.month}',
      );
    }
    return (income, expense, labels);
  }

  Widget _highlightMetric(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      border: Border.all(color: color.withValues(alpha: .28)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );

  void _showNotifications(BuildContext context, FinovaState state) {
    final tasks = state.tasks.where((item) => !item.completed).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final debts = state.debts.where((item) => !item.isSettled).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final items = <Widget>[
      ...tasks
          .take(3)
          .map(
            (task) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.task_alt_rounded)),
              title: Text(task.title),
              subtitle: Text('Tenggat ${_shortDate(task.dueDate)}'),
            ),
          ),
      ...debts
          .take(3)
          .map(
            (debt) => ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.handshake_outlined),
              ),
              title: Text(
                '${debt.person} · ${formatMoney(debt.remaining, state.settings.currency)}',
              ),
              subtitle: Text('Jatuh tempo ${_shortDate(debt.dueDate)}'),
            ),
          ),
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Pusat pengingat',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 4),
              if (items.isEmpty)
                const ListTile(
                  leading: CircleAvatar(child: Icon(Icons.done_all_rounded)),
                  title: Text('Semua aman'),
                  subtitle: Text(
                    'Belum ada tugas atau jatuh tempo yang perlu diingatkan.',
                  ),
                )
              else
                ...items,
            ],
          ),
        ),
      ),
    );
  }

  String _shortDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

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
    required this.labels,
  });
  final List<int> incomeValues;
  final List<int> expenseValues;
  final List<String> labels;

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
                      child: Text('Belum ada data pada periode ini.'),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (_, value, __) => CustomPaint(
                              painter: _CashflowPainter(
                                incomeValues,
                                expenseValues,
                                maxValue,
                                value,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                        Row(
                          children: labels
                              .map(
                                (label) => Expanded(
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
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

class _CashflowPainter extends CustomPainter {
  _CashflowPainter(this.income, this.expense, this.maxValue, this.progress);
  final List<int> income;
  final List<int> expense;
  final int maxValue;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x227F8C8D)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    void drawLine(List<int> values, Color color) {
      final path = Path();
      final points = <Offset>[];
      for (var i = 0; i < values.length; i++) {
        final x = values.length == 1
            ? size.width / 2
            : size.width * i / (values.length - 1);
        final y =
            size.height -
            (values[i] / maxValue) * size.height * .88 -
            size.height * .06;
        points.add(Offset(x, y));
        if (i == 0)
          path.moveTo(x, y);
        else
          path.lineTo(x, y);
      }
      final reveal = path.computeMetrics().first;
      final visible = reveal.extractPath(0, reveal.length * progress);
      final line = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(visible, line);
      final dot = Paint()..color = color;
      for (final p in points) canvas.drawCircle(p, 4, dot);
    }

    drawLine(income, const Color(0xFF159B7D));
    drawLine(expense, const Color(0xFFE76F51));
  }

  @override
  bool shouldRepaint(covariant _CashflowPainter oldDelegate) => true;
}
