import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home/home_controller.dart';
import '../history/history_types.dart';
import '../history/history_view.dart';

class DriverDashboardView extends StatelessWidget {
  const DriverDashboardView({super.key});

  static const Color _bg = Color(0xFFF7F7F7);
  static const Color _primary = Color(0xFFC15A20);
  static const Color _primaryDark = Color(0xFF8A4C31);
  static const Color _text = Color(0xFF222222);
  static const Color _muted = Color(0xFF7A7A7A);

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _primaryDark),
          title: const Text(
            'الإحصائيات',
            style: TextStyle(color: _primaryDark, fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              onPressed: () => c.loadDashboard(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: RefreshIndicator(
          color: _primary,
          onRefresh: c.loadDashboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              _RangeSelector(controller: c),
              const SizedBox(height: 16),
              Obx(
                () => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    _StatCard(
                      title: 'تم التسليم',
                      value: '${c.delivered.value}',
                      icon: Icons.check_circle_rounded,
                      filled: true,
                      onTap: () => Get.to(
                        () => const HistoryView(
                          kind: HistoryKind.delivered,
                          initialRange: 'all',
                        ),
                      ),
                    ),
                    _StatCard(
                      title: 'تم الرفض',
                      value: '${c.rejected.value}',
                      icon: Icons.cancel_rounded,
                      onTap: () => Get.to(
                        () => const HistoryView(
                          kind: HistoryKind.rejected,
                          initialRange: 'all',
                        ),
                      ),
                    ),
                    _StatCard(
                      title: 'الربح',
                      value: c.profitAll.value.toStringAsFixed(2),
                      icon: Icons.payments_outlined,
                      onTap: () => Get.to(
                        () => const HistoryView(
                          kind: HistoryKind.profit,
                          initialRange: 'all',
                        ),
                      ),
                    ),
                    _StatCard(
                      title: 'المديونية',
                      value: c.debtToday.value.toStringAsFixed(2),
                      icon: Icons.account_balance_wallet_outlined,
                      onTap: () => Get.to(
                        () => const HistoryView(
                          kind: HistoryKind.debt,
                          initialRange: 'all',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Text(
                  'هذه اللوحة تعرض ملخص أداء السائق حسب الفترة المختارة. يمكن الضغط على أي بطاقة لفتح التفاصيل والسجلات.',
                  style: TextStyle(
                    color: _muted,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    const items = [
      ['all', 'كل الوقت'],
      ['month', 'هذا الشهر'],
      ['week', 'هذا الأسبوع'],
      ['today', 'اليوم'],
    ];

    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9E2DC)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((e) {
              final selected = controller.range.value == e[0];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  selected: selected,
                  label: Text(e[1]),
                  onSelected: (_) {
                    controller.range.value = e[0];
                    controller.loadDashboard();
                  },
                  selectedColor: const Color(0xFFC15A20).withOpacity(.14),
                  backgroundColor: Colors.transparent,
                  labelStyle: TextStyle(
                    color: selected
                        ? DriverDashboardView._text
                        : DriverDashboardView._muted,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: selected
                          ? DriverDashboardView._primaryDark
                          : const Color(0xFFE9E2DC),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? DriverDashboardView._primaryDark : Colors.white;
    final fg = filled ? Colors.white : DriverDashboardView._text;
    final mute = filled ? Colors.white70 : DriverDashboardView._muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: filled ? Colors.transparent : const Color(0xFFE9E2DC),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              color: filled ? Colors.white : DriverDashboardView._primary,
              size: 26,
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              title,
              style: TextStyle(color: mute, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
