import 'package:flutter/material.dart';

import '../data/database.dart';
import '../models/activity.dart';
import '../models/bank_card.dart';
import '../models/bill.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/card_face_view.dart';
import '../widgets/common.dart';
import 'card_editor_screen.dart';

class _DetailData {
  final BankCard card;
  final List<Bill> bills;
  final List<ActivityGoal> activities;
  final Map<String, double> logSums;
  final double used;

  _DetailData(this.card, this.bills, this.activities, this.logSums, this.used);
}

class CardDetailScreen extends StatefulWidget {
  final String cardId;
  const CardDetailScreen({super.key, required this.cardId});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailData> _load() async {
    final db = DatabaseHelper.instance;
    final card = await db.getCard(widget.cardId);
    if (card == null) throw StateError('卡片不存在');
    final bills = await db.getBills(cardId: widget.cardId);
    final activities = await db.getActivities(cardId: widget.cardId);
    final sums = <String, double>{};
    for (final a in activities) {
      sums[a.id] = await db.sumLogs(a.id);
    }
    final used = bills.fold<double>(
        0, (s, b) => s + (b.isExpense ? b.amount : -b.amount));
    return _DetailData(card, bills, activities, sums, used);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('卡片详情')),
      body: FutureBuilder<_DetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return emptyState(icon: Icons.error, title: '加载失败');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final card = data.card;
          final used = data.used < 0 ? 0.0 : data.used;
          final available = (card.creditLimit - used).clamp(0, double.infinity);
          final ratio = card.creditLimit > 0
              ? (used / card.creditLimit).clamp(0.0, 1.0)
              : 0.0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              CardFaceView(card: card),
              const SizedBox(height: 18),
              sectionTitle('基本信息'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _infoRow('卡片名称', card.name),
                      _infoRow('发卡银行',
                          card.bankName.isEmpty ? '未填写' : card.bankName),
                      _infoRow('卡号', card.cardNumber.isEmpty ? '未填写' : card.cardNumber),
                      _infoRow('持卡人',
                          card.cardholderName.isEmpty ? '未填写' : card.cardholderName),
                      _infoRow('有效期', card.expiryDate.isEmpty ? '未填写' : card.expiryDate),
                      _infoRow(
                          '卡片类型', card.isCredit ? '信用卡' : '借记卡'),
                      if (card.isCredit) ...[
                        _infoRow('账单日',
                            card.billingDate > 0 ? '每月 ${card.billingDate} 日' : '未设置'),
                        _infoRow('还款日',
                            card.repaymentDate > 0 ? '每月 ${card.repaymentDate} 日' : '未设置'),
                      ],
                      if (card.note.isNotEmpty) _infoRow('备注', card.note),
                    ],
                  ),
                ),
              ),
              if (card.isCredit) ...[
                const SizedBox(height: 18),
                sectionTitle('额度情况'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _stat('总额度', card.creditLimit),
                            _stat('已用', used, color: AppTheme.expense),
                            _stat('可用', available, color: AppTheme.income),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            color: ratio > 0.8 ? AppTheme.expense : AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('使用率 ${(ratio * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              sectionTitle('最近账单',
                  trailing: Text('${data.bills.length} 笔',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500))),
              if (data.bills.isEmpty)
                _miniEmpty('暂无账单')
              else
                Card(
                  child: Column(
                    children: data.bills.take(5).map((bill) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (bill.isExpense
                                    ? AppTheme.expense
                                    : AppTheme.income)
                                .withValues(alpha: 0.12),
                            child: Icon(
                                bill.isExpense
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: bill.isExpense
                                    ? AppTheme.expense
                                    : AppTheme.income,
                                size: 18),
                          ),
                          title: Text(bill.category,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${monthDay(bill.date)} ${bill.note}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          trailing: Text(
                            '${bill.isExpense ? '-' : '+'}¥${money(bill.amount)}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: bill.isExpense
                                    ? AppTheme.expense
                                    : AppTheme.income),
                          ),
                        )).toList(),
                  ),
                ),
              const SizedBox(height: 18),
              sectionTitle('相关活动',
                  trailing: Text('${data.activities.length} 项',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500))),
              if (data.activities.isEmpty)
                _miniEmpty('暂无活动计划')
              else
                Card(
                  child: Column(
                    children: data.activities.map((a) {
                      final current = data.logSums[a.id] ?? 0;
                      final progress = a.targetValue > 0
                          ? (current / a.targetValue).clamp(0.0, 1.0)
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(a.title,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600))),
                                Text('${(progress * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CardEditorScreen(
                              cardType: card.cardType,
                              cardId: card.id,
                            ),
                          ),
                        );
                        if (result == true) _reload();
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('编辑卡片'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.expense),
                      onPressed: () async {
                        final ok = await confirmDialog(
                          context,
                          title: '删除卡片',
                          message:
                              '将同时删除「${card.name}」下的所有账单和活动记录，且无法恢复。确定删除？',
                        );
                        if (!ok) return;
                        await DatabaseHelper.instance.deleteCard(card.id);
                        final creditCards = await DatabaseHelper.instance
                            .getCards(cardType: CardType.credit);
                        await NotificationService.instance
                            .scheduleRepaymentReminders(creditCards);
                        if (mounted) Navigator.pop(context, true);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('删除卡片'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            SizedBox(
                width: 72,
                child: Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _stat(String label, double value, {Color? color}) => Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text('¥${money(value)}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color ?? const Color(0xFF0F172A))),
        ],
      );

  Widget _miniEmpty(String text) => Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
      );
}
