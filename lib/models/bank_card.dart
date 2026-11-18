class CardType {
  static const String credit = 'credit';
  static const String debit = 'debit';

  static String label(String type) =>
      type == credit ? '信用卡' : '借记卡';
}

class BankCard {
  final String id;
  final String name;
  final String bankName;
  final String cardType; // credit | debit
  final String cardNumber; // 仅保存脱敏号，例如 **** **** **** 1234
  final String cardholderName;
  final String expiryDate; // MM/YY
  final double creditLimit; // 借记卡为 0
  final int billingDate; // 账单日 1-31，0 表示未设置
  final int repaymentDate; // 还款日 1-31，0 表示未设置
  final String cardFace; // 内置卡面 id 或 custom:<路径>
  final String note;
  final int createdAt;

  BankCard({
    required this.id,
    required this.name,
    required this.bankName,
    required this.cardType,
    required this.cardNumber,
    required this.cardholderName,
    required this.expiryDate,
    required this.creditLimit,
    required this.billingDate,
    required this.repaymentDate,
    required this.cardFace,
    required this.note,
    required this.createdAt,
  });

  bool get isCredit => cardType == CardType.credit;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'bankName': bankName,
        'cardType': cardType,
        'cardNumber': cardNumber,
        'cardholderName': cardholderName,
        'expiryDate': expiryDate,
        'creditLimit': creditLimit,
        'billingDate': billingDate,
        'repaymentDate': repaymentDate,
        'cardFace': cardFace,
        'note': note,
        'createdAt': createdAt,
      };

  factory BankCard.fromMap(Map<String, dynamic> map) => BankCard(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        bankName: map['bankName'] as String? ?? '',
        cardType: map['cardType'] as String? ?? CardType.credit,
        cardNumber: map['cardNumber'] as String? ?? '',
        cardholderName: map['cardholderName'] as String? ?? '',
        expiryDate: map['expiryDate'] as String? ?? '',
        creditLimit: (map['creditLimit'] as num?)?.toDouble() ?? 0,
        billingDate: (map['billingDate'] as num?)?.toInt() ?? 0,
        repaymentDate: (map['repaymentDate'] as num?)?.toInt() ?? 0,
        cardFace: map['cardFace'] as String? ?? 'obsidian',
        note: map['note'] as String? ?? '',
        createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      );

  BankCard copyWith({
    String? name,
    String? bankName,
    String? cardType,
    String? cardNumber,
    String? cardholderName,
    String? expiryDate,
    double? creditLimit,
    int? billingDate,
    int? repaymentDate,
    String? cardFace,
    String? note,
  }) =>
      BankCard(
        id: id,
        name: name ?? this.name,
        bankName: bankName ?? this.bankName,
        cardType: cardType ?? this.cardType,
        cardNumber: cardNumber ?? this.cardNumber,
        cardholderName: cardholderName ?? this.cardholderName,
        expiryDate: expiryDate ?? this.expiryDate,
        creditLimit: creditLimit ?? this.creditLimit,
        billingDate: billingDate ?? this.billingDate,
        repaymentDate: repaymentDate ?? this.repaymentDate,
        cardFace: cardFace ?? this.cardFace,
        note: note ?? this.note,
        createdAt: createdAt,
      );
}
