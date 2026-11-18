import 'package:flutter/material.dart';

import 'models/bank_card.dart';
import 'screens/activities_screen.dart';
import 'screens/bills_screen.dart';
import 'screens/cards_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/statistics_screen.dart';
import 'theme.dart';

class XCardApp extends StatelessWidget {
  const XCardApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'X-Card',
        theme: AppTheme.light(),
        home: const AppShell(),
      );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String _cardType = CardType.credit;
  int _tab = 0;
  int _revision = 0;

  void refresh() => setState(() => _revision++);

  void setType(String type) {
    if (_cardType == type) return;
    setState(() => _cardType = type);
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['我的卡片', '账单明细', '活动计划', '消费统计'];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF60A5FA)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('X',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17)),
              ),
            ),
            const SizedBox(width: 8),
            const Text('X-Card'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _TypeSwitch(type: _cardType, onChanged: setType),
          ),
        ],
      ),
      drawer: _AppDrawer(
        cardType: _cardType,
        currentTab: _tab,
        onTypeChanged: setType,
        onTabChanged: (index) => setState(() => _tab = index),
        onSettings: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          CardsScreen(
            cardType: _cardType,
            revision: _revision,
            onChanged: refresh,
            onOpenTab: (index) => setState(() => _tab = index),
          ),
          BillsScreen(
            cardType: _cardType,
            revision: _revision,
            onChanged: refresh,
          ),
          ActivitiesScreen(
            cardType: _cardType,
            revision: _revision,
            onChanged: refresh,
          ),
          StatisticsScreen(cardType: _cardType, revision: _revision),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: titles[0],
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: titles[1],
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: titles[2],
          ),
          NavigationDestination(
            icon: Icon(Icons.insert_chart_outlined),
            selectedIcon: Icon(Icons.insert_chart),
            label: titles[3],
          ),
        ],
      ),
    );
  }
}

class _TypeSwitch extends StatelessWidget {
  final String type;
  final ValueChanged<String> onChanged;
  const _TypeSwitch({required this.type, required this.onChanged});

  Widget _pill(String label, String value) {
    final selected = type == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black12, blurRadius: 4)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppTheme.primary : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pill('信用卡', CardType.credit),
            _pill('借记卡', CardType.debit),
          ],
        ),
      );
}

class _AppDrawer extends StatelessWidget {
  final String cardType;
  final int currentTab;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onSettings;

  const _AppDrawer({
    required this.cardType,
    required this.currentTab,
    required this.onTypeChanged,
    required this.onTabChanged,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF60A5FA)],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.account_balance_wallet,
                        color: Colors.white),
                  ),
                  SizedBox(height: 12),
                  Text('X-Card',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  Text('卡片管理 · 账单 · 活动',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _TypeSwitch(type: cardType, onChanged: onTypeChanged),
            ),
            _navItem(context, 0, Icons.credit_card, '卡片管理', onTabChanged),
            _navItem(context, 1, Icons.receipt_long, '账单明细', onTabChanged),
            _navItem(context, 2, Icons.flag, '活动计划', onTabChanged),
            _navItem(context, 3, Icons.insert_chart, '消费统计', onTabChanged),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('设置与通知'),
              onTap: onSettings,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('数据仅保存在本机 · v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon, String label,
      ValueChanged<int> onTap) {
    final selected = currentTab == index;
    return ListTile(
      selected: selected,
      selectedTileColor: AppTheme.primary.withValues(alpha: 0.08),
      leading: Icon(icon, color: selected ? AppTheme.primary : null),
      title: Text(label,
          style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              color: selected ? AppTheme.primary : null)),
      onTap: () {
        Navigator.pop(context);
        onTap(index);
      },
    );
  }
}
