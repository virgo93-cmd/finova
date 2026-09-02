import 'package:finova/core/database/finova_database.dart';
import 'package:finova/core/models/models.dart';
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
    required this.settings,
  });
  final List<Category> categories;
  final List<MoneyTransaction> transactions;
  final List<Budget> budgets;
  final List<FinovaTask> tasks;
  final List<Habit> habits;
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
  }) => _mutate(
    () => _db.saveTask(
      id: id,
      title: title,
      notes: notes,
      dueDate: dueDate,
      priority: priority,
    ),
  );
  Future<void> toggleTask(FinovaTask task) =>
      _mutate(() => _db.toggleTask(task));
  Future<void> deleteTask(int id) => _mutate(() => _db.deleteTask(id));
  Future<void> saveHabit({
    int? id,
    required String title,
    required String icon,
    required HabitFrequency frequency,
    required Set<int> selectedDays,
  }) => _mutate(
    () => _db.saveHabit(
      id: id,
      title: title,
      icon: icon,
      frequency: frequency,
      selectedDays: selectedDays,
    ),
  );
  Future<void> toggleHabit(Habit habit) =>
      _mutate(() => _db.toggleHabitLog(habit, DateTime.now()));
  Future<void> deleteHabit(int id) => _mutate(() => _db.deleteHabit(id));
  Future<void> resetAll() async {
    await _db.resetAll();
    await _prefs.clear();
    state = await AsyncValue.guard(_load);
  }
}
