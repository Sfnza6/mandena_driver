import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'statistics_controller.dart';

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key});

  static const Color bg = Color(0xFFF8F6F3);
  static const Color brown = Color(0xFFB65A25);
  static const Color orange = Color(0xFFFF5A00);
  static const Color green = Color(0xFF09BF58);
  static const Color red = Color(0xFFFF1E35);
  static const Color blueBg = Color(0xFFEAF3FF);
  static const Color blueBorder = Color(0xFF9BC8FF);
  static const Color blue = Color(0xFF0B62D6);
  static const Color text = Color(0xFF1F1F1F);
  static const Color mute = Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<StatisticsController>()
        ? Get.find<StatisticsController>()
        : Get.put(StatisticsController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: brown),
          title: const Text(
            'الإحصائيات',
            style: TextStyle(
              color: brown,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: c.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 26),
            children: [
              _RangeTabs(controller: c),
              const SizedBox(height: 22),
              Obx(() {
                if (c.loading.value &&
                    c.delivered.value == 0 &&
                    c.rejected.value == 0 &&
                    c.profit.value == 0 &&
                    c.debt.value == 0 &&
                    c.past.value == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return Column(
                  children: [
                    if (c.error.value.isNotEmpty) ...[
                      _ErrorBox(message: c.error.value),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: _SmallStatCard(
                            title: 'طلبات مكتملة',
                            value: '${c.delivered.value}',
                            icon: Icons.inventory_2_outlined,
                            color: green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SmallStatCard(
                            title: 'طلبات مرفوضة',
                            value: '${c.rejected.value}',
                            icon: Icons.cancel_outlined,
                            color: red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _WideStatCard(
                      title: 'إجمالي الربح',
                      value: _money(c.profit.value),
                      icon: Icons.trending_up_rounded,
                      color: brown,
                    ),
                    const SizedBox(height: 12),
                    _WideStatCard(
                      title: 'إجمالي المديونية',
                      value: _money(c.debt.value),
                      icon: Icons.trending_down_rounded,
                      color: orange,
                    ),
                    const SizedBox(height: 12),
                    _PastCard(value: _money(c.past.value)),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  static String _money(double value) {
    final fixed = value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 2,
    );
    return '$fixed ر.س';
  }
}

class _RangeTabs extends StatelessWidget {
  const _RangeTabs({required this.controller});
  final StatisticsController controller;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      ['all', 'الكل'],
      ['month', 'شهر'],
      ['week', 'أسبوع'],
      ['today', 'يوم'],
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Obx(() {
        final selected = controller.range.value;
        return Row(
          children: tabs.map((tab) {
            final key = tab[0];
            final label = tab[1];
            final active = selected == key;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () => controller.setRange(key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? StatisticsView.brown : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: active ? Colors.white : StatisticsView.mute,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  const _SmallStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.22),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(icon, color: Colors.white, size: 22),
            ],
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 23,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WideStatCard extends StatelessWidget {
  const _WideStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.20),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(icon, color: Colors.white, size: 22),
            ],
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PastCard extends StatelessWidget {
  const _PastCard({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: StatisticsView.blueBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StatisticsView.blueBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.attach_money_rounded,
                color: StatisticsView.blue,
                size: 20,
              ),
              SizedBox(width: 6),
              Text(
                'الماضي',
                style: TextStyle(
                  color: StatisticsView.blue,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF003D91),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(.25)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
      ),
    );
  }
}
