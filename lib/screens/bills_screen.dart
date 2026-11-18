import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/database.dart';
import '../models/bank_card.dart';
import '../models/bill.dart';
import '../theme.dart';
import '../widgets/common.dart';

class _BillsData {
  final List<BankCard> cards;
  final List<Bill> bills;
  _BillsData(this.cards, this.bills);
}

class BillsScreen extends StatefulWidget {
  final String cardType;
  final int revision;
  final VoidCallback onChanged;

  const BillsScreen({
    super.key,
    required this.cardType,
    required this.revision,
    required this.onChanged,
  });

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  late Future<_BillsData> _future;
  String? _filterCardId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant BillsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision ||
        oldWidget.cardType != widget.cardType) {
      _filterCardId = null;
      _future = _load();
    }
  }

  Future<_BillsData> _load() async {
    final db = DatabaseHelper.instance;
    final cards = await db.getCards(cardType: widget.cardType);
    final bills = await db.getBillsForCards(cards.map((c) => c.id).toList());
    return _BillsData(cards, bills);
  }

  void _reload() => setState(() => _future = _load());

  void _openAddSheet(List<BankCard> cards) {
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加一张卡片')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BillFormSheet(
        cards: cards,
        initialCardId: _filterCardId ?? cards.first.id,
        onSaved: () {
          widget.onChanged();
          _reload();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = widget.cardType == CardType.credit;
    return Scaffold(
      body: FutureBuilder<_BillsData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final filtered = _filterCardId == null
              ? data.bills
              : data.bills.where((b) => b.cardId == _filterCardId).toList();
          final expense = filtered
              .where((b) => b.isExpense)
              .fold<double>(0, (s, b) => s + b.amount);
          final income = filtered
              .where((b) => !b.isExpense)
              .fold<double>(0, (s, b) => s + b.amount);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _chip('全部卡片', null),
                      ...data.cards.map((c) => _chip(c.name, c.id)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _summary('支出', expense, AppTheme.expense),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summary('收入', income, AppTheme.income),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? emptyState(
                        icon: Icons.receipt_long_outlined,
                        title: '暂无账单记录',
                        subtitle: '点击右下角按钮记一笔${isCredit ? '消费或还款' : '收支'}',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final bill = filtered[index];
                          final card = data.cards.firstWhere(
                              (c) => c.id == bill.cardId,
                              orElse: () => data.cards.first);
                          return Dismissible(
                            key: ValueKey(bill.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppTheme.expense,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) => confirmDialog(
                              context,
                              title: '删除账单',
                              message: '确定删除这条账单记录吗？',
                            ),
                            onDismissed: (_) async {
                              await DatabaseHelper.instance.deleteBill(bill.id);
                              widget.onChanged();
                              _reload();
                            },
                            child: Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: (bill.isExpense
                                          ? AppTheme.expense
                                          : AppTheme.income)
                                      .withValues(alpha: 0.12),
                                  child: Icon(
                                    bill.isExpense
                                        ? Icons.shopping_bag_outlined
                                        : Icons.account_balance_wallet_outlined,
                                    color: bill.isExpense
                                        ? AppTheme.expense
                                        : AppTheme.income,
                                    size: 19,
                                  ),
                                ),
                                title: Text(
                                  '${bill.category} · ${card.name}',
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${monthDay(bill.date)}${bill.note.isEmpty ? '' : ' · ${bill.note}'}',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey.shade500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  '${bill.isExpense ? '-' : '+'}¥${money(bill.amount)}',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: bill.isExpense
                                          ? AppTheme.expense
                                          : AppTheme.income),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _future.then((data) => _openAddSheet(data.cards));
        },
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
    );
  }

  Widget _chip(String label, String? id) {
    final selected = _filterCardId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
        selected: selected,
        onSelected: (_) => setState(() => _filterCardId = id),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _summary(String label, double value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: color)),
            const SizedBox(height: 4),
            Text('¥${money(value)}',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      );
}

class _BillFormSheet extends StatefulWidget {
  final List<BankCard> cards;
  final String initialCardId;
  final VoidCallback onSaved;

  const _BillFormSheet({
    required this.cards,
    required this.initialCardId,
    required this.onSaved,
  });

  @override
  State<_BillFormSheet> createState() => _BillFormSheetState();
}

class _BillFormSheetState extends State<_BillFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late String _cardId;
  String _type = BillType.expense;
  String _category = '餐饮';
  DateTime _date = DateTime.now();

  static const _expenseCategories = [
    '餐饮', '购物', '交通', '娱乐', '居住', '医疗', '教育', '旅行', '还款', '其他'
  ];
  static const _incomeCategories = [
    '工资', '奖金', '理财', '退款', '兼职', '其他'
  ];

  @override
  void initState() {
    super.initState();
    _cardId = widget.cards
            .any((c) => c.id == widget.initialCardId)
        ? widget.initialCardId
        : widget.cards.first.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  List<String> get categories =>
      _type == BillType.expense ? _expenseCategories : _incomeCategories;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amount.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('金额必须大于 0')));
      return;
    }
    await DatabaseHelper.instance.insertBill(Bill(
      id: const Uuid().v4(),
      cardId: _cardId,
      type: _type,
      amount: amount,
      category: _category,
      note: _note.text.trim(),
      date: _date.millisecondsSinceEpoch,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('记一笔',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _cardId,
                decoration: const InputDecoration(labelText: '选择卡片'),
                items: widget.cards
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.bankName} · ${c.name}',
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _cardId = v ?? _cardId),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(child: _typeButton('消费', BillType.expense)),
                    Expanded(child: _typeButton('收入', BillType.income)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v == null || v.isEmpty ? '请填写金额' : null,
                decoration: const InputDecoration(
                  labelText: '金额',
                  prefixText: '¥ ',
                ),
              ),
              const SizedBox(height: 14),
              Text('分类',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: categories
                    .map((c) => ChoiceChip(
                          label: Text(c),
                          selected: _category == c,
                          onSelected: (_) => setState(() {
                            _category = c;
                            if (!categories.contains(c)) _category = categories.first;
                          }),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _note,
                decoration: const InputDecoration(
                    labelText: '备注', hintText: '可选'),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, size: 20),
                title: Text(shortDate(_date.millisecondsSinceEpoch),
                    style: const TextStyle(fontSize: 14)),
                trailing: const Text('选择日期',
                    style: TextStyle(fontSize: 12, color: AppTheme.primary)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _save,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('保存账单'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeButton(String label, String value) {
    final selected = _type == value;
    final color = value == BillType.expense ? AppTheme.expense : AppTheme.income;
    return GestureDetector(
      onTap: () => setState(() {
        _type = value;
        _category = categories.first;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.grey.shade600)),
        ),
      ),
    );
  }
}
