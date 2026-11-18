import 'package:flutter/material.dart';

import '../data/database.dart';
import '../models/bank_card.dart';
import '../models/bill.dart';
import '../theme.dart';
import '../widgets/card_face_view.dart';
import '../widgets/common.dart';
import 'card_detail_screen.dart';
import 'card_editor_screen.dart';

class _CardsData {
  final List<BankCard> cards;
  final Map<String, double> used;
  final double monthExpense;
  final double monthIncome;

  _CardsData(this.cards, this.used, this.monthExpense, this.monthIncome);
}

class CardsScreen extends StatefulWidget {
  final String cardType;
  final int revision;
  final VoidCallback onChanged;
  final ValueChanged<int> onOpenTab;

  const CardsScreen({
    super.key,
    required this.cardType,
    required this.revision,
    required this.onChanged,
    required this.onOpenTab,
  });

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  late Future<_CardsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant CardsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision ||
        oldWidget.cardType != widget.cardType) {
      _future = _load();
    }
  }

  Future<_CardsData> _load() async {
    final db = DatabaseHelper.instance;
    final cards = await db.getCards(cardType: widget.cardType);
    final bills = await db.getBillsForCards(cards.map((c) => c.id).toList());
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final used = <String, double>{for (final c in cards) c.id: 0.0};
    double expense = 0, income = 0;
    for (final b in bills) {
      used[b.cardId] =
          (used[b.cardId] ?? 0) + (b.isExpense ? b.amount : -b.amount);
      if (b.date >= monthStart) {
        if (b.isExpense) {
          expense += b.amount;
        } else {
          income += b.amount;
        }
      }
    }
    return _CardsData(cards, used, expense, income);
  }

  Future<void> _addCard() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CardEditorScreen(cardType: widget.cardType),
      ),
    );
    if (result == true) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = widget.cardType == CardType.credit;
    return Scaffold(
      body: FutureBuilder<_CardsData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final cards = data.cards;
          final totalLimit =
              cards.fold<double>(0, (sum, c) => sum + c.creditLimit);
          final totalUsed = cards.fold<double>(
              0, (sum, c) => sum + (data.used[c.id] ?? 0).clamp(0, double.infinity));
          final available = (totalLimit - totalUsed).clamp(0, double.infinity);

          return RefreshIndicator(
            onRefresh: () async {
              _future = _load();
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _SummaryBanner(
                  isCredit: isCredit,
                  line1: isCredit ? '总授信额度' : '本月支出',
                  value1: isCredit ? totalLimit : data.monthExpense,
                  line2: isCredit ? '已用额度' : '本月收入',
                  value2: isCredit ? totalUsed : data.monthIncome,
                  line3: isCredit ? '可用额度' : '卡片数量',
                  value3: isCredit ? available : cards.length.toDouble(),
                  isCount: !isCredit,
                ),
                const SizedBox(height: 18),
                sectionTitle(
                  isCredit ? '信用卡列表' : '借记卡列表',
                  trailing: Text('${cards.length} 张',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ),
                if (cards.isEmpty)
                  emptyState(
                    icon: isCredit ? Icons.credit_card : Icons.account_balance,
                    title: isCredit ? '还没有信用卡' : '还没有借记卡',
                    subtitle: '点击下方按钮添加第一张${isCredit ? '信用卡' : '借记卡'}',
                  )
                else
                  ...cards.map((card) => _CardTile(
                        card: card,
                        used: data.used[card.id] ?? 0,
                        onTap: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CardDetailScreen(cardId: card.id),
                            ),
                          );
                          if (result == true) widget.onChanged();
                        },
                      )),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCard,
        icon: const Icon(Icons.add),
        label: Text('添加${isCredit ? '信用卡' : '借记卡'}'),
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final bool isCredit;
  final String line1, line2, line3;
  final double value1, value2, value3;
  final bool isCount;

  const _SummaryBanner({
    required this.isCredit,
    required this.line1,
    required this.value1,
    required this.line2,
    required this.value2,
    required this.line3,
    required this.value3,
    required this.isCount,
  });

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, double value, {bool count = false}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(height: 6),
              Text(
                count ? value.toInt().toString() : '¥${money(value)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF60A5FA)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isCredit ? '信用卡概览' : '借记卡概览',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              cell(line1, value1),
              cell(line2, value2),
              cell(line3, value3, count: isCount),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final BankCard card;
  final double used;
  final VoidCallback onTap;

  const _CardTile({
    required this.card,
    required this.used,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final clampedUsed = used < 0 ? 0.0 : used;
    final ratio = card.creditLimit > 0
        ? (clampedUsed / card.creditLimit).clamp(0.0, 1.0)
        : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                CardFaceView(card: card, compact: true),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              card.isCredit
                                  ? '已用 ¥${money(clampedUsed)} / 额度 ¥${money(card.creditLimit)}'
                                  : card.note.isEmpty
                                      ? '借记卡 · 点击查看详情'
                                      : card.note,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (card.isCredit && card.repaymentDate > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.expense.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${card.repaymentDate}日还款',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.expense,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
                if (card.isCredit && card.creditLimit > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 5,
                      backgroundColor: Colors.grey.shade200,
                      color: ratio > 0.8 ? AppTheme.expense : AppTheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
