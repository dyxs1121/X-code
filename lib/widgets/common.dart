import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String money(double value) {
  final f = NumberFormat('#,##0.00', 'zh_CN');
  return f.format(value);
}

String shortDate(int millis) {
  if (millis <= 0) return '未设置';
  return DateFormat('yyyy-MM-dd')
      .format(DateTime.fromMillisecondsSinceEpoch(millis));
}

String monthDay(int millis) {
  if (millis <= 0) return '';
  return DateFormat('MM月dd日')
      .format(DateTime.fromMillisecondsSinceEpoch(millis));
}

Widget sectionTitle(String text, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );

Widget emptyState({
  required IconData icon,
  required String title,
  String? subtitle,
  Widget? action,
}) =>
    Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action,
            ],
          ],
        ),
      ),
    );

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定')),
      ],
    ),
  );
  return result ?? false;
}
