enum TransactionType { income, expense }

enum TaskPriority { low, medium, high }

enum HabitFrequency { daily, selectedDays }

enum AppThemeMode { system, light, dark }

enum DebtType { payable, receivable }

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.isSystem,
  });
  final int id;
  final String name;
  final TransactionType type;
  final String icon;
  final bool isSystem;
}

class MoneyTransaction {
  const MoneyTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.note,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });
  final int id;
  final TransactionType type;
  final int amount;
  final int categoryId;
  final String categoryName;
  final String note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class Budget {
  const Budget({
    required this.id,
    required this.amount,
    required this.month,
    this.categoryId,
    this.categoryName,
  });
  final int id;
  final int amount;
  final DateTime month;
  final int? categoryId;
  final String? categoryName;
}

class FinovaTask {
  const FinovaTask({
    required this.id,
    required this.title,
    required this.notes,
    required this.dueDate,
    required this.priority,
    required this.completed,
    required this.createdAt,
    this.completedAt,
  });
  final int id;
  final String title;
  final String notes;
  final DateTime dueDate;
  final TaskPriority priority;
  final bool completed;
  final DateTime createdAt;
  final DateTime? completedAt;
}

class Habit {
  const Habit({
    required this.id,
    required this.title,
    required this.icon,
    required this.frequency,
    required this.selectedDays,
    required this.createdAt,
    required this.active,
    required this.logDates,
  });
  final int id;
  final String title;
  final String icon;
  final HabitFrequency frequency;
  final Set<int> selectedDays;
  final DateTime createdAt;
  final bool active;
  final Set<DateTime> logDates;
}

class DebtRecord {
  const DebtRecord({
    required this.id,
    required this.type,
    required this.person,
    required this.amount,
    required this.paidAmount,
    required this.dueDate,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final DebtType type;
  final String person;
  final int amount;
  final int paidAmount;
  final DateTime dueDate;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get remaining => (amount - paidAmount).clamp(0, amount);
  bool get isSettled => remaining == 0;
}

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
  });

  final int id;
  final String title;
  final int targetAmount;
  final int currentAmount;
  final DateTime? targetDate;

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);
  int get remaining => (targetAmount - currentAmount).clamp(0, targetAmount);
}

class GoalContribution {
  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    required this.note,
  });
  final int id;
  final int goalId;
  final int amount;
  final DateTime date;
  final String note;
}

class DebtPayment {
  const DebtPayment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    required this.note,
  });
  final int id;
  final int debtId;
  final int amount;
  final DateTime date;
  final String note;
}

class FinovaSettings {
  const FinovaSettings({
    this.currency = 'IDR',
    this.initialBalance = 0,
    this.themeMode = AppThemeMode.system,
    this.notificationsEnabled = false,
    this.adsEnabled = true,
    this.onboardingComplete = false,
  });
  final String currency;
  final int initialBalance;
  final AppThemeMode themeMode;
  final bool notificationsEnabled;
  final bool adsEnabled;
  final bool onboardingComplete;

  FinovaSettings copyWith({
    String? currency,
    int? initialBalance,
    AppThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? adsEnabled,
    bool? onboardingComplete,
  }) => FinovaSettings(
    currency: currency ?? this.currency,
    initialBalance: initialBalance ?? this.initialBalance,
    themeMode: themeMode ?? this.themeMode,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    adsEnabled: adsEnabled ?? this.adsEnabled,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
  );
}
