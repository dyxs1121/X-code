import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/database.dart';
import 'models/bank_card.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await NotificationService.instance.init();

  // 启动时根据已保存的设置重新安排信用卡还款提醒。
  try {
    final prefs = await SharedPreferences.getInstance();
    final days = prefs.getInt('reminder_days_before') ?? 3;
    final creditCards =
        await DatabaseHelper.instance.getCards(cardType: CardType.credit);
    await NotificationService.instance
        .scheduleRepaymentReminders(creditCards, daysBefore: days);
  } catch (_) {
    // 首次启动数据库尚未建立时忽略，添加卡片后会重新安排。
  }

  runApp(const XCardApp());
}
