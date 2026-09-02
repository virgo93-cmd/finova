import 'package:finova/core/models/models.dart';
import 'package:finova/core/services/ad_service.dart';
import 'package:finova/core/utils/formatters.dart';
import 'package:finova/core/widgets/common_widgets.dart';
import 'package:finova/features/state/finova_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/* Legacy inline dashboard retained temporarily for migration reference.
class HomePage extends ConsumerWidget{const HomePage({super.key});
  @override Widget build(BuildContext context,WidgetRef ref){final async=ref.watch(finovaControllerProvider);return async.when(loading:()=>const Center(child:CircularProgressIndicator()),error:(e,_)=>Center(child:Text('$e')),data:(s){final now=DateTime.now();final month=s.transactions.where((t)=>t.date.year==now.year&&t.date.month==now.month);final all=calculateFinance(s.transactions,initialBalance:s.settings.initialBalance);final current=calculateFinance(month);final today=s.tasks.where((t)=>dateOnly(t.dueDate)==dateOnly(now)).toList();final budget=s.budgets.where((b)=>b.categoryId==null&&b.month.year==now.year&&b.month.month==now.month).firstOrNull;final spent=current.expense;return SafeArea(child:RefreshIndicator(onRefresh:()=>ref.read(finovaControllerProvider.notifier).refresh(),child:ListView(padding:const EdgeInsets.fromLTRB(20,18,20,110),children:[Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(greeting(),style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w700)),const Text("Here's your day at a glance.")])),IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SettingsPage())),icon:const Icon(Icons.settings_outlined))]),const SizedBox(height:22),Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF087F68),Color(0xFF075C50)]),borderRadius:BorderRadius.circular(24)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Current balance',style:TextStyle(color:Colors.white70)),const SizedBox(height:6),Text(formatMoney(all.balance,s.settings.currency),style:Theme.of(context).textTheme.headlineMedium?.copyWith(color:Colors.white,fontWeight:FontWeight.w800)),const SizedBox(height:22),Row(children:[Expanded(child:_metric('Income this month',formatMoney(current.income,s.settings.currency),Colors.greenAccent)),Expanded(child:_metric('Expense this month',formatMoney(current.expense,s.settings.currency),Colors.orangeAccent))])])),const SizedBox(height:24),SectionTitle('Monthly budget',action:budget==null?'Set budget':'Edit',onAction:()=>BudgetFormPage.show(context)),const SizedBox(height:10),budget==null?const EmptyState(icon:Icons.savings_outlined,title:'Plan this month',message:'Set a monthly budget to keep spending in view.'):_budgetCard(context,budget.amount,spent,s.settings.currency),const SizedBox(height:24),const SectionTitle('Quick actions'),const SizedBox(height:12),Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[_quick(context,Icons.remove,'Expense',()=>TransactionFormPage.show(context,TransactionType.expense)),_quick(context,Icons.add,'Income',()=>TransactionFormPage.show(context,TransactionType.income)),_quick(context,Icons.task_alt,'Task',()=>TaskFormPage.show(context)),_quick(context,Icons.repeat,'Habit',()=>HabitFormPage.show(context))]),const SizedBox(height:28),const SectionTitle('Productivity today'),const SizedBox(height:10),Card(child:Padding(padding:const EdgeInsets.all(18),child:Row(children:[Icon(Icons.task_alt,color:Theme.of(context).colorScheme.primary),const SizedBox(width:12),Expanded(child:Text('${today.where((t)=>t.completed).length} of ${today.length} tasks completed')),SizedBox(width:70,child:LinearProgressIndicator(value:taskCompletion(today)))]))),const SizedBox(height:24),const SectionTitle('Recent transactions'),const SizedBox(height:8),if(s.transactions.isEmpty)const EmptyState(icon:Icons.receipt_long_outlined,title:'No transactions yet',message:'Start by adding your first expense or income.')else...s.transactions.take(5).map((t)=>TransactionTile(transaction:t,currency:s.settings.currency))]));});}
  Widget _metric(String label,String value,Color color)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(color:Colors.white70,fontSize:12)),const SizedBox(height:4),Text(value,style:TextStyle(color:color,fontWeight:FontWeight.w700))]);
  Widget _quick(BuildContext c,IconData icon,String label,VoidCallback tap)=>InkWell(onTap:tap,borderRadius:BorderRadius.circular(16),child:Padding(padding:const EdgeInsets.all(8),child:Column(children:[CircleAvatar(child:Icon(icon)),const SizedBox(height:6),Text(label,style:Theme.of(c).textTheme.labelMedium)])));
  Widget _budgetCard(BuildContext c,int amount,int spent,String currency){final p=budgetProgress(spent:spent,budget:amount);return Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[Row(children:[Text(formatMoney(spent,currency),style:Theme.of(c).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w700)),const Spacer(),Text('${(p*100).round()}%')]),const SizedBox(height:10),LinearProgressIndicator(value:p.clamp(0,1),color:p>1?Theme.of(c).colorScheme.error:p>.8?Colors.amber:null),const SizedBox(height:8),Align(alignment:Alignment.centerLeft,child:Text('${formatMoney((amount-spent).clamp(0,amount),currency)} remaining'))])));}
}

