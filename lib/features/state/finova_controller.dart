import 'package:finova/core/database/finova_database.dart';
import 'package:finova/core/models/models.dart';
import 'package:finova/core/services/backup_service.dart';
import 'package:finova/core/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final databaseProvider = Provider<FinovaDatabase>(
  (ref) => throw UnimplementedError(),
);
final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);
final finovaControllerProvider =
    AsyncNotifierProvider<FinovaController, FinovaState>(FinovaController.new);

class FinovaState {
  const FinovaState({
    required this.categories,
    required this.transactions,
    required this.budgets,
    required this.tasks,
    required this.habits,
    required this.debts,
    required this.goals,
    required this.goalContributions,
    required this.debtPayments,
    required this.settings,
  });
  final List<Category> categories;
  final List<MoneyTransaction> transactions;
  final List<Budget> budgets;
  final List<FinovaTask> tasks;
  final List<Habit> habits;
  final List<DebtRecord> debts;
  final List<SavingsGoal> goals;
  final List<GoalContribution> goalContributions;
  final List<DebtPayment> debtPayments;
  final FinovaSettings settings;
}

class FinovaController extends AsyncNotifier<FinovaState> {
  FinovaDatabase get _db => ref.read(databaseProvider);
  SharedPreferences get _prefs => ref.read(preferencesProvider);

  @override
  Future<FinovaState> build() => _load();

  FinovaSettings _settings() => FinovaSettings(
    currency: _prefs.getString('currency') ?? 'IDR',
    initialBalance: _prefs.getInt('initial_balance') ?? 0,
    themeMode: AppThemeMode.values.byName(
      _prefs.getString('theme') ?? 'system',
    ),
    notificationsEnabled: _prefs.getBool('notifications') ?? false,
    adsEnabled: _prefs.getBool('ads_enabled') ?? true,
    onboardingComplete: _prefs.getBool('onboarding_complete') ?? false,
  );
  Future<FinovaState> _load() async => FinovaState(
    categories: await _db.categories(),
    transactions: await _db.transactions(),
    budgets: await _db.budgets(),
    tasks: await _db.tasks(),
    habits: await _db.habits(),
    debts: await _db.debts(),
    goals: await _db.goals(),
    goalContributions: await _db.goalContributions(),
    debtPayments: await _db.debtPayments(),
    settings: _settings(),
  );
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> _mutate(Future<void> Function() action) async {
    await action();
    state = await AsyncValue.guard(_load);
  }

  Future<void> completeOnboarding(String currency, int balance) async {
    await _prefs.setString('currency', currency);
    await _prefs.setInt('initial_balance', balance);
    await _prefs.setBool('onboarding_complete', true);
    state = await AsyncValue.guard(_load);
  }

  Future<void> updateSettings(FinovaSettings settings) async {
    await _prefs.setString('currency', settings.currency);
    await _prefs.setInt('initial_balance', settings.initialBalance);
    await _prefs.setString('theme', settings.themeMode.name);
    await _prefs.setBool('notifications', settings.notificationsEnabled);
    await _prefs.setBool('ads_enabled', settings.adsEnabled);
    final current = state.value;
    if (current != null) {
      if (settings.notificationsEnabled) {
        for (final task in current.tasks.where((item) => !item.completed)) {
          await NotificationService.scheduleTask(
            task.id,
            task.title,
            task.dueDate,
          );
        }
        for (final debt in current.debts.where((item) => !item.isSettled)) {
          await NotificationService.scheduleDebt(
            debt.id,
            debt.person,
            debt.dueDate,
            debt.type == DebtType.receivable,
          );
        }
        for (final habit in current.habits.where((item) => item.active)) {
          await NotificationService.scheduleHabit(habit.id, habit.title);
        }
      } else {
        for (final task in current.tasks) {
          await NotificationService.cancelTask(task.id);
        }
        for (final debt in current.debts) {
          await NotificationService.cancelDebt(debt.id);
        }
        for (final habit in current.habits) {
          await NotificationService.cancelHabit(habit.id);
        }
      }
    }
    state = await AsyncValue.guard(_load);
  }

