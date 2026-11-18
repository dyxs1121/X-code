import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database.dart';
import '../models/bank_card.dart';
import '../services/notification_service.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _daysBefore = 3;
  int _cardCount = 0;
  int _billCount = 0;
  int _activityCount = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final database = await DatabaseHelper.instance.db;
    setState(() {
      _daysBefore = prefs.getInt('reminder_days_before') ?? 3;
      _cardCount = 0;
    });
    final cards = await database.query('cards');
    final bills = await database.query('bills');
    final activities = await database.query('activities');
    if (!mounted) return;
    setState(() {
      _cardCount = cards.length;
      _billCount = bills.length;
      _activityCount = activities.length;
    });
  }

  Future<void> _setDaysBefore(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_days_before', value);
    setState(() => _daysBefore = value);
    await _reschedule();
  }

  Future<void> _reschedule() async {
    setState(() => _busy = true);
    final cards =
        await DatabaseHelper.instance.getCards(cardType: CardType.credit);
    final count = await NotificationService.instance
        .scheduleRepaymentReminders(cards, daysBefore: _daysBefore);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已为 $count 张信用卡安排还款提醒（提前 $_daysBefore 天 09:00）')),
    );
  }

  Future<void> _clearData() async {
    final ok = await confirmDialog(
      context,
      title: '清空所有数据',
      message: '将删除全部卡片、账单和活动记录，且无法恢复。确定继续？',
    );
    if (!ok) return;
    final database = await DatabaseHelper.instance.db;
    await database.delete('activity_logs');
    await database.delete('activities');
    await database.delete('bills');
    await database.delete('cards');
    await NotificationService.instance.cancelAll();
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据已清空')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('设置与通知')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            sectionTitle('还款提醒'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_none,
                        color: AppTheme.primary),
                    title: const Text('开启通知权限'),
                    subtitle: const Text('首次需要授权；之后可在系统设置修改'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final granted =
                          await NotificationService.instance.requestPermission();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(granted
                                  ? '通知权限已开启'
                                  : '未获得通知权限，请到系统设置中开启')),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.alarm, color: AppTheme.primary),
                    title: const Text('提前提醒天数'),
                    trailing: DropdownButton<int>(
                      value: _daysBefore,
                      underline: const SizedBox.shrink(),
                      items: [1, 2, 3, 5, 7, 10]
                          .map((d) => DropdownMenuItem(
                              value: d, child: Text('$d 天')))
                          .toList(),
                      onChanged: (v) =>
                          _setDaysBefore(v ?? 3),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.refresh, color: AppTheme.primary),
                    title: const Text('重新安排所有提醒'),
                    subtitle: Text('当前 $_cardCount 张卡片，其中信用卡自动计算'),
                    trailing: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : null,
                    onTap: _busy ? null : _reschedule,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined,
                        color: AppTheme.primary),
                    title: const Text('发送测试通知'),
                    onTap: () async {
                      await NotificationService.instance.showTestNotification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('测试通知已发送')));
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            sectionTitle('数据概览'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _count('卡片', _cardCount),
                    _count('账单', _billCount),
                    _count('活动', _activityCount),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            sectionTitle('隐私与安全'),
            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.phone_iphone, color: AppTheme.primary),
                    title: Text('仅本机存储'),
                    subtitle: Text('所有数据保存在应用沙盒 SQLite 数据库中，不联网上传'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: AppTheme.expense),
                    title: Text('清空所有数据',
                        style: TextStyle(color: AppTheme.expense)),
                    onTap: _clearData,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            sectionTitle('关于'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'X-Card v1.0.0\n\n'
                  '信用卡与借记卡分账管理、账单记账、活动进度、消费统计。\n\n'
                  '提醒依赖 iOS 本地通知：App 需至少启动过一次；长时间未打开或被系统终止后，'
                  '已排期的本地通知通常仍会触发，但不保证在「低电量模式 / 重启后」始终生效。\n\n'
                  '卡面图库中的渐变卡面为原创设计，未使用任何银行的版权图案；'
                  '如需真实卡面请自行上传卡片照片。',
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                      color: Colors.grey.shade600),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      );

  Widget _count(String label, int value) => Column(
        children: [
          Text('$value',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primary)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      );
}
