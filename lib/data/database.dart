import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/activity.dart';
import '../models/bank_card.dart';
import '../models/bill.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'xcard.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE cards (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            bankName TEXT,
            cardType TEXT NOT NULL,
            cardNumber TEXT,
            cardholderName TEXT,
            expiryDate TEXT,
            creditLimit REAL DEFAULT 0,
            billingDate INTEGER DEFAULT 0,
            repaymentDate INTEGER DEFAULT 0,
            cardFace TEXT,
            note TEXT,
            createdAt INTEGER
          )
        ''');
        await database.execute('''
          CREATE TABLE bills (
            id TEXT PRIMARY KEY,
            cardId TEXT NOT NULL,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT,
            note TEXT,
            date INTEGER,
            createdAt INTEGER
          )
        ''');
        await database.execute(
            'CREATE INDEX idx_bills_card ON bills(cardId)');
        await database.execute('''
          CREATE TABLE activities (
            id TEXT PRIMARY KEY,
            cardId TEXT NOT NULL,
            title TEXT NOT NULL,
            goalType TEXT NOT NULL,
            targetValue REAL DEFAULT 0,
            startDate INTEGER,
            endDate INTEGER,
            note TEXT,
            status TEXT,
            createdAt INTEGER
          )
        ''');
        await database.execute('''
          CREATE TABLE activity_logs (
            id TEXT PRIMARY KEY,
            activityId TEXT NOT NULL,
            value REAL NOT NULL,
            note TEXT,
            date INTEGER
          )
        ''');
        await database.execute(
            'CREATE INDEX idx_logs_activity ON activity_logs(activityId)');
      },
    );
  }

  // ---------------- 卡片 ----------------

  Future<List<BankCard>> getCards({String? cardType}) async {
    final database = await db;
    final rows = cardType == null
        ? await database.query('cards', orderBy: 'createdAt DESC')
        : await database.query('cards',
            where: 'cardType = ?',
            whereArgs: [cardType],
            orderBy: 'createdAt DESC');
    return rows.map(BankCard.fromMap).toList();
  }

  Future<BankCard?> getCard(String id) async {
    final database = await db;
    final rows = await database.query('cards', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return BankCard.fromMap(rows.first);
  }

  Future<void> insertCard(BankCard card) async {
    final database = await db;
    await database.insert('cards', card.toMap());
  }

  Future<void> updateCard(BankCard card) async {
    final database = await db;
    await database.update('cards', card.toMap(), where: 'id = ?', whereArgs: [card.id]);
  }

  Future<void> deleteCard(String id) async {
    final database = await db;
    final activityRows = await database.query('activities', where: 'cardId = ?', whereArgs: [id]);
    final batch = database.batch();
    for (final row in activityRows) {
      batch.delete('activity_logs',
          where: 'activityId = ?', whereArgs: [row['id']]);
    }
    batch.delete('activities', where: 'cardId = ?', whereArgs: [id]);
    batch.delete('bills', where: 'cardId = ?', whereArgs: [id]);
    batch.delete('cards', where: 'id = ?', whereArgs: [id]);
    await batch.commit(noResult: true);
  }

  // ---------------- 账单 ----------------

  Future<List<Bill>> getBills({String? cardId, int? limit}) async {
    final database = await db;
    final rows = await database.query(
      'bills',
      where: cardId == null ? null : 'cardId = ?',
      whereArgs: cardId == null ? null : [cardId],
      orderBy: 'date DESC, createdAt DESC',
      limit: limit,
    );
    return rows.map(Bill.fromMap).toList();
  }

  Future<List<Bill>> getBillsForCards(List<String> cardIds) async {
    if (cardIds.isEmpty) return [];
    final database = await db;
    final placeholders = List.filled(cardIds.length, '?').join(',');
    final rows = await database.query(
      'bills',
      where: 'cardId IN ($placeholders)',
      whereArgs: cardIds,
      orderBy: 'date DESC, createdAt DESC',
    );
    return rows.map(Bill.fromMap).toList();
  }

  Future<void> insertBill(Bill bill) async {
    final database = await db;
    await database.insert('bills', bill.toMap());
  }

  Future<void> updateBill(Bill bill) async {
    final database = await db;
    await database.update('bills', bill.toMap(), where: 'id = ?', whereArgs: [bill.id]);
  }

  Future<void> deleteBill(String id) async {
    final database = await db;
    await database.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- 活动 ----------------

  Future<List<ActivityGoal>> getActivities({String? cardId}) async {
    final database = await db;
    final rows = await database.query(
      'activities',
      where: cardId == null ? null : 'cardId = ?',
      whereArgs: cardId == null ? null : [cardId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(ActivityGoal.fromMap).toList();
  }

  Future<void> insertActivity(ActivityGoal goal) async {
    final database = await db;
    await database.insert('activities', goal.toMap());
  }

  Future<void> updateActivity(ActivityGoal goal) async {
    final database = await db;
    await database.update('activities', goal.toMap(),
        where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> deleteActivity(String id) async {
    final database = await db;
    final batch = database.batch();
    batch.delete('activity_logs', where: 'activityId = ?', whereArgs: [id]);
    batch.delete('activities', where: 'id = ?', whereArgs: [id]);
    await batch.commit(noResult: true);
  }

  Future<List<ActivityLog>> getLogs(String activityId) async {
    final database = await db;
    final rows = await database.query('activity_logs',
        where: 'activityId = ?', whereArgs: [activityId], orderBy: 'date DESC');
    return rows.map(ActivityLog.fromMap).toList();
  }

  Future<double> sumLogs(String activityId) async {
    final database = await db;
    final rows = await database.rawQuery(
        'SELECT COALESCE(SUM(value), 0) AS total FROM activity_logs WHERE activityId = ?',
        [activityId]);
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<void> insertLog(ActivityLog log) async {
    final database = await db;
    await database.insert('activity_logs', log.toMap());
  }

  Future<void> deleteLog(String id) async {
    final database = await db;
    await database.delete('activity_logs', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- 统计 ----------------

  Future<double> sumBills(List<String> cardIds, String type,
      {int? from, int? to}) async {
    if (cardIds.isEmpty) return 0;
    final database = await db;
    final placeholders = List.filled(cardIds.length, '?').join(',');
    final conditions = ['cardId IN ($placeholders)', 'type = ?'];
    final args = <dynamic>[...cardIds, type];
    if (from != null) {
      conditions.add('date >= ?');
      args.add(from);
    }
    if (to != null) {
      conditions.add('date <= ?');
      args.add(to);
    }
    final rows = await database.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM bills WHERE ${conditions.join(' AND ')}',
      args,
    );
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, dynamic>>> categoryBreakdown(
    List<String> cardIds, {
    required int from,
    required int to,
  }) async {
    if (cardIds.isEmpty) return [];
    final database = await db;
    final placeholders = List.filled(cardIds.length, '?').join(',');
    return database.rawQuery(
      '''
      SELECT category, SUM(amount) AS total
      FROM bills
      WHERE cardId IN ($placeholders) AND type = ? AND date BETWEEN ? AND ?
      GROUP BY category ORDER BY total DESC
      ''',
      [...cardIds, BillType.expense, from, to],
    );
  }

  Future<List<Map<String, dynamic>>> monthlyBreakdown(
    List<String> cardIds, {
    required int from,
    required int to,
  }) async {
    if (cardIds.isEmpty) return [];
    final database = await db;
    final placeholders = List.filled(cardIds.length, '?').join(',');
    return database.rawQuery(
      '''
      SELECT strftime('%Y-%m', date/1000, 'unixepoch', 'localtime') AS month,
             SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS expense,
             SUM(CASE WHEN type = 'income'  THEN amount ELSE 0 END) AS income
      FROM bills
      WHERE cardId IN ($placeholders) AND date BETWEEN ? AND ?
      GROUP BY month ORDER BY month ASC
      ''',
      [...cardIds, from, to],
    );
  }
}
