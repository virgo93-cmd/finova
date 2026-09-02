import 'package:finova/core/models/models.dart';
import 'package:finova/core/services/ad_service.dart';
import 'package:finova/core/services/calculations.dart';
import 'package:finova/core/utils/formatters.dart';
import 'package:finova/core/widgets/common_widgets.dart';
import 'package:finova/features/screens/finance_screens.dart';
import 'package:finova/features/state/finova_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ProductivityPage extends ConsumerStatefulWidget {
  const ProductivityPage({super.key});
  @override
  ConsumerState<ProductivityPage> createState() => _ProductivityPageState();
}

class _ProductivityPageState extends ConsumerState<ProductivityPage> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(finovaControllerProvider).value;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produktivitas',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('Tugas'),
                      icon: Icon(Icons.task_alt),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Kebiasaan'),
                      icon: Icon(Icons.repeat),
                    ),
                  ],
                  selected: {tab},
                  onSelectionChanged: (v) => setState(() => tab = v.first),
                ),
              ],
            ),
          ),
          Expanded(child: tab == 0 ? _tasks(state) : _habits(state)),
        ],
      ),
    );
  }

  Widget _tasks(FinovaState? s) {
    if (s == null) return const Center(child: CircularProgressIndicator());
    if (s.tasks.isEmpty) {
      return EmptyState(
        icon: Icons.task_alt,
        title: 'Hari Anda masih kosong.',
        message: 'Tambahkan tugas saat ada hal yang perlu dikerjakan.',
        action: FilledButton.icon(
          onPressed: () => TaskFormPage.show(context),
          icon: const Icon(Icons.add),
          label: const Text('Tambah tugas'),
        ),
      );
    }
    final today = dateOnly(DateTime.now());
    final open = s.tasks.where(
      (t) => !t.completed && dateOnly(t.dueDate) == today,
    );
    final upcoming = s.tasks.where(
      (t) => !t.completed && t.dueDate.isAfter(today),
    );
    final done = s.tasks.where((t) => t.completed);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
      children: [
        Text('${done.length} dari ${s.tasks.length} selesai'),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: taskCompletion(s.tasks)),
        _taskSection('Hari ini', open),
        _taskSection('Mendatang', upcoming),
        _taskSection('Selesai', done),
        FinovaBannerAd(enabled: s.settings.adsEnabled),
      ],
    );
  }

  Widget _taskSection(String title, Iterable<FinovaTask> tasks) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 6),
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      if (tasks.isEmpty)
        Text('Belum ada data', style: Theme.of(context).textTheme.bodySmall)
      else
        ...tasks.map(
          (t) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Checkbox(
              value: t.completed,
              onChanged: (_) =>
                  ref.read(finovaControllerProvider.notifier).toggleTask(t),
            ),
            title: Text(
              t.title,
              style: TextStyle(
                decoration: t.completed ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              '${DateFormat.MMMd().format(t.dueDate)} • ${t.priority.name}',
            ),
            onTap: () => TaskFormPage.show(context, item: t),
            trailing: IconButton(
              onPressed: () async {
                if (await confirmDelete(context, 'Hapus tugas ini?')) {
                  ref.read(finovaControllerProvider.notifier).deleteTask(t.id);
                }
              },
              icon: const Icon(Icons.more_horiz),
            ),
          ),
        ),
    ],
  );
  Widget _habits(FinovaState? s) {
    if (s == null) return const Center(child: CircularProgressIndicator());
    if (s.habits.isEmpty) {
      return EmptyState(
        icon: Icons.repeat,
        title: 'Bangun kebiasaan pertama Anda.',
        message: 'Rutinitas kecil menghasilkan perubahan besar.',
        action: FilledButton.icon(
          onPressed: () => HabitFormPage.show(context),
          icon: const Icon(Icons.add),
          label: const Text('Tambah kebiasaan'),
        ),
      );
    }
    final today = dateOnly(DateTime.now());
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        ...s.habits.map((h) {
          final checked = h.logDates.map(dateOnly).contains(today);
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(child: Text(h.icon)),
              title: Text(h.title),
              subtitle: Text(
                'Beruntun ${currentHabitStreak(h)} hari • Terbaik ${longestHabitStreak(h)}',
              ),
              trailing: Checkbox(
                value: checked,
                onChanged: (_) {
                  ref.read(finovaControllerProvider.notifier).toggleHabit(h);
                  if (!checked) AdService.meaningfulAction();
                },
              ),
              onTap: () => HabitFormPage.show(context, item: h),
              onLongPress: () async {
                if (await confirmDelete(
                  context,
                  'Hapus kebiasaan ini beserta riwayatnya?',
                )) {
                  ref.read(finovaControllerProvider.notifier).deleteHabit(h.id);
                }
              },
            ),
          );
        }),
        const SizedBox(height: 18),
        FinovaBannerAd(enabled: s.settings.adsEnabled),
      ],
    );
  }
}

