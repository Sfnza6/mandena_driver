import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'history_controller.dart';
import 'history_types.dart';

const Color _bg = Color(0xFFF8F6F3);
const Color _card = Colors.white;
const Color _brown = Color(0xFF9A5236);
const Color _text = Color(0xFF172033);
const Color _muted = Color(0xFF7C7C84);
const Color _border = Color(0xFFE7DED8);
const Color _greenText = Color(0xFF159447);
const Color _greenBg = Color(0xFFDDFBE8);
const Color _redText = Color(0xFFE23B3B);
const Color _redBg = Color(0xFFFFE0E0);

class HistoryView extends StatefulWidget {
  const HistoryView({
    super.key,
    this.kind = HistoryKind.delivered,
    this.initialRange = 'all',
  });

  final HistoryKind kind;
  final String initialRange;

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late final HistoryController controller;

  @override
  void initState() {
    super.initState();
    final tag = widget.kind.name;
    controller = Get.isRegistered<HistoryController>(tag: tag)
        ? Get.find<HistoryController>(tag: tag)
        : Get.put(HistoryController(kind: widget.kind), tag: tag);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final requested = _normalizeRange(widget.initialRange);
      if (controller.range.value != requested) {
        controller.setRange(requested);
      }
    });
  }

  String _normalizeRange(String value) {
    switch (value) {
      case 'today':
      case 'week':
      case 'month':
      case 'all':
        return value;
      default:
        return 'all';
    }
  }

  @override
  Widget build(BuildContext context) {
    const ranges = [
      ['today', 'اليوم'],
      ['week', 'هذا الأسبوع'],
      ['month', 'هذا الشهر'],
      ['all', 'كل الوقت'],
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _brown),
          title: Text(
            widget.kind == HistoryKind.delivered
                ? 'الطلبات السابقة'
                : widget.kind.label,
            style: const TextStyle(
              color: _brown,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ranges.map((r) {
                    final key = r[0];
                    final label = r[1];
                    final selected = controller.range.value == key;
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => controller.setRange(key),
                        backgroundColor: Colors.white,
                        selectedColor: _brown.withOpacity(.15),
                        labelStyle: TextStyle(
                          color: selected ? _brown : _muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        shape: StadiumBorder(
                          side: BorderSide(color: selected ? _brown : _border),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(
                          horizontal: -2,
                          vertical: -2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (controller.loading.value && controller.orders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.orders.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: controller.loadAll,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 90, 18, 18),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _border),
                          ),
                          child: const Text(
                            'لا توجد طلبات مسلّمة لهذا النطاق',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _muted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final orders = controller.orders.toList();
                return RefreshIndicator(
                  onRefresh: controller.loadAll,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                    itemBuilder: (_, i) =>
                        _DeliveredOrderCard(order: orders[i]),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemCount: orders.length,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveredOrderCard extends StatelessWidget {
  const _DeliveredOrderCard({required this.order});

  final Map<String, dynamic> order;

  bool _bad(dynamic value) {
    final s = '$value'.trim();
    if (s.isEmpty || s == 'null') return true;
    final qCount = '?'.allMatches(s).length;
    return qCount >= 3;
  }

  String _first(List<String> keys, {String fallback = '-'}) {
    for (final key in keys) {
      final value = order[key];
      if (!_bad(value)) return '$value'.trim();
    }
    return fallback;
  }

  double _num(dynamic value) {
    return double.tryParse('$value'.replaceAll(',', '').trim()) ?? 0;
  }

  String _dateTime() {
    final raw = _first([
      'delivered_at',
      'completed_at',
      'date',
      'created_at',
      'updated_at',
    ], fallback: '-');
    return raw;
  }

  String _money(dynamic value) {
    final n = _num(value);
    final out = n.truncateToDouble() == n
        ? n.toStringAsFixed(2)
        : n.toStringAsFixed(2);
    return '$out د.ل';
  }

  @override
  Widget build(BuildContext context) {
    final id = _first(['id', 'order_id'], fallback: '0');

    final phone = _first([
      'phone',
      'user_phone',
      'customer_phone',
    ], fallback: '-');

    final customer = _first([
      'user_name',
      'username',
      'customer_name',
      'customer',
      'name',
    ], fallback: phone != '-' ? phone : 'زبون');

    final address = _first([
      'address',
      'user_address',
      'delivery_address',
      'address_text',
      'location',
    ], fallback: '-');

    final total =
        order['grand_total'] ??
        order['final_total'] ??
        order['total_with_delivery'] ??
        order['total'] ??
        order['price'] ??
        order['amount'] ??
        0;

    final statusRaw = '${order['status'] ?? 'delivered'}';
    final rejected = statusRaw == 'rejected' || statusRaw == 'cancelled';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اليسار: الحالة + الهاتف + الوقت
          SizedBox(
            width: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBadge(rejected: rejected),
                const SizedBox(height: 18),
                Text(
                  phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 46),
                Text(
                  _dateTime(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // اليمين: رقم الطلب + الاسم + العنوان + السعر
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '#$id',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: _brown,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 20),
                _RightIconLine(
                  icon: Icons.person_outline_rounded,
                  text: customer,
                  fontSize: 19,
                  bold: true,
                  iconSize: 23,
                ),
                const SizedBox(height: 12),
                _RightIconLine(
                  icon: Icons.location_on_outlined,
                  text: address,
                  fontSize: 17,
                  bold: false,
                  iconSize: 25,
                ),
                const SizedBox(height: 14),
                _RightIconLine(
                  icon: Icons.receipt_long_outlined,
                  text: _money(total),
                  fontSize: 19,
                  bold: true,
                  iconSize: 24,
                  color: _brown,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RightIconLine extends StatelessWidget {
  const _RightIconLine({
    required this.icon,
    required this.text,
    this.fontSize = 14,
    this.bold = false,
    this.iconSize = 18,
    this.color,
  });

  final IconData icon;
  final String text;
  final double fontSize;
  final bool bold;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? _text;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c,
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: _muted, size: iconSize),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.rejected});
  final bool rejected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: rejected ? _redBg : _greenBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        rejected ? 'مرفوضة ×' : 'مكتملة ✓',
        style: TextStyle(
          color: rejected ? _redText : _greenText,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ignore: unused_element
class _MiniLine extends StatelessWidget {
  const _MiniLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _muted, size: 17),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _text,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    // ignore: unused_element_parameter
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: highlighted
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : EdgeInsets.zero,
      decoration: highlighted
          ? BoxDecoration(
              color: _brown.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: highlighted ? _brown : _muted,
                fontWeight: FontWeight.w900,
                fontSize: highlighted ? 13 : 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlighted ? _brown : _text,
              fontWeight: FontWeight.w900,
              fontSize: highlighted ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