*/
class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});
  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  TransactionType? type;
  String query = '';
  String period = 'Month';
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(finovaControllerProvider);
    return SafeArea(
      child: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('$e'),
        data: (s) {
          final now = DateTime.now();
          final start = period == 'Week'
              ? now.subtract(const Duration(days: 7))
              : DateTime(now.year, now.month);
          final filtered = s.transactions
              .where(
                (t) =>
                    (type == null || t.type == type) &&
                    t.date.isAfter(
                      start.subtract(const Duration(seconds: 1)),
                    ) &&
                    (query.isEmpty ||
                        t.note.toLowerCase().contains(query.toLowerCase()) ||
                        t.categoryName.toLowerCase().contains(
                          query.toLowerCase(),
                        )),
              )
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Transaksi',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => CategoriesPage.show(context),
                          icon: const Icon(Icons.category_outlined),
                        ),
                      ],
                    ),
                    TextField(
                      onChanged: (v) => setState(() => query = v),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Cari transaksi',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ...[
                          (null, 'Semua'),
                          (TransactionType.income, 'Pemasukan'),
                          (TransactionType.expense, 'Pengeluaran'),
                        ].map(
                          (x) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(x.$2),
                              selected: type == x.$1,
                              onSelected: (_) => setState(() => type = x.$1),
                            ),
                          ),
                        ),
                        const Spacer(),
                        DropdownButton<String>(
                          value: period,
                          items: ['Minggu', 'Bulan']
                              .map(
                                (x) =>
                                    DropdownMenuItem(value: x, child: Text(x)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => period = v!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Transaksi tidak ditemukan',
                        message: 'Ubah filter atau tambahkan catatan baru.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        itemCount: filtered.length + 1,
                        itemBuilder: (c, i) => i == filtered.length
                            ? FinovaBannerAd(enabled: s.settings.adsEnabled)
                            : TransactionTile(
                                transaction: filtered[i],
                                currency: s.settings.currency,
                                onTap: () => TransactionDetailPage.show(
                                  context,
                                  filtered[i],
                                ),
                              ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.currency,
    this.onTap,
  });
  final MoneyTransaction transaction;
  final String currency;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final income = transaction.type == TransactionType.income;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: (income ? Colors.green : Colors.red).withValues(
          alpha: .12,
        ),
        child: Icon(
          income ? Icons.south_west : Icons.north_east,
          color: income ? Colors.green : Colors.red,
        ),
      ),
      title: Text(
        transaction.note.isEmpty ? transaction.categoryName : transaction.note,
      ),
      subtitle: Text(
        '${transaction.categoryName} • ${DateFormat.MMMd().format(transaction.date)}',
      ),
      trailing: Text(
        '${income ? '+' : '-'}${formatMoney(transaction.amount, currency)}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: income
              ? Colors.green
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key, required this.type, this.item});
  final TransactionType type;
  final MoneyTransaction? item;
  static Future<void> show(
    BuildContext c,
    TransactionType type, {
    MoneyTransaction? item,
  }) => Navigator.push(
    c,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => TransactionFormPage(type: type, item: item),
    ),
  );
  @override
  ConsumerState<TransactionFormPage> createState() =>
      _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final amount = TextEditingController();
  final note = TextEditingController();
  int? category;
  DateTime date = DateTime.now();
  @override
  void initState() {
    super.initState();
    final x = widget.item;
    if (x != null) {
      amount.text = x.amount.toString();
      note.text = x.note;
      category = x.categoryId;
      date = x.date;
    }
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(finovaControllerProvider).value;
    final cats =
        state?.categories.where((c) => c.type == widget.type).toList() ?? [];
    category ??= cats.firstOrNull?.id;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.item == null ? 'Tambah' : 'Ubah'} ${widget.type == TransactionType.income ? 'pemasukan' : 'pengeluaran'}',
        ),
        actions: [
          TextButton(
            onPressed: category == null ? null : _save,
            child: const Text('Simpan'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: amount,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: 'Nominal',
              prefixText: '${state?.settings.currency ?? ''} ',
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Kategori'),
            items: cats
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() => category = v),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: note,
            decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
          ),
          const SizedBox(height: 14),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            title: const Text('Tanggal'),
            subtitle: Text(DateFormat.yMMMd().format(date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: date,
    );
    if (value != null) setState(() => date = value);
  }

  Future<void> _save() async {
    final value =
        int.tryParse(amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal lebih dari nol.')),
      );
      return;
    }
    await ref
        .read(finovaControllerProvider.notifier)
        .saveTransaction(
          id: widget.item?.id,
          type: widget.type,
          amount: value,
          categoryId: category!,
          note: note.text,
          date: date,
        );
    AdService.meaningfulAction();
    if (mounted) Navigator.pop(context);
  }
}