class TaskFormPage extends ConsumerStatefulWidget {
  const TaskFormPage({super.key, this.item});
  final FinovaTask? item;
  static Future<void> show(BuildContext c, {FinovaTask? item}) =>
      Navigator.push(
        c,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => TaskFormPage(item: item),
        ),
      );
  @override
  ConsumerState<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends ConsumerState<TaskFormPage> {
  final title = TextEditingController();
  final notes = TextEditingController();
  DateTime due = DateTime.now();
  TaskPriority priority = TaskPriority.medium;
  @override
  void initState() {
    super.initState();
    final x = widget.item;
    if (x != null) {
      title.text = x.title;
      notes.text = x.notes;
      due = x.dueDate;
      priority = x.priority;
    }
  }

  @override
  void dispose() {
    title.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.item == null ? 'Tambah tugas' : 'Ubah tugas'),
      actions: [TextButton(onPressed: _save, child: const Text('Simpan'))],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: title,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Judul tugas'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: notes,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<TaskPriority>(
          initialValue: priority,
          decoration: const InputDecoration(labelText: 'Prioritas'),
          items: TaskPriority.values
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(switch (v) {
                    TaskPriority.low => 'Rendah',
                    TaskPriority.medium => 'Sedang',
                    TaskPriority.high => 'Tinggi',
                  }),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => priority = v!),
        ),
        const SizedBox(height: 14),
        ListTile(
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Tenggat waktu'),
          subtitle: Text(DateFormat.yMMMd().format(due)),
          onTap: () async {
            final x = await showDatePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              initialDate: due,
            );
            if (x != null) setState(() => due = x);
          },
        ),
      ],
    ),
  );
  Future<void> _save() async {
    if (title.text.trim().isEmpty) return;
    await ref
        .read(finovaControllerProvider.notifier)
        .saveTask(
          id: widget.item?.id,
          title: title.text,
          notes: notes.text,
          dueDate: due,
          priority: priority,
        );
    AdService.meaningfulAction();
    if (mounted) Navigator.pop(context);
  }
}

class HabitFormPage extends ConsumerStatefulWidget {
  const HabitFormPage({super.key, this.item});
  final Habit? item;
  static Future<void> show(BuildContext c, {Habit? item}) => Navigator.push(
    c,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => HabitFormPage(item: item),
    ),
  );
  @override
  ConsumerState<HabitFormPage> createState() => _HabitFormPageState();
}

