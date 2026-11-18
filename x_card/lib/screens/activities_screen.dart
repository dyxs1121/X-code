import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/database.dart';
import '../models/activity.dart';
import '../models/bank_card.dart';
import '../theme.dart';
import '../widgets/common.dart';

class _ActivityData {
  final List<BankCard> cards;
  final List<ActivityGoal> activities;
  final Map<String, double> sums;

  _ActivityData(this.cards, this.activities, this.sums);
}

class ActivitiesScreen extends StatefulWidget {
  final String cardType;
  final int revision;
  final VoidCallback onChanged;

  const ActivitiesScreen({
    super.key,
    required this.cardType,
    required this.revision,
    required this.onChanged,
  });

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  late Future<_ActivityData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant ActivitiesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision ||
        oldWidget.cardType != widget.cardType) {
      _future = _load();
    }
  }

  Future<_ActivityData> _load() async {
    final db = DatabaseHelper.instance;
    final cards = await db.getCards(cardType: widget.cardType);
    final all = await db.getActivities();
    final ids = cards.map((c) => c.id).toSet();
    final activities = all.where((a) => ids.contains(a.cardId)).toList();
    final sums = <String, double>{};
    for (final a in activities) {
      sums[a.id] = await db.sumLogs(a.id);
    }
    return _ActivityData(cards, activities, sums);
  }

  void _reload() => setState(() => _future = _load());

  void _openForm(_ActivityData data, {ActivityGoal? goal}) {
    if (data.cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加一张卡片')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalFormSheet(
        cards: data.cards,
        goal: goal,
        onSaved: () {
          widget.onChanged();
          _reload();
        },
      ),
    );
  }

  void _openDetail(_ActivityData data, ActivityGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalDetailSheet(
        goal: goal,
        current: data.sums[goal.id] ?? 0,
        onChanged: () {
          widget.onChanged();
          _reload();
        },
        onEdit: () => _openForm(data, goal: goal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: FutureBuilder<_ActivityData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            if (data.activities.isEmpty) {
              return emptyState(
                icon: Icons.flag_outlined,
                title: '暂无活动计划',
                subtitle: '例如：本月刷满 10000 元，或刷卡 8 次，随时查看完成进度',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: data.activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final goal = data.activities[index];
                final current = data.sums[goal.id] ?? 0;
                final progress = goal.targetValue > 0
                    ? (current / goal.targetValue).clamp(0.0, 1.0)
                    : 0.0;
                final card = data.cards.firstWhere(
                    (c) => c.id == goal.cardId,
                    orElse: () => data.cards.first);
                final done = current >= goal.targetValue && goal.targetValue > 0;
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openDetail(data, goal),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(goal.title,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (done)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.income.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('已完成',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.income,
                                          fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${card.name} · ${GoalType.label(goal.goalType)} · ${shortDate(goal.startDate)} 至 ${shortDate(goal.endDate)}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                goal.goalType == GoalType.amount
                                    ? '¥${money(current)} / ¥${money(goal.targetValue)}'
                                    : '${current.toStringAsFixed(0)} 次 / ${goal.targetValue.toStringAsFixed(0)} 次',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text('${(progress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 7,
                              backgroundColor: Colors.grey.shade200,
                              color: done ? AppTheme.income : AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _future.then((data) => _openForm(data));
          },
          icon: const Icon(Icons.add),
          label: const Text('新建活动'),
        ),
      );
}

class _GoalFormSheet extends StatefulWidget {
  final List<BankCard> cards;
  final ActivityGoal? goal;
  final VoidCallback onSaved;

  const _GoalFormSheet({
    required this.cards,
    required this.onSaved,
    this.goal,
  });

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _target = TextEditingController();
  final _note = TextEditingController();
  late String _cardId;
  late String _goalType;
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _cardId = goal?.cardId ?? widget.cards.first.id;
    _goalType = goal?.goalType ?? GoalType.amount;
    _title.text = goal?.title ?? '';
    _target.text = goal != null
        ? (goal.targetValue == goal.targetValue.toInt()
            ? goal.targetValue.toInt().toString()
            : goal.targetValue.toStringAsFixed(2))
        : '';
    _note.text = goal?.note ?? '';
    _start = goal != null && goal.startDate > 0
        ? DateTime.fromMillisecondsSinceEpoch(goal.startDate)
        : DateTime(DateTime.now().year, DateTime.now().month, 1);
    _end = goal != null && goal.endDate > 0
        ? DateTime.fromMillisecondsSinceEpoch(goal.endDate)
        : DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  }

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final target = double.tryParse(_target.text) ?? 0;
    if (target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('目标值必须大于 0')));
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final goal = ActivityGoal(
      id: widget.goal?.id ?? const Uuid().v4(),
      cardId: _cardId,
      title: _title.text.trim(),
      goalType: _goalType,
      targetValue: target,
      startDate: _start.millisecondsSinceEpoch,
      endDate: _end.millisecondsSinceEpoch,
      note: _note.text.trim(),
      status: widget.goal?.status ?? ActivityStatus.active,
      createdAt: widget.goal?.createdAt ?? now,
    );
    final db = DatabaseHelper.instance;
    if (widget.goal == null) {
      await db.insertActivity(goal);
    } else {
      await db.updateActivity(goal);
    }
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Container(
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
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(widget.goal == null ? '新建活动' : '编辑活动',
                    style:
                        const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _cardId,
                  decoration: const InputDecoration(labelText: '关联卡片'),
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
                TextFormField(
                  controller: _title,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? '请填写活动名称'
                      : null,
                  decoration: const InputDecoration(
                      labelText: '活动内容',
                      hintText: '例如：本月刷卡消费满 10000 元'),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Expanded(child: _typeButton('消费金额', GoalType.amount)),
                      Expanded(child: _typeButton('刷卡次数', GoalType.count)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _target,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => v == null || v.isEmpty ? '请填写目标值' : null,
                  decoration: InputDecoration(
                    labelText: _goalType == GoalType.amount ? '目标金额' : '目标次数',
                    prefixText: _goalType == GoalType.amount ? '¥ ' : null,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _dateTile('开始', _start, (d) => setState(() => _start = d))),
                    const SizedBox(width: 12),
                    Expanded(child: _dateTile('结束', _end, (d) => setState(() => _end = d))),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _note,
                  decoration: const InputDecoration(
                      labelText: '备注', hintText: '可选'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _save,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('保存活动'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _dateTile(String label, DateTime date, ValueChanged<DateTime> onPick) =>
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 730)),
          );
          if (picked != null) onPick(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text(shortDate(date.millisecondsSinceEpoch),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _typeButton(String label, String value) {
    final selected = _goalType == value;
    return GestureDetector(
      onTap: () => setState(() => _goalType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.grey.shade600)),
        ),
      ),
    );
  }
}

class _GoalDetailSheet extends StatefulWidget {
  final ActivityGoal goal;
  final double current;
  final VoidCallback onChanged;
  final VoidCallback onEdit;

  const _GoalDetailSheet({
    required this.goal,
    required this.current,
    required this.onChanged,
    required this.onEdit,
  });

  @override
  State<_GoalDetailSheet> createState() => _GoalDetailSheetState();
}

class _GoalDetailSheetState extends State<_GoalDetailSheet> {
  late Future<List<ActivityLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = DatabaseHelper.instance.getLogs(widget.goal.id);
  }

  void _reload() => setState(
      () => _logsFuture = DatabaseHelper.instance.getLogs(widget.goal.id));

  void _openRecordSheet() {
    final controller = TextEditingController();
    final noteController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('记录一次进度',
                  style:
                      const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: widget.goal.goalType == GoalType.amount
                      ? '本次消费金额'
                      : '本次刷卡次数',
                  prefixText: widget.goal.goalType == GoalType.amount ? '¥ ' : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration:
                    const InputDecoration(labelText: '备注', hintText: '可选'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final value = double.tryParse(controller.text) ?? 0;
                  if (value <= 0) return;
                  await DatabaseHelper.instance.insertLog(ActivityLog(
                    id: const Uuid().v4(),
                    activityId: widget.goal.id,
                    value: value,
                    note: noteController.text.trim(),
                    date: DateTime.now().millisecondsSinceEpoch,
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                  _reload();
                  widget.onChanged();
                },
                child: const Text('保存记录'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final progress = goal.targetValue > 0
        ? (widget.current / goal.targetValue).clamp(0.0, 1.0)
        : 0.0;
    final remaining = (goal.targetValue - widget.current).clamp(0, double.infinity);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(goal.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              '${GoalType.label(goal.goalType)} · ${shortDate(goal.startDate)} 至 ${shortDate(goal.endDate)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            if (goal.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(goal.note,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stat('已完成', widget.current, goal.goalType),
                _stat('目标', goal.targetValue, goal.goalType),
                _stat('还差', remaining, goal.goalType),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: Colors.grey.shade200,
                color: progress >= 1 ? AppTheme.income : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text('完成度 ${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _openRecordSheet,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('记录进度'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onEdit();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: '编辑活动',
                ),
                IconButton.outlined(
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: '删除活动',
                      message: '将同时删除该活动的所有进度记录，确定吗？',
                    );
                    if (!ok) return;
                    await DatabaseHelper.instance.deleteActivity(goal.id);
                    if (mounted) Navigator.pop(context);
                    widget.onChanged();
                  },
                  icon: const Icon(Icons.delete_outline),
                  color: AppTheme.expense,
                  tooltip: '删除活动',
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('进度记录',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            FutureBuilder<List<ActivityLog>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('暂无记录',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400)),
                  );
                }
                return Column(
                  children: snapshot.data!.map((log) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          log.note.isEmpty
                              ? shortDate(log.date)
                              : '${shortDate(log.date)} · ${log.note}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              goal.goalType == GoalType.amount
                                  ? '+¥${money(log.value)}'
                                  : '+${log.value.toStringAsFixed(0)} 次',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.income),
                            ),
                            IconButton(
                              icon: Icon(Icons.close,
                                  size: 16, color: Colors.grey.shade400),
                              onPressed: () async {
                                await DatabaseHelper.instance.deleteLog(log.id);
                                _reload();
                                widget.onChanged();
                              },
                            ),
                          ],
                        ),
                      )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, double value, String type) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text(
                type == GoalType.amount
                    ? '¥${money(value)}'
                    : '${value.toStringAsFixed(0)}次',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
}
