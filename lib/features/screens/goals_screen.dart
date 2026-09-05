import 'package:finova/core/models/models.dart';
import 'package:finova/core/utils/formatters.dart';
import 'package:finova/core/widgets/common_widgets.dart';
import 'package:finova/features/screens/finance_screens.dart';
import 'package:finova/features/state/finova_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(finovaControllerProvider).value;
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Target keuangan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => GoalFormPage.show(context),
        icon: const Icon(Icons.add),
        label: const Text('Target baru'),
      ),
      body: state.goals.isEmpty
          ? EmptyState(
              icon: Icons.flag_outlined,
              title: 'Tetapkan target pertama',
              message:
                  'Pantau tabungan untuk dana darurat, liburan, atau tujuan lainnya.',
              action: FilledButton(
                onPressed: () => GoalFormPage.show(context),
                child: const Text('Buat target'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: state.goals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final goal = state.goals[index];
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => GoalFormPage.show(context, goal: goal),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  goal.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text('${(goal.progress * 100).round()}%'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(value: goal.progress),
                          const SizedBox(height: 10),
                          Text(
                            '${formatMoney(goal.currentAmount, state.settings.currency)} dari ${formatMoney(goal.targetAmount, state.settings.currency)}',
                          ),
                          if (goal.targetDate != null)
                            Text(
                              'Target ${goal.targetDate!.day}/${goal.targetDate!.month}/${goal.targetDate!.year}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (!goal.progress.isNaN && goal.progress < 1)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _addContribution(
                                  context,
                                  ref,
                                  goal,
                                  state.settings.currency,
                                ),
                                icon: const Icon(Icons.add_card_outlined),
                                label: const Text('Tambah setoran'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _addContribution(
    BuildContext context,
    WidgetRef ref,
    SavingsGoal goal,
    String currency,
  ) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final result = await showDialog<(int, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Setoran · ${goal.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Nominal',
                helperText: 'Sisa ${formatMoney(goal.remaining, currency)}',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, (
              int.tryParse(amountController.text) ?? 0,
              noteController.text,
            )),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    amountController.dispose();
    noteController.dispose();
    if (result == null || result.$1 <= 0 || !context.mounted) return;
    await ref
        .read(finovaControllerProvider.notifier)
        .addGoalContribution(goal, result.$1, result.$2);
  }
}

class GoalFormPage extends ConsumerStatefulWidget {
  const GoalFormPage({super.key, this.goal});
  final SavingsGoal? goal;

  static Future<void> show(BuildContext context, {SavingsGoal? goal}) =>
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GoalFormPage(goal: goal)),
      );

  @override
  ConsumerState<GoalFormPage> createState() => _GoalFormPageState();
}

class _GoalFormPageState extends ConsumerState<GoalFormPage> {
  late final TextEditingController title;
  late final TextEditingController target;
  late final TextEditingController current;
  DateTime? targetDate;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.goal?.title);
    target = TextEditingController(text: widget.goal?.targetAmount.toString());
    current = TextEditingController(
      text: widget.goal?.currentAmount.toString() ?? '0',
    );
    targetDate = widget.goal?.targetDate;
  }

  @override
  void dispose() {
    title.dispose();
    target.dispose();
    current.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(finovaControllerProvider).value;
    final history = widget.goal == null || state == null
        ? const <GoalContribution>[]
        : state.goalContributions
              .where((entry) => entry.goalId == widget.goal!.id)
              .toList();
    final currency = state?.settings.currency ?? 'IDR';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal == null ? 'Target baru' : 'Ubah target'),
        actions: [
          if (widget.goal != null)
            IconButton(
              tooltip: 'Hapus',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: title,
            autofocus: widget.goal == null,
            decoration: const InputDecoration(
              labelText: 'Nama target',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: target,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Nominal target'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: current,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Sudah terkumpul'),
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(
              targetDate == null
                  ? 'Tanpa batas waktu'
                  : '${targetDate!.day}/${targetDate!.month}/${targetDate!.year}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickDate,
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Simpan target')),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 28),
            const SectionTitle('Riwayat setoran'),
            ...history.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Icon(entry.amount >= 0 ? Icons.add : Icons.remove),
                ),
                title: Text(entry.note),
                subtitle: Text(
                  '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                ),
                trailing: Text(
                  '${entry.amount >= 0 ? '+' : ''}${formatMoney(entry.amount, currency)}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: targetDate ?? DateTime.now().add(const Duration(days: 90)),
    );
    if (value != null) setState(() => targetDate = value);
  }

  Future<void> _save() async {
    final targetValue = int.tryParse(target.text) ?? 0;
    final currentValue = int.tryParse(current.text) ?? 0;
    if (title.text.trim().isEmpty || targetValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan nominal target wajib diisi.')),
      );
      return;
    }
    await ref
        .read(finovaControllerProvider.notifier)
        .saveGoal(
          id: widget.goal?.id,
          title: title.text,
          targetAmount: targetValue,
          currentAmount: currentValue,
          targetDate: targetDate,
        );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    if (!await confirmDelete(context, 'Hapus target ${widget.goal!.title}?')) {
      return;
    }
    await ref
        .read(finovaControllerProvider.notifier)
        .deleteGoal(widget.goal!.id);
    if (mounted) Navigator.pop(context);
  }
}