class TransactionDetailPage extends ConsumerWidget {
  const TransactionDetailPage({super.key, required this.item});
  final MoneyTransaction item;
  static Future<void> show(BuildContext c, MoneyTransaction item) =>
      Navigator.push(
        c,
        MaterialPageRoute(builder: (_) => TransactionDetailPage(item: item)),
      );
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency =
        ref.watch(finovaControllerProvider).value?.settings.currency ?? 'IDR';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        actions: [
          IconButton(
            onPressed: () =>
                TransactionFormPage.show(context, item.type, item: item),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () async {
              if (await confirmDelete(context, 'Hapus transaksi ini?')) {
                await ref
                    .read(finovaControllerProvider.notifier)
                    .deleteTransaction(item.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatMoney(item.amount, currency),
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: Text(item.categoryName),
            ),
            ListTile(
              leading: const Icon(Icons.notes),
              title: Text(item.note.isEmpty ? 'Tanpa catatan' : item.note),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat.yMMMMd().format(item.date)),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmDelete(BuildContext context, String message) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Mohon konfirmasi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    ) ??
    false;

class BudgetFormPage extends ConsumerStatefulWidget {
  const BudgetFormPage({super.key});
  static Future<void> show(BuildContext c) => Navigator.push(
    c,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const BudgetFormPage(),
    ),
  );
  @override
  ConsumerState<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends ConsumerState<BudgetFormPage> {
  final amount = TextEditingController();
  int? category;
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats =
        ref
            .watch(finovaControllerProvider)
            .value
            ?.categories
            .where((c) => c.type == TransactionType.expense)
            .toList() ??
        [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur anggaran'),
        actions: [TextButton(onPressed: _save, child: const Text('Simpan'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: amount,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nominal anggaran'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Cakupan'),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Anggaran bulanan keseluruhan'),
              ),
              ...cats.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: (v) => setState(() => category = v),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final value =
        int.tryParse(amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (value <= 0) return;
    await ref
        .read(finovaControllerProvider.notifier)
        .saveBudget(value, DateTime.now(), categoryId: category);
    if (mounted) Navigator.pop(context);
  }
}

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});
  static Future<void> show(BuildContext c) => Navigator.push(
    c,
    MaterialPageRoute(builder: (_) => const CategoriesPage()),
  );
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(finovaControllerProvider).value?.categories ?? [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
        actions: [
          IconButton(
            onPressed: () => _edit(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final type in TransactionType.values) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                type.name.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            ...cats
                .where((c) => c.type == type)
                .map(
                  (c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.label_outline),
                    ),
                    title: Text(c.name),
                    subtitle: Text(
                      c.isSystem ? 'Kategori bawaan' : 'Kategori khusus',
                    ),
                    trailing: c.isSystem
                        ? null
                        : PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'rename') {
                                _edit(context, ref, item: c);
                              } else if (await confirmDelete(
                                context,
                                'Hapus ${c.name}?',
                              )) {
                                try {
                                  await ref
                                      .read(finovaControllerProvider.notifier)
                                      .deleteCategory(c.id);
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Kategori ini sedang digunakan oleh transaksi.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'rename',
                                child: Text('Ubah nama'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus'),
                              ),
                            ],
                          ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    Category? item,
  }) async {
    final text = TextEditingController(text: item?.name);
    var type = item?.type ?? TransactionType.expense;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(item == null ? 'Kategori baru' : 'Ubah nama kategori'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: text,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              if (item == null) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<TransactionType>(
                  initialValue: type,
                  items: TransactionType.values
                      .map(
                        (v) => DropdownMenuItem(value: v, child: Text(v.name)),
                      )
                      .toList(),
                  onChanged: (v) => set(() => type = v!),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && text.text.trim().isNotEmpty) {
      if (item == null) {
        await ref
            .read(finovaControllerProvider.notifier)
            .addCategory(text.text, type);
      } else {
        await ref
            .read(finovaControllerProvider.notifier)
            .renameCategory(item.id, text.text);
      }
    }
    text.dispose();
  }
}