class _HabitFormPageState extends ConsumerState<HabitFormPage> {
  final title = TextEditingController();
  String icon = '✨';
  HabitFrequency frequency = HabitFrequency.daily;
  Set<int> days = {1, 2, 3, 4, 5};
  @override
  void initState() {
    super.initState();
    final x = widget.item;
    if (x != null) {
      title.text = x.title;
      icon = x.icon;
      frequency = x.frequency;
      days = {...x.selectedDays};
    }
  }

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.item == null ? 'Tambah kebiasaan' : 'Ubah kebiasaan'),
      actions: [TextButton(onPressed: _save, child: const Text('Simpan'))],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: title,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama kebiasaan'),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: icon,
          decoration: const InputDecoration(labelText: 'Ikon'),
          items: [
            '✨',
            '💧',
            '🏃',
            '📚',
            '🧘',
            '💊',
            '🌿',
          ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => icon = v!),
        ),
        const SizedBox(height: 14),
        SegmentedButton<HabitFrequency>(
          segments: const [
            ButtonSegment(
              value: HabitFrequency.daily,
              label: Text('Setiap hari'),
            ),
            ButtonSegment(
              value: HabitFrequency.selectedDays,
              label: Text('Hari tertentu'),
            ),
          ],
          selected: {frequency},
          onSelectionChanged: (v) => setState(() => frequency = v.first),
        ),
        if (frequency == HabitFrequency.selectedDays) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 5,
            children: List.generate(7, (i) {
              final day = i + 1;
              return FilterChip(
                label: Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][i]),
                selected: days.contains(day),
                onSelected: (v) =>
                    setState(() => v ? days.add(day) : days.remove(day)),
              );
            }),
          ),
        ],
      ],
    ),
  );
  Future<void> _save() async {
    if (title.text.trim().isEmpty ||
        (frequency == HabitFrequency.selectedDays && days.isEmpty)) {
      return;
    }
    await ref
        .read(finovaControllerProvider.notifier)
        .saveHabit(
          id: widget.item?.id,
          title: title.text,
          icon: icon,
          frequency: frequency,
          selectedDays: frequency == HabitFrequency.daily ? {} : days,
        );
    if (mounted) Navigator.pop(context);
  }
}

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});
  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  int tab = 0;
  int days = 30;
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(finovaControllerProvider).value;
    if (s == null) return const Center(child: CircularProgressIndicator());
    final start = DateTime.now().subtract(Duration(days: days));
    final tx = s.transactions.where((t) => t.date.isAfter(start));
    final summary = calculateFinance(tx);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          Text(
            'Insight',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Keuangan')),
              ButtonSegment(value: 1, label: Text('Produktivitas')),
            ],
            selected: {tab},
            onSelectionChanged: (v) => setState(() => tab = v.first),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: [7, 30, 90]
                .map(
                  (v) => ChoiceChip(
                    label: Text('$v hari'),
                    selected: days == v,
                    onSelected: (_) => setState(() => days = v),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          if (tab == 0)
            ..._finance(context, s, tx, summary)
          else
            ..._productivity(context, s, start),
          const SizedBox(height: 20),
          FinovaBannerAd(enabled: s.settings.adsEnabled),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => AdService.showRewarded(
              onReward: () {
                if (mounted) {
                  showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Insight tambahan'),
                      content: Text(
                        summary.expense > summary.income
                            ? 'Pengeluaran Anda lebih besar daripada pemasukan pada periode ini. Tinjau kategori terbesar dan pertimbangkan anggaran yang lebih ketat.'
                            : 'Arus kas bersih Anda positif pada periode ini. Pertimbangkan mengalokasikan sebagian selisih untuk tujuan atau dana darurat.',
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Selesai'),
                        ),
                      ],
                    ),
                  );
                }
              },
              onUnavailable: () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Iklan berbonus belum tersedia saat ini.'),
                    ),
                  );
                }
              },
            ),
            icon: const Icon(Icons.ondemand_video_outlined),
            label: const Text('Tonton iklan untuk insight tambahan'),
          ),
        ],
      ),
    );
  }

  List<Widget> _finance(
    BuildContext c,
    FinovaState s,
    Iterable<MoneyTransaction> tx,
    FinanceSummary sum,
  ) {
    final by = <String, int>{};
    for (final t in tx.where((x) => x.type == TransactionType.expense)) {
      by[t.categoryName] = (by[t.categoryName] ?? 0) + t.amount;
    }
    final sorted = by.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (tx.isEmpty) {
      return [
        const EmptyState(
          icon: Icons.insights_outlined,
          title: 'Data belum cukup.',
          message: 'Terus lakukan pencatatan dan insight akan muncul di sini.',
        ),
      ];
    }
    return [
      _stats(c, [
        ('Pemasukan', sum.income),
        ('Pengeluaran', sum.expense),
        ('Bersih', sum.balance),
      ], s.settings.currency),
      const SizedBox(height: 22),
      const SectionTitle('Pengeluaran per kategori'),
      ...sorted.map(
        (e) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(e.key),
          trailing: Text(formatMoney(e.value, s.settings.currency)),
          subtitle: LinearProgressIndicator(
            value: sum.expense == 0 ? 0 : e.value / sum.expense,
          ),
        ),
      ),
    ];
  }

  List<Widget> _productivity(BuildContext c, FinovaState s, DateTime start) {
    final tasks = s.tasks.where((t) => t.createdAt.isAfter(start)).toList();
    final logs = s.habits
        .expand((h) => h.logDates)
        .where((d) => d.isAfter(start))
        .length;
    return [
      _stats(c, [
        ('Tugas selesai', tasks.where((t) => t.completed).length),
        ('Rasio tugas', (taskCompletion(tasks) * 100).round()),
        ('Catatan kebiasaan', logs),
      ], ''),
      const SizedBox(height: 22),
      const SectionTitle('Rangkaian aktif'),
      ...s.habits.map(
        (h) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Text(h.icon, style: const TextStyle(fontSize: 24)),
          title: Text(h.title),
          trailing: Text('${currentHabitStreak(h)} hari'),
        ),
      ),
    ];
  }

  Widget _stats(BuildContext c, List<(String, int)> values, String currency) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: values
                .map(
                  (x) => Expanded(
                    child: Column(
                      children: [
                        Text(x.$1, style: Theme.of(c).textTheme.labelMedium),
                        const SizedBox(height: 5),
                        Text(
                          currency.isEmpty
                              ? x.$2.toString()
                              : formatMoney(x.$2, currency),
                          style: Theme.of(c).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );
}