  Future<void> saveTransaction({
    int? id,
    required TransactionType type,
    required int amount,
    required int categoryId,
    required String note,
    required DateTime date,
  }) => _mutate(
    () => _db.saveTransaction(
      id: id,
      type: type,
      amount: amount,
      categoryId: categoryId,
      note: note,
      date: date,
    ),
  );
  Future<void> deleteTransaction(int id) =>
      _mutate(() => _db.deleteTransaction(id));
  Future<void> addCategory(String name, TransactionType type) =>
      _mutate(() => _db.addCategory(name, type));
  Future<void> renameCategory(int id, String name) =>
      _mutate(() => _db.renameCategory(id, name));
  Future<void> deleteCategory(int id) => _mutate(() => _db.deleteCategory(id));
  Future<void> saveBudget(int amount, DateTime month, {int? categoryId}) =>
      _mutate(
        () => _db.saveBudget(
          amount: amount,
          month: month,
          categoryId: categoryId,
        ),
      );
  Future<void> saveTask({
    int? id,
    required String title,
    required String notes,
    required DateTime dueDate,
    required TaskPriority priority,
  }) async {
    final savedId = await _db.saveTask(
      id: id,
      title: title,
      notes: notes,
      dueDate: dueDate,
      priority: priority,
    );
    if (_settings().notificationsEnabled) {
      await NotificationService.scheduleTask(savedId, title, dueDate);
    }
    state = await AsyncValue.guard(_load);
  }

  Future<void> toggleTask(FinovaTask task) async {
    await _db.toggleTask(task);
    if (!task.completed) {
      await NotificationService.cancelTask(task.id);
    } else if (_settings().notificationsEnabled) {
      await NotificationService.scheduleTask(task.id, task.title, task.dueDate);
    }
    state = await AsyncValue.guard(_load);
  }

  Future<void> deleteTask(int id) async {
    await _db.deleteTask(id);
    await NotificationService.cancelTask(id);
    state = await AsyncValue.guard(_load);
  }

  Future<void> saveHabit({
    int? id,
    required String title,
    required String icon,
    required HabitFrequency frequency,
    required Set<int> selectedDays,
  }) async {
    final savedId = await _db.saveHabit(
      id: id,
      title: title,
      icon: icon,
      frequency: frequency,
      selectedDays: selectedDays,
    );
    if (_settings().notificationsEnabled) {
      await NotificationService.scheduleHabit(savedId, title);
    }
    state = await AsyncValue.guard(_load);
  }

  Future<void> toggleHabit(Habit habit) =>
      _mutate(() => _db.toggleHabitLog(habit, DateTime.now()));
  Future<void> deleteHabit(int id) async {
    await _db.deleteHabit(id);
    await NotificationService.cancelHabit(id);
    state = await AsyncValue.guard(_load);
  }

  Future<void> saveDebt({
    int? id,
    required DebtType type,
    required String person,
    required int amount,
    required int paidAmount,
    required DateTime dueDate,
    required String note,
  }) async {
    final savedId = await _db.saveDebt(
      id: id,
      type: type,
      person: person,
      amount: amount,
      paidAmount: paidAmount,
      dueDate: dueDate,
      note: note,
    );
    if (_settings().notificationsEnabled) {
      await NotificationService.scheduleDebt(
        savedId,
        person,
        dueDate,
        type == DebtType.receivable,
      );
    }
    state = await AsyncValue.guard(_load);
  }

  Future<void> updateDebtPayment(DebtRecord debt, int paidAmount) async {
    await _db.updateDebtPayment(debt.id, paidAmount, debt.amount);
    if (paidAmount >= debt.amount) {
      await NotificationService.cancelDebt(debt.id);
    }
    state = await AsyncValue.guard(_load);
  }

  Future<void> deleteDebt(int id) async {
    await _db.deleteDebt(id);
    await NotificationService.cancelDebt(id);
    state = await AsyncValue.guard(_load);
  }

  Future<void> saveGoal({
    int? id,
    required String title,
    required int targetAmount,
    required int currentAmount,
    DateTime? targetDate,
  }) => _mutate(
    () => _db.saveGoal(
      id: id,
      title: title,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetDate: targetDate,
    ),
  );
  Future<void> deleteGoal(int id) => _mutate(() => _db.deleteGoal(id));
  Future<void> addGoalContribution(SavingsGoal goal, int amount, String note) =>
      _mutate(() => _db.addGoalContribution(goal, amount, note));
  Future<DateTime> createCloudBackup() =>
      BackupService(_db, _prefs).createBackup();
  Future<DateTime> restoreCloudBackup() async {
    final restoredAt = await BackupService(_db, _prefs).restoreBackup();
    state = await AsyncValue.guard(_load);
    return restoredAt;
  }

  Future<void> resetAll() async {
    await NotificationService.cancelAll();
    await _db.resetAll();
    await _prefs.clear();
    state = await AsyncValue.guard(_load);
  }
}
