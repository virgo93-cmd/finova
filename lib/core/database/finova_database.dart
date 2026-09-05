import 'package:finova/core/models/models.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class FinovaDatabase {
  static const backupTables = <String>[
    'categories',
    'transactions',
    'budgets',
    'tasks',
    'habits',
    'habit_logs',
    'goals',
    'debts',
    'goal_contributions',
    'debt_payments',
  ];
  Database? _database;
  Database get db => _database!;

  Future<void> open() async {
    final path = p.join(await getDatabasesPath(), 'finova.db');
    _database = await openDatabase(
      path,
      version: 4,
      onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      onCreate: _create,
      onUpgrade: _upgrade,
    );
  }

  Future<void> _create(Database database, int version) async {
    await database.execute(
      'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT NOT NULL, icon TEXT NOT NULL, is_system INTEGER NOT NULL DEFAULT 0)',
    );
    await database.execute(
      'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL, amount INTEGER NOT NULL CHECK(amount > 0), category_id INTEGER NOT NULL, note TEXT NOT NULL DEFAULT \'\', date TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, FOREIGN KEY(category_id) REFERENCES categories(id))',
    );
    await database.execute(
      'CREATE INDEX idx_transactions_date ON transactions(date)',
    );
    await database.execute(
      'CREATE TABLE budgets(id INTEGER PRIMARY KEY AUTOINCREMENT, amount INTEGER NOT NULL CHECK(amount > 0), month TEXT NOT NULL, category_id INTEGER, UNIQUE(month, category_id), FOREIGN KEY(category_id) REFERENCES categories(id))',
    );
    await database.execute(
      'CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, notes TEXT NOT NULL DEFAULT \'\', due_date TEXT NOT NULL, priority TEXT NOT NULL, completed INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, completed_at TEXT)',
    );
    await database.execute(
      'CREATE TABLE habits(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, icon TEXT NOT NULL, frequency TEXT NOT NULL, selected_days TEXT NOT NULL DEFAULT \'\', created_at TEXT NOT NULL, active INTEGER NOT NULL DEFAULT 1)',
    );
    await database.execute(
      'CREATE TABLE habit_logs(id INTEGER PRIMARY KEY AUTOINCREMENT, habit_id INTEGER NOT NULL, log_date TEXT NOT NULL, UNIQUE(habit_id, log_date), FOREIGN KEY(habit_id) REFERENCES habits(id) ON DELETE CASCADE)',
    );
    await database.execute(
      'CREATE TABLE goals(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, target_amount INTEGER NOT NULL DEFAULT 0, current_amount INTEGER NOT NULL DEFAULT 0, target_date TEXT)',
    );
    await database.execute(
      'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
    await _createDebtsTable(database);
    await _createHistoryTables(database);
    await _seedCategories(database);
  }

  Future<void> _upgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) await _createDebtsTable(database);
    if (oldVersion < 3) await _translateSystemCategories(database);
    if (oldVersion < 4) await _createHistoryTables(database);
  }

  Future<void> _translateSystemCategories(Database database) async {
    const names = {
      'Food': 'Makanan',
      'Transport': 'Transportasi',
      'Shopping': 'Belanja',
      'Bills': 'Tagihan',
      'Entertainment': 'Hiburan',
      'Health': 'Kesehatan',
      'Education': 'Pendidikan',
      'Family': 'Keluarga',
      'Travel': 'Perjalanan',
      'Other': 'Lainnya',
      'Salary': 'Gaji',
      'Business': 'Bisnis',
      'Freelance': 'Freelance',
      'Investment': 'Investasi',
      'Gift': 'Hadiah',
    };
    for (final entry in names.entries) {
      await database.update(
        'categories',
        {'name': entry.value},
        where: 'name = ? AND is_system = 1',
        whereArgs: [entry.key],
      );
    }
  }

  Future<void> _createDebtsTable(Database database) => database.execute(
    'CREATE TABLE debts(id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL, person TEXT NOT NULL, amount INTEGER NOT NULL CHECK(amount > 0), paid_amount INTEGER NOT NULL DEFAULT 0 CHECK(paid_amount >= 0), due_date TEXT NOT NULL, note TEXT NOT NULL DEFAULT \'\', created_at TEXT NOT NULL, updated_at TEXT NOT NULL)',
  );

  Future<void> _createHistoryTables(Database database) async {
    await database.execute(
      'CREATE TABLE IF NOT EXISTS goal_contributions(id INTEGER PRIMARY KEY AUTOINCREMENT, goal_id INTEGER NOT NULL, amount INTEGER NOT NULL, date TEXT NOT NULL, note TEXT NOT NULL DEFAULT \'\', FOREIGN KEY(goal_id) REFERENCES goals(id) ON DELETE CASCADE)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_goal_contributions_goal_date ON goal_contributions(goal_id, date DESC)',
    );
    await database.execute(
      'CREATE TABLE IF NOT EXISTS debt_payments(id INTEGER PRIMARY KEY AUTOINCREMENT, debt_id INTEGER NOT NULL, amount INTEGER NOT NULL, date TEXT NOT NULL, note TEXT NOT NULL DEFAULT \'\', FOREIGN KEY(debt_id) REFERENCES debts(id) ON DELETE CASCADE)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS idx_debt_payments_debt_date ON debt_payments(debt_id, date DESC)',
    );
  }

  Future<void> _seedCategories(Database database) async {
    const expenses = {
      'Makanan': 'restaurant',
      'Transportasi': 'directions_car',
      'Belanja': 'shopping_bag',
      'Tagihan': 'receipt_long',
      'Hiburan': 'movie',
      'Kesehatan': 'health_and_safety',
      'Pendidikan': 'school',
      'Keluarga': 'family_restroom',
      'Perjalanan': 'flight',
      'Lainnya': 'more_horiz',
    };
    const incomes = {
      'Gaji': 'payments',
      'Bisnis': 'business_center',
      'Freelance': 'laptop',
      'Investasi': 'trending_up',
      'Hadiah': 'redeem',
      'Lainnya': 'more_horiz',
    };
    for (final entry in expenses.entries) {
      await database.insert('categories', {
        'name': entry.key,
        'type': 'expense',
        'icon': entry.value,
        'is_system': 1,
      });
    }
    for (final entry in incomes.entries) {
      await database.insert('categories', {
        'name': entry.key,
        'type': 'income',
        'icon': entry.value,
        'is_system': 1,
      });
    }
  }

  Future<List<Category>> categories([TransactionType? type]) async {
    final rows = await db.query(
      'categories',
      where: type == null ? null : 'type = ?',
      whereArgs: type == null ? null : [type.name],
      orderBy: 'is_system DESC, name',
    );
    return rows
        .map(
          (r) => Category(
            id: r['id'] as int,
            name: r['name'] as String,
            type: TransactionType.values.byName(r['type'] as String),
            icon: r['icon'] as String,
            isSystem: (r['is_system'] as int) == 1,
          ),
        )
        .toList();
  }

  Future<int> addCategory(String name, TransactionType type) => db.insert(
    'categories',
    {'name': name.trim(), 'type': type.name, 'icon': 'label', 'is_system': 0},
  );
  Future<void> renameCategory(int id, String name) async {
    await db.update(
      'categories',
      {'name': name.trim()},
      where: 'id = ? AND is_system = 0',
      whereArgs: [id],
    );
  }

  Future<void> deleteCategory(int id) async {
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM transactions WHERE category_id = ?',
            [id],
          ),
        ) ??
        0;
    if (count > 0) throw StateError('Category is used by transactions');
    await db.delete(
      'categories',
      where: 'id = ? AND is_system = 0',
      whereArgs: [id],
    );
  }

  Future<List<MoneyTransaction>> transactions() async {
    final rows = await db.rawQuery(
      'SELECT t.*, c.name category_name FROM transactions t JOIN categories c ON c.id=t.category_id ORDER BY date DESC, created_at DESC',
    );
    return rows
        .map(
          (r) => MoneyTransaction(
            id: r['id'] as int,
            type: TransactionType.values.byName(r['type'] as String),
            amount: r['amount'] as int,
            categoryId: r['category_id'] as int,
            categoryName: r['category_name'] as String,
            note: r['note'] as String,
            date: DateTime.parse(r['date'] as String),
            createdAt: DateTime.parse(r['created_at'] as String),
            updatedAt: DateTime.parse(r['updated_at'] as String),
          ),
        )
        .toList();
  }

  Future<void> saveTransaction({
    int? id,
    required TransactionType type,
    required int amount,
    required int categoryId,
    required String note,
    required DateTime date,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Must be greater than zero');
    }
    final now = DateTime.now().toIso8601String();
    final values = {
      'type': type.name,
      'amount': amount,
      'category_id': categoryId,
      'note': note.trim(),
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'updated_at': now,
    };
    if (id == null) {
      await db.insert('transactions', {...values, 'created_at': now});
    } else {
      await db.update('transactions', values, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> deleteTransaction(int id) async {
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Budget>> budgets() async {
    final rows = await db.rawQuery(
      'SELECT b.*, c.name category_name FROM budgets b LEFT JOIN categories c ON c.id=b.category_id ORDER BY category_id',
    );
    return rows
        .map(
          (r) => Budget(
            id: r['id'] as int,
            amount: r['amount'] as int,
            month: DateTime.parse(r['month'] as String),
            categoryId: r['category_id'] as int?,
            categoryName: r['category_name'] as String?,
          ),
        )
        .toList();
  }

  Future<void> saveBudget({
    required int amount,
    required DateTime month,
    int? categoryId,
  }) async {
    final key = DateTime(month.year, month.month).toIso8601String();
    final existing = await db.query(
      'budgets',
      where: categoryId == null
          ? 'month = ? AND category_id IS NULL'
          : 'month = ? AND category_id = ?',
      whereArgs: categoryId == null ? [key] : [key, categoryId],
    );
    if (existing.isEmpty) {
      await db.insert('budgets', {
        'amount': amount,
        'month': key,
        'category_id': categoryId,
      });
    } else {
      await db.update(
        'budgets',
        {'amount': amount},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  Future<List<FinovaTask>> tasks() async {
    final rows = await db.query(
      'tasks',
      orderBy: 'completed, due_date, priority DESC',
    );
    return rows
        .map(
          (r) => FinovaTask(
            id: r['id'] as int,
            title: r['title'] as String,
            notes: r['notes'] as String,
            dueDate: DateTime.parse(r['due_date'] as String),
            priority: TaskPriority.values.byName(r['priority'] as String),
            completed: (r['completed'] as int) == 1,
            createdAt: DateTime.parse(r['created_at'] as String),
            completedAt: r['completed_at'] == null
                ? null
                : DateTime.parse(r['completed_at'] as String),
          ),
        )
        .toList();
  }

  Future<int> saveTask({
    int? id,
    required String title,
    required String notes,
    required DateTime dueDate,
    required TaskPriority priority,
  }) async {
    final values = {
      'title': title.trim(),
      'notes': notes.trim(),
      'due_date': dueDate.toIso8601String(),
      'priority': priority.name,
    };
    if (id == null) {
      return db.insert('tasks', {
        ...values,
        'completed': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update('tasks', values, where: 'id = ?', whereArgs: [id]);
      return id;
    }
  }

  Future<void> toggleTask(FinovaTask task) async {
    final done = !task.completed;
    await db.update(
      'tasks',
      {
        'completed': done ? 1 : 0,
        'completed_at': done ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(int id) async {
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Habit>> habits() async {
    final rows = await db.query('habits', orderBy: 'active DESC, created_at');
    final logs = await db.query('habit_logs');
    return rows.map((r) {
      final id = r['id'] as int;
      return Habit(
        id: id,
        title: r['title'] as String,
        icon: r['icon'] as String,
        frequency: HabitFrequency.values.byName(r['frequency'] as String),
        selectedDays: (r['selected_days'] as String)
            .split(',')
            .where((x) => x.isNotEmpty)
            .map(int.parse)
            .toSet(),
        createdAt: DateTime.parse(r['created_at'] as String),
        active: (r['active'] as int) == 1,
        logDates: logs
            .where((x) => x['habit_id'] == id)
            .map((x) => DateTime.parse(x['log_date'] as String))
            .toSet(),
      );
    }).toList();
  }

  Future<int> saveHabit({
    int? id,
    required String title,
    required String icon,
    required HabitFrequency frequency,
    required Set<int> selectedDays,
  }) async {
    final values = {
      'title': title.trim(),
      'icon': icon,
      'frequency': frequency.name,
      'selected_days': selectedDays.join(','),
    };
    if (id == null) {
      return db.insert('habits', {
        ...values,
        'created_at': DateTime.now().toIso8601String(),
        'active': 1,
      });
    } else {
      await db.update('habits', values, where: 'id = ?', whereArgs: [id]);
      return id;
    }
  }

  Future<void> toggleHabitLog(Habit habit, DateTime date) async {
    final day = DateTime(date.year, date.month, date.day).toIso8601String();
    final found = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND log_date = ?',
      whereArgs: [habit.id, day],
    );
    if (found.isEmpty) {
      await db.insert('habit_logs', {'habit_id': habit.id, 'log_date': day});
    } else {
      await db.delete(
        'habit_logs',
        where: 'habit_id = ? AND log_date = ?',
        whereArgs: [habit.id, day],
      );
    }
  }

  Future<void> deleteHabit(int id) async {
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<DebtRecord>> debts() async {
    final rows = await db.query('debts', orderBy: 'due_date, created_at DESC');
    return rows
        .map(
          (r) => DebtRecord(
            id: r['id'] as int,
            type: DebtType.values.byName(r['type'] as String),
            person: r['person'] as String,
            amount: r['amount'] as int,
            paidAmount: r['paid_amount'] as int,
            dueDate: DateTime.parse(r['due_date'] as String),
            note: r['note'] as String,
            createdAt: DateTime.parse(r['created_at'] as String),
            updatedAt: DateTime.parse(r['updated_at'] as String),
          ),
        )
        .toList();
  }

  Future<int> saveDebt({
    int? id,
    required DebtType type,
    required String person,
    required int amount,
    required int paidAmount,
    required DateTime dueDate,
    required String note,
  }) async {
    if (amount <= 0 || person.trim().isEmpty) {
      throw ArgumentError('Nama dan nominal wajib diisi.');
    }
    final now = DateTime.now().toIso8601String();
    final values = {
      'type': type.name,
      'person': person.trim(),
      'amount': amount,
      'paid_amount': paidAmount.clamp(0, amount),
      'due_date': DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
      ).toIso8601String(),
      'note': note.trim(),
      'updated_at': now,
    };
    if (id == null) {
      return db.insert('debts', {...values, 'created_at': now});
    } else {
      await db.update('debts', values, where: 'id = ?', whereArgs: [id]);
      return id;
    }
  }

  Future<void> updateDebtPayment(int id, int paidAmount, int total) async {
    await db.transaction((txn) async {
      final rows = await txn.query('debts', where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) return;
      final before = rows.first['paid_amount'] as int;
      final after = paidAmount.clamp(0, total);
      final difference = after - before;
      await txn.update(
        'debts',
        {'paid_amount': after, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      if (difference != 0) {
        await txn.insert('debt_payments', {
          'debt_id': id,
          'amount': difference,
          'date': DateTime.now().toIso8601String(),
          'note': difference > 0 ? 'Pembayaran' : 'Koreksi pembayaran',
        });
      }
    });
  }

  Future<List<DebtPayment>> debtPayments() async =>
      (await db.query('debt_payments', orderBy: 'date DESC')).map((row) {
        return DebtPayment(
          id: row['id'] as int,
          debtId: row['debt_id'] as int,
          amount: row['amount'] as int,
          date: DateTime.parse(row['date'] as String),
          note: row['note'] as String,
        );
      }).toList();

  Future<void> deleteDebt(int id) async {
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SavingsGoal>> goals() async {
    final rows = await db.query('goals', orderBy: 'target_date, id DESC');
    return rows
        .map(
          (row) => SavingsGoal(
            id: row['id'] as int,
            title: row['title'] as String,
            targetAmount: row['target_amount'] as int,
            currentAmount: row['current_amount'] as int,
            targetDate: row['target_date'] == null
                ? null
                : DateTime.parse(row['target_date'] as String),
          ),
        )
        .toList();
  }

  Future<void> saveGoal({
    int? id,
    required String title,
    required int targetAmount,
    required int currentAmount,
    DateTime? targetDate,
  }) async {
    if (title.trim().isEmpty || targetAmount <= 0) {
      throw ArgumentError('Nama dan target wajib diisi.');
    }
    final values = {
      'title': title.trim(),
      'target_amount': targetAmount,
      'current_amount': currentAmount.clamp(0, targetAmount),
      'target_date': targetDate?.toIso8601String(),
    };
    await db.transaction((txn) async {
      int goalId;
      var previous = 0;
      if (id == null) {
        goalId = await txn.insert('goals', values);
      } else {
        goalId = id;
        final rows = await txn.query('goals', where: 'id = ?', whereArgs: [id]);
        if (rows.isNotEmpty) previous = rows.first['current_amount'] as int;
        await txn.update('goals', values, where: 'id = ?', whereArgs: [id]);
      }
      final difference = currentAmount.clamp(0, targetAmount) - previous;
      if (difference != 0) {
        await txn.insert('goal_contributions', {
          'goal_id': goalId,
          'amount': difference,
          'date': DateTime.now().toIso8601String(),
          'note': difference > 0 ? 'Setoran' : 'Penyesuaian',
        });
      }
    });
  }

  Future<List<GoalContribution>> goalContributions() async =>
      (await db.query('goal_contributions', orderBy: 'date DESC')).map((row) {
        return GoalContribution(
          id: row['id'] as int,
          goalId: row['goal_id'] as int,
          amount: row['amount'] as int,
          date: DateTime.parse(row['date'] as String),
          note: row['note'] as String,
        );
      }).toList();

  Future<void> addGoalContribution(
    SavingsGoal goal,
    int amount,
    String note,
  ) async {
    if (amount <= 0) {
      throw ArgumentError('Nominal setoran harus lebih dari nol.');
    }
    await db.transaction((txn) async {
      final accepted = amount.clamp(0, goal.remaining);
      if (accepted == 0) {
        return;
      }
      await txn.update(
        'goals',
        {'current_amount': goal.currentAmount + accepted},
        where: 'id = ?',
        whereArgs: [goal.id],
      );
      await txn.insert('goal_contributions', {
        'goal_id': goal.id,
        'amount': accepted,
        'date': DateTime.now().toIso8601String(),
        'note': note.trim().isEmpty ? 'Setoran' : note.trim(),
      });
    });
  }

  Future<void> deleteGoal(int id) async {
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, List<Map<String, Object?>>>> exportData() async {
    final result = <String, List<Map<String, Object?>>>{};
    for (final table in backupTables) {
      result[table] = await db.query(table);
    }
    return result;
  }

  Future<void> importData(Map<String, dynamic> source) async {
    await db.transaction((txn) async {
      await txn.execute('PRAGMA defer_foreign_keys = ON');
      for (final table in backupTables.reversed) {
        await txn.delete(table);
      }
      for (final table in backupTables) {
        final rows = source[table];
        if (rows == null &&
            (table == 'goal_contributions' || table == 'debt_payments')) {
          continue;
        }
        if (rows is! List) {
          throw const FormatException('Isi backup tidak lengkap.');
        }
        for (final row in rows) {
          if (row is! Map) {
            throw const FormatException('Baris backup tidak valid.');
          }
          await txn.insert(
            table,
            Map<String, Object?>.from(row),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Future<void> resetAll() async {
    await db.transaction((txn) async {
      for (final table in backupTables.reversed.where(
        (x) => x != 'categories',
      )) {
        await txn.delete(table);
      }
      await txn.delete('categories', where: 'is_system = 0');
    });
  }
}
