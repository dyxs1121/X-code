class GoalType {
  static const String amount = 'amount';
  static const String count = 'count';
  static String label(String t) => t == amount ? '消费金额' : '刷卡次数';
}

class ActivityStatus {
  static const String active = 'active';
  static const String done = 'done';
}

class ActivityGoal {
  final String id;
  final String cardId;
  final String title;
  final String goalType; // amount | count
  final double targetValue;
  final int startDate;
  final int endDate;
  final String note;
  final String status;
  final int createdAt;

  ActivityGoal({
    required this.id,
    required this.cardId,
    required this.title,
    required this.goalType,
    required this.targetValue,
    required this.startDate,
    required this.endDate,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'cardId': cardId,
        'title': title,
        'goalType': goalType,
        'targetValue': targetValue,
        'startDate': startDate,
        'endDate': endDate,
        'note': note,
        'status': status,
        'createdAt': createdAt,
      };

  factory ActivityGoal.fromMap(Map<String, dynamic> map) => ActivityGoal(
        id: map['id'] as String,
        cardId: map['cardId'] as String,
        title: map['title'] as String? ?? '',
        goalType: map['goalType'] as String? ?? GoalType.amount,
        targetValue: (map['targetValue'] as num?)?.toDouble() ?? 0,
        startDate: (map['startDate'] as num?)?.toInt() ?? 0,
        endDate: (map['endDate'] as num?)?.toInt() ?? 0,
        note: map['note'] as String? ?? '',
        status: map['status'] as String? ?? ActivityStatus.active,
        createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
      );

  ActivityGoal copyWith({
    String? title,
    String? goalType,
    double? targetValue,
    int? startDate,
    int? endDate,
    String? note,
    String? status,
  }) =>
      ActivityGoal(
        id: id,
        cardId: cardId,
        title: title ?? this.title,
        goalType: goalType ?? this.goalType,
        targetValue: targetValue ?? this.targetValue,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        note: note ?? this.note,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}

class ActivityLog {
  final String id;
  final String activityId;
  final double value; // 金额或次数
  final String note;
  final int date;

  ActivityLog({
    required this.id,
    required this.activityId,
    required this.value,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'activityId': activityId,
        'value': value,
        'note': note,
        'date': date,
      };

  factory ActivityLog.fromMap(Map<String, dynamic> map) => ActivityLog(
        id: map['id'] as String,
        activityId: map['activityId'] as String,
        value: (map['value'] as num?)?.toDouble() ?? 0,
        note: map['note'] as String? ?? '',
        date: (map['date'] as num?)?.toInt() ?? 0,
      );
}
