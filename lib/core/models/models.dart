enum TransactionType { income, expense }

enum TaskPriority { low, medium, high }

enum HabitFrequency { daily, selectedDays }

enum AppThemeMode { system, light, dark }

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
