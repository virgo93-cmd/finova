import 'package:finova/core/models/models.dart';
import 'package:finova/core/utils/formatters.dart';
import 'package:finova/core/widgets/common_widgets.dart';
import 'package:finova/features/screens/finance_screens.dart';
import 'package:finova/features/state/finova_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DebtPage extends ConsumerStatefulWidget {
  const DebtPage({super.key});

  @override
  ConsumerState<DebtPage> createState() => _DebtPageState();
}

class _DebtPageState extends ConsumerState<DebtPage> {
  DebtType type = DebtType.receivable;
  bool showSettled = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(finovaControllerProvider).value;
    if (state == null) return const Center(child: CircularProgressIndicator());
    final currency = state.settings.currency;
    final debts = state.debts
        .where((item) => item.type == type && (showSettled || !item.isSettled))
        .toList();
    final receivable = state.debts
        .where((item) => item.type == DebtType.receivable)
        .fold<int>(0, (sum, item) => sum + item.remaining);
    final payable = state.debts
        .where((item) => item.type == DebtType.payable)
        .fold<int>(0, (sum, item) => sum + item.remaining);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hutang & Piutang',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      tooltip: 'Tambah catatan',
                      onPressed: () =>
                          DebtFormPage.show(context, initialType: type),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        context,
                        'Akan diterima',
                        receivable,
                        currency,
                        Icons.south_west,
                        const Color(0xFF087F68),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _summaryCard(
                        context,
                        'Harus dibayar',
                        payable,
                        currency,
                        Icons.north_east,
                        const Color(0xFFE56B5D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentedButton<DebtType>(
                  segments: const [
                    ButtonSegment(
                      value: DebtType.receivable,
                      label: Text('Piutang'),
                      icon: Icon(Icons.call_received),
                    ),
                    ButtonSegment(
                      value: DebtType.payable,
                      label: Text('Hutang'),
                      icon: Icon(Icons.call_made),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (value) =>
                      setState(() => type = value.first),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tampilkan yang sudah lunas'),
                  value: showSettled,
                  onChanged: (value) => setState(() => showSettled = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: debts.isEmpty
                ? EmptyState(
                    icon: type == DebtType.receivable
                        ? Icons.handshake_outlined
                        : Icons.receipt_long_outlined,
                    title: type == DebtType.receivable
                        ? 'Belum ada piutang'
                        : 'Belum ada hutang',
                    message: type == DebtType.receivable
                        ? 'Catat uang yang perlu dikembalikan kepada Anda.'
                        : 'Catat kewajiban agar tidak melewati jatuh tempo.',
                    action: FilledButton.icon(
                      onPressed: () =>
                          DebtFormPage.show(context, initialType: type),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah catatan'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 120),
                    itemCount: debts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _DebtCard(debt: debts[index], currency: currency),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    String label,
    int value,
    String currency,
    IconData icon,
    Color color,
  ) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 12),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 3),
        Text(
          formatMoney(value, currency),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _DebtCard extends ConsumerWidget {
  const _DebtCard({required this.debt, required this.currency});
  final DebtRecord debt;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments =
        ref
            .watch(finovaControllerProvider)
            .value
            ?.debtPayments
            .where((entry) => entry.debtId == debt.id)
            .toList() ??
        const <DebtPayment>[];
    final overdue = !debt.isSettled && debt.dueDate.isBefore(DateTime.now());
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => DebtFormPage.show(context, item: debt),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(debt.person.characters.first.toUpperCase()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.person,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          debt.isSettled
                              ? 'Lunas'
                              : overdue
                              ? 'Terlambat · ${DateFormat('d MMM y', 'id_ID').format(debt.dueDate)}'
                              : 'Jatuh tempo ${DateFormat('d MMM y', 'id_ID').format(debt.dueDate)}',
                          style: TextStyle(
                            color: overdue
                                ? Theme.of(context).colorScheme.error
                                : null,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatMoney(debt.remaining, currency),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              LinearProgressIndicator(
                value: debt.amount == 0 ? 0 : debt.paidAmount / debt.amount,
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Text(
                    'Terbayar ${formatMoney(debt.paidAmount, currency)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: 'Tindakan',
                    onSelected: (value) async {
                      if (value == 'payment') {
                        _recordPayment(context, ref);
                      } else if (value == 'history') {
                        _showHistory(context, payments);
                      } else if (value == 'settle') {
                        await ref
                            .read(finovaControllerProvider.notifier)
                            .updateDebtPayment(debt, debt.amount);
                      } else if (value == 'delete' &&
                          await confirmDelete(context, 'Hapus catatan ini?')) {
                        await ref
                            .read(finovaControllerProvider.notifier)
                            .deleteDebt(debt.id);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'history',
                        child: Text('Riwayat cicilan (${payments.length})'),
                      ),
                      if (!debt.isSettled)
                        const PopupMenuItem(
                          value: 'payment',
                          child: Text('Catat pembayaran'),
                        ),
                      if (!debt.isSettled)
                        const PopupMenuItem(
                          value: 'settle',
                          child: Text('Tandai lunas'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistory(BuildContext context, List<DebtPayment> payments) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Riwayat cicilan · ${debt.person}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (payments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: Text('Belum ada pembayaran tercatat.')),
                )
              else
                ...payments
                    .take(12)
                    .map(
                      (entry) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          child: Icon(Icons.payments_outlined),
                        ),
                        title: Text(entry.note),
                        subtitle: Text(
                          DateFormat(
                            'd MMM y, HH:mm',
                            'id_ID',
                          ).format(entry.date),
                        ),
                        trailing: Text(
                          '${entry.amount >= 0 ? '+' : ''}${formatMoney(entry.amount, currency)}',
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _recordPayment(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Catat pembayaran'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Nominal pembayaran',
            helperText: 'Sisa ${formatMoney(debt.remaining, currency)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final amount =
                  int.tryParse(
                    controller.text.replaceAll(RegExp(r'[^0-9]'), ''),
                  ) ??
                  0;
              Navigator.pop(dialogContext, amount);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value > 0 && context.mounted) {
      await ref
          .read(finovaControllerProvider.notifier)
          .updateDebtPayment(debt, debt.paidAmount + value);
    }
  }
}

class DebtFormPage extends ConsumerStatefulWidget {
  const DebtFormPage({
    super.key,
    this.item,
    this.initialType = DebtType.receivable,
  });
  final DebtRecord? item;
  final DebtType initialType;

  static Future<void> show(
    BuildContext context, {
    DebtRecord? item,
    DebtType initialType = DebtType.receivable,
  }) => Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => DebtFormPage(item: item, initialType: initialType),
    ),
  );

  @override
  ConsumerState<DebtFormPage> createState() => _DebtFormPageState();
}

class _DebtFormPageState extends ConsumerState<DebtFormPage> {
  final person = TextEditingController();
  final amount = TextEditingController();
  final paidAmount = TextEditingController();
  final note = TextEditingController();
  late DebtType type;
  DateTime dueDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    type = widget.item?.type ?? widget.initialType;
    final item = widget.item;
    if (item != null) {
      person.text = item.person;
      amount.text = item.amount.toString();
      paidAmount.text = item.paidAmount.toString();
      note.text = item.note;
      dueDate = item.dueDate;
    }
  }

  @override
  void dispose() {
    person.dispose();
    amount.dispose();
    paidAmount.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.item == null ? 'Tambah hutang/piutang' : 'Ubah catatan',
      ),
      actions: [TextButton(onPressed: _save, child: const Text('Simpan'))],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<DebtType>(
          segments: const [
            ButtonSegment(value: DebtType.receivable, label: Text('Piutang')),
            ButtonSegment(value: DebtType.payable, label: Text('Hutang')),
          ],
          selected: {type},
          onSelectionChanged: (value) => setState(() => type = value.first),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: person,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: type == DebtType.receivable
                ? 'Nama peminjam'
                : 'Nama pemberi pinjaman',
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Total nominal',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: paidAmount,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Sudah dibayar (opsional)',
            prefixIcon: Icon(Icons.check_circle_outline),
          ),
        ),
        const SizedBox(height: 14),
        ListTile(
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: const Icon(Icons.event_outlined),
          title: const Text('Tanggal jatuh tempo'),
          subtitle: Text(DateFormat('d MMMM y', 'id_ID').format(dueDate)),
          onTap: _pickDate,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: note,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Catatan (opsional)',
            prefixIcon: Icon(Icons.notes),
          ),
        ),
      ],
    ),
  );

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: dueDate,
      locale: const Locale('id', 'ID'),
    );
    if (selected != null) setState(() => dueDate = selected);
  }

  Future<void> _save() async {
    final total =
        int.tryParse(amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final paid =
        int.tryParse(paidAmount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (person.text.trim().isEmpty || total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama dan nominal lebih dari nol.')),
      );
      return;
    }
    await ref
        .read(finovaControllerProvider.notifier)
        .saveDebt(
          id: widget.item?.id,
          type: type,
          person: person.text,
          amount: total,
          paidAmount: paid,
          dueDate: dueDate,
          note: note.text,
        );
    if (mounted) Navigator.pop(context);
  }
}
