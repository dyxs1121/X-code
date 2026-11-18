import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../models/bank_card.dart';
import '../models/bill.dart';
import '../theme.dart';
import '../widgets/common.dart';

class _StatsData {
  final List<BankCard> cards;
  final List<Bill> bills;
  final double expense;
  final double income;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> monthly;

  _StatsData(this.cards, this.bills, this.expense, this.income, this.categories,
      this.monthly);
}

class StatisticsScreen extends StatefulWidget {
  final String cardType;
  final int revision;

  const StatisticsScreen({
    super.key,
    required this.cardType,
    required this.revision,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<_StatsData> _future;
  int _days = 90;

  static const _chartColors = [
    Color(0xFF2563EB),
    Color(0xFFE11D48),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFFF97316),
    Color(0xFF64748B),
  ];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant StatisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision ||
        oldWidget.cardType != widget.cardType) {
      _future = _load();
    }
  }

  Future<_StatsData> _load() async {
    final db = DatabaseHelper.instance;
    final cards = await db.getCards(cardType: widget.cardType);
    final ids = cards.map((c) => c.id).toList();
    final from = DateTime.now()
        .subtract(Duration(days: _days))
        .millisecondsSinceEpoch;
    final to = DateTime.now().millisecondsSinceEpoch;
    final bills = await db.getBillsForCards(ids);
    final inRange = bills.where((b) => b.date >= from && b.date <= to).toList();
    final expense = await db.sumBills(ids, BillType.expense, from: from, to: to);
    final income = await db.sumBills(ids, BillType.income, from: from, to: to);
    final categories =
        await db.categoryBreakdown(ids, from: from, to: to);
    final monthly = await db.monthlyBreakdown(ids, from: from, to: to);
    return _StatsData(cards, bills, expense, income, categories, monthly);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) => Scaffold(
        body: FutureBuilder<_StatsData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            final net = data.income - data.expense;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                Row(
                  children: [
                    _periodButton('近 30 天', 30),
                    const SizedBox(width: 8),
                    _periodButton('近 90 天', 90),
                    const SizedBox(width: 8),
                    _periodButton('全部', 36500),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _statCard('总支出', data.expense, AppTheme.expense)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _statCard('总收入', data.income, AppTheme.income)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _statCard(
                            '结余', net, net >= 0 ? AppTheme.primary : AppTheme.expense)),
                  ],
                ),
                const SizedBox(height: 20),
                sectionTitle('支出分类占比'),
                if (data.categories.isEmpty)
                  _emptyChart('该时间段暂无支出数据')
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 190,
                            child: PieChart(
                              PieChartData(
                                sections: data.categories
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final value =
                                      (entry.value['total'] as num).toDouble();
                                  final percent = data.expense > 0
                                      ? value / data.expense
                                      : 0;
                                  return PieChartSectionData(
                                    value: value,
                                    color: _chartColors[
                                        entry.key % _chartColors.length],
                                    title:
                                        '${(percent * 100).toStringAsFixed(0)}%',
                                    titleStyle: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                    radius: 58,
                                  );
                                }).toList(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...data.categories.asMap().entries.map((entry) {
                            final name = entry.value['category'] as String? ?? '其他';
                            final value =
                                (entry.value['total'] as num).toDouble();
                            final percent = data.expense > 0
                                ? value / data.expense
                                : 0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _chartColors[
                                          entry.key % _chartColors.length],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(name,
                                      style: const TextStyle(fontSize: 12))),
                                  Text('¥${money(value)}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: 38,
                                    child: Text(
                                        '${(percent * 100).toStringAsFixed(0)}%',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500)),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                sectionTitle('月度收支趋势'),
                if (data.monthly.isEmpty)
                  _emptyChart('该时间段暂无账单数据')
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _maxY(data.monthly),
                                barGroups: data.monthly
                                    .asMap()
                                    .entries
                                    .map((entry) => BarChartGroupData(
                                          x: entry.key,
                                          barRods: [
                                            BarChartRodData(
                                              toY: (entry.value['expense'] as num)
                                                  .toDouble(),
                                              color: AppTheme.expense,
                                              width: 9,
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            BarChartRodData(
                                              toY: (entry.value['income'] as num)
                                                  .toDouble(),
                                              color: AppTheme.income,
                                              width: 9,
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          ],
                                        ))
                                    .toList(),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index < 0 ||
                                            index >= data.monthly.length) {
                                          return const SizedBox.shrink();
                                        }
                                        final month =
                                            data.monthly[index]['month'] as String? ??
                                                '';
                                        return Text(
                                          month.length >= 5
                                              ? month.substring(5)
                                              : month,
                                          style: const TextStyle(fontSize: 9),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: _maxY(data.monthly) / 4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _legend(AppTheme.expense, '支出'),
                              const SizedBox(width: 20),
                              _legend(AppTheme.income, '收入'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );

  double _maxY(List<Map<String, dynamic>> monthly) {
    var max = 0.0;
    for (final row in monthly) {
      max = max > (row['expense'] as num? ?? 0) ? max : (row['expense'] as num).toDouble();
      max = max > (row['income'] as num? ?? 0) ? max : (row['income'] as num).toDouble();
    }
    return max <= 0 ? 100 : max * 1.2;
  }

  Widget _legend(Color color, String label) => Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );

  Widget _emptyChart(String text) => Card(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ),
      );

  Widget _statCard(String label, double value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 6),
            FittedBox(
              child: Text('¥${money(value)}',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ),
          ],
        ),
      );

  Widget _periodButton(String label, int days) {
    final selected = _days == days;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_days == days) return;
          setState(() {
            _days = days;
            _future = _load();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.grey.shade600)),
          ),
        ),
      ),
    );
  }
}
