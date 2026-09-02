import 'package:finova/core/models/models.dart';
import 'package:finova/core/services/calculations.dart';
import 'package:flutter_test/flutter_test.dart';

MoneyTransaction tx(int amount, TransactionType type, {DateTime? date}) =>
    MoneyTransaction(
      id: 1,
      type: type,
      amount: amount,
      categoryId: 1,
      categoryName: 'Test',
      note: '',
      date: date ?? DateTime(2026, 9, 1),
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    );
FinovaTask task(bool done) => FinovaTask(
  id: 1,
  title: 'Task',
  notes: '',
  dueDate: DateTime(2026, 9, 1),
  priority: TaskPriority.medium,
  completed: done,
  createdAt: DateTime(2026, 9, 1),
);
Habit habit(
  Set<DateTime> logs, {
  HabitFrequency frequency = HabitFrequency.daily,
  Set<int> days = const {},
}) => Habit(
  id: 1,
  title: 'Read',
  icon: '📚',
  frequency: frequency,
  selectedDays: days,
  createdAt: DateTime(2026, 8, 1),
  active: true,
  logDates: logs,
);

void main() {
  test('balance and income expense are deterministic', () {
    final result = calculateFinance([
      tx(1000, TransactionType.income),
      tx(250, TransactionType.expense),
    ], initialBalance: 500);
    expect(result.income, 1000);
    expect(result.expense, 250);
    expect(result.balance, 1250);
  });
  test('budget progress handles normal and zero budgets', () {
    expect(budgetProgress(spent: 250, budget: 1000), .25);
    expect(budgetProgress(spent: 10, budget: 0), 0);
    expect(budgetProgress(spent: 1250, budget: 1000), 1.25);
  });
  test('task completion handles empty and mixed tasks', () {
    expect(taskCompletion([]), 0);
    expect(taskCompletion([task(true), task(false)]), .5);
  });
  test('date filtering includes both range edges', () {
    expect(
      inDateRange(
        DateTime(2026, 9, 1, 23),
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 7),
      ),
      isTrue,
    );
    expect(
      inDateRange(
        DateTime(2026, 9, 8),
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 7),
      ),
      isFalse,
    );
  });
  test('daily current streak counts consecutive dates', () {
    final h = habit({
      DateTime(2026, 8, 30),
      DateTime(2026, 8, 31),
      DateTime(2026, 9, 1),
    });
    expect(currentHabitStreak(h, now: DateTime(2026, 9, 1)), 3);
    expect(longestHabitStreak(h), 3);
  });
  test('selected-day streak skips ineligible dates', () {
    final h = habit(
      {DateTime(2026, 8, 28), DateTime(2026, 8, 31), DateTime(2026, 9, 2)},
      frequency: HabitFrequency.selectedDays,
      days: {DateTime.monday, DateTime.wednesday, DateTime.friday},
    );
    expect(currentHabitStreak(h, now: DateTime(2026, 9, 2)), 3);
    expect(longestHabitStreak(h), 3);
  });
}
