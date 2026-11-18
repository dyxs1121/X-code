class BillType {
  static const String expense = 'expense';
  static const String income = 'income';

  static String label(String type) => type == expense ? '消费' : '收入';
}

class Bill {
  final String id;
  final String cardId;
  final String type; // expense | income
  final double amount;
  final String category;
  final String note;
  final int date;
  final int createdAt;

  Bill({
    required this.id,
    required this.cardId,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
    required this.createdAt,
  });

  bool get isExpense => type == BillType.expense;

  Map<String, dynamic> toMap() => {
        'id': id,
        'cardId': cardId,
        'type': type,
        'amount': amount,
        'category': category,
        'note': note,
        'date': date,
        'createdAt': createdAt,
      };

  factory Bill.fromMap(Map<String, dynamic> map) => Bill(
        id: map['id'] as String,
        cardId: map['cardId'] as String,
        type: map['type'] as String? ?? BillType.expense,
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        category: map['category'] as String? ?? '其他',
        note: map['note'] as String? ?? '',
        date: (map['date'] as num?)?.toInt() ?? 0,
        createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      );
}
