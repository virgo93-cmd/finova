import 'package:finova/core/models/models.dart';

class FinanceSummary {
  const FinanceSummary({
    required this.income,
    required this.expense,
    required this.balance,
  });
  final int income;
  final int expense;
  final int balance;
}

FinanceSummary calculateFinance(
  Iterable<MoneyTransaction> items, {
  int initialBalance = 0,
}) {
  var income = 0;
  var expense = 0;
  for (final item in items) {
    if (item.type == TransactionType.income) {
      income += item.amount;
    } else {
      expense += item.amount;
    }
  }
  return FinanceSummary(
    income: income,
    expense: expense,
    balance: initialBalance + income - expense,
  );
}

double budgetProgress({required int spent, required int budget}) =>
    budget <= 0 ? 0 : spent / budget;

double taskCompletion(Iterable<FinovaTask> tasks) {
  final list = tasks.toList();
  return list.isEmpty
      ? 0
      : list.where((task) => task.completed).length / list.length;
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool inDateRange(DateTime value, DateTime start, DateTime end) {
  final date = dateOnly(value);
  return !date.isBefore(dateOnly(start)) && !date.isAfter(dateOnly(end));
}

int currentHabitStreak(Habit habit, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final logs = habit.logDates.map(dateOnly).toSet();
  bool eligible(DateTime day) =>
      habit.frequency == HabitFrequency.daily ||
      habit.selectedDays.contains(day.weekday);
  var cursor = today;
  while (!eligible(cursor)) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  if (!logs.contains(cursor) && cursor == today) {
    cursor = cursor.subtract(const Duration(days: 1));
    while (!eligible(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
  }
  var streak = 0;
  while (!cursor.isBefore(dateOnly(habit.createdAt))) {
    if (eligible(cursor)) {
      if (!logs.contains(cursor)) break;
      streak++;
    }
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

int longestHabitStreak(Habit habit) {
  final logs = habit.logDates.map(dateOnly).toList()..sort();
  if (logs.isEmpty) return 0;
  bool eligible(DateTime day) =>
      habit.frequency == HabitFrequency.daily ||
      habit.selectedDays.contains(day.weekday);
  var best = 0;
  var run = 0;
  DateTime? previous;
  for (final log in logs) {
    if (!eligible(log)) continue;
    if (previous == null) {
      run = 1;
    } else {
      var expected = previous.add(const Duration(days: 1));
      while (!eligible(expected) && expected.isBefore(log)) {
        expected = expected.add(const Duration(days: 1));
      }
      run = expected == log ? run + 1 : 1;
    }
    if (run > best) best = run;
    previous = log;
  }
  return best;
}
