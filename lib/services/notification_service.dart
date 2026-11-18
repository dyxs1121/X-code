import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/bank_card.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const int _reminderBaseId = 1000;
  static const int _testNotificationId = 999;

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(settings);
    _ready = true;
  }

  /// iOS 首次会弹权限申请；之后可在系统设置中修改。
  Future<bool> requestPermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
    return granted;
  }

  NotificationDetails get _details => NotificationDetails(
        android: AndroidNotificationDetails(
          'repayment_channel',
          '还款提醒',
          channelDescription: 'X-Card 信用卡还款日提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  /// 为所有信用卡重新计算并安排下一次还款提醒（默认提前 3 天 09:00）。
  Future<int> scheduleRepaymentReminders(
    List<BankCard> cards, {
    int daysBefore = 3,
    int hour = 9,
  }) async {
    if (!_ready) await init();
    await _plugin.cancelAll();
    final now = DateTime.now();
    var count = 0;

    for (final card in cards) {
      if (card.cardType != CardType.credit) continue;
      if (card.repaymentDate < 1 || card.repaymentDate > 31) continue;

      final day = card.repaymentDate > 28 ? 28 : card.repaymentDate;
      var due = DateTime(now.year, now.month, day);
      if (!due.isAfter(now)) {
        due = DateTime(now.year, now.month + 1, day);
      }
      var remindAt = DateTime(
        due.year,
        due.month,
        due.day,
        hour,
      ).subtract(Duration(days: daysBefore));
      if (!remindAt.isAfter(now)) {
        remindAt = remindAt.add(const Duration(days: 30));
      }

      await _plugin.schedule(
        _reminderBaseId + card.createdAt % 100000,
        'X-Card 还款提醒',
        '「${card.name}」将于 ${due.month}月${due.day}日到期还款，请及时处理。',
        remindAt,
        notificationDetails: _details,
        payload: card.id,
      );
      count++;
    }
    return count;
  }

  Future<void> cancelAll() async {
    if (!_ready) await init();
    await _plugin.cancelAll();
  }

  Future<void> showTestNotification() async {
    if (!_ready) await init();
    await _plugin.show(
      _testNotificationId,
      'X-Card',
      '通知功能正常，还款提醒会提前发送到这里。',
      _details,
    );
  }
}
