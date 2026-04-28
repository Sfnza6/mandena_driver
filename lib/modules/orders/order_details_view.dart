import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../home/home_controller.dart';

class OrderDetailsView extends StatelessWidget {
  const OrderDetailsView({super.key});

  static const _bg = Color(0xFFF7F7F7);
  static const _card = Colors.white;
  static const _text = Color(0xFF222222);
  static const _textMute = Color(0xFF8B8B92);
  static const _divider = Color(0xFFECE2DA);
  static const _primary = Color(0xFFC15A20);
  static const _primaryDark = Color(0xFF8A4C31);
  static const _green = Color(0xFF05B94E);
  static const _red = Color(0xFFFF3040);

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String okText,
  }) async {
    final res = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: _card,
        title: Text(
          title,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            color: _primaryDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          style: const TextStyle(color: _text, fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(okText),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return res == true;
  }

  String _s(dynamic v, [String fallback = '-']) {
    final text = '${v ?? ''}'.trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  String _money(dynamic v) {
    final n = double.tryParse('${v ?? 0}'.replaceAll(',', '').trim()) ?? 0;
    final text = n.truncateToDouble() == n
        ? n.toStringAsFixed(0)
        : n.toStringAsFixed(2);
    return '$text د.ل';
  }

  int _orderId(Map<String, dynamic> o) {
    return int.tryParse('${o['order_id'] ?? o['id'] ?? 0}') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> o = Map<String, dynamic>.from(
      (Get.arguments ?? {}) as Map,
    );
    final c = Get.find<HomeController>();
    final isOffer = c.isOffer(o);
    final orderId = _orderId(o);
    final customerName = _s(o['username']);
    final phone = _s(o['phone']);
    final branchName = _s(o['branch_name']);
    final address = _s(o['address'], 'لا يوجد عنوان');
    final itemsText = _s(o['items_text'], '');
    final mapUrl = _s(o['maps_url'], '');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: _primaryDark),
          centerTitle: true,
          title: Text(
            'طلب #$orderId',
            style: const TextStyle(
              color: _primaryDark,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            _HeaderSummaryCard(
              orderId: orderId,
              branchName: branchName,
              isOffer: isOffer,
              remainingBuilder: isOffer
                  ? Obx(
                      () => Text(
                        '${c.remainingSeconds(o)} ثانية',
                        style: const TextStyle(
                          color: _primaryDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : const Text(
                      'طلب نشط',
                      style: TextStyle(
                        color: _primaryDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    title: 'رقم الهاتف',
                    value: phone,
                    icon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoCard(
                    title: 'اسم العميل',
                    value: customerName,
                    icon: Icons.person_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoCard(
              title: 'العنوان',
              value: address,
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    title: 'رسوم التوصيل',
                    value: _money(o['delivery_fee']),
                    icon: Icons.local_shipping_outlined,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoCard(
                    title: 'سعر الطلبية',
                    value: _money(o['total']),
                    icon: Icons.receipt_long_outlined,
                    compact: true,
                  ),
                ),
              ],
            ),
            if (itemsText.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _InfoCard(
                title: 'العناصر',
                value: itemsText,
                icon: Icons.fastfood_outlined,
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: mapUrl.isEmpty
                    ? null
                    : () => launchUrl(
                        Uri.parse(mapUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                icon: const Icon(Icons.map_outlined, size: 20),
                label: const Text(
                  'إظهار الموقع على الخرائط',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _primaryDark.withOpacity(.35),
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Obx(() {
              final busy = c.actionBusy.value;
              if (isOffer) {
                final rem = c.remainingSeconds(o);
                return Row(
                  children: [
                    Expanded(
                      child: _MainActionButton(
                        text: 'رفض',
                        color: _red,
                        onPressed: busy || rem <= 0
                            ? null
                            : () async {
                                await c.rejectOffer(o);
                                Get.back();
                              },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MainActionButton(
                        text: 'قبول الطلب',
                        color: _green,
                        onPressed: busy || rem <= 0
                            ? null
                            : () async {
                                await c.acceptOffer(o);
                                if (Get.isOverlaysOpen) return;
                                Get.back();
                              },
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  // SizedBox(
                  //   width: double.infinity,
                  //   height: 52,
                  //   child: OutlinedButton.icon(
                  //     onPressed: busy ? null : () => c.markOnTheWay(orderId),
                  //     icon: const Icon(Icons.route_outlined, size: 20),
                  //     label: const Text(
                  //       'بدأ التوصيل',
                  //       style: TextStyle(
                  //         fontWeight: FontWeight.w800,
                  //         fontSize: 15,
                  //       ),
                  //     ),
                  //     style: OutlinedButton.styleFrom(
                  //       foregroundColor: _primary,
                  //       side: BorderSide(color: _primary.withOpacity(.55)),
                  //       backgroundColor: Colors.white,
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(16),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MainActionButton(
                          text: 'رفض',
                          color: _red,
                          onPressed: busy
                              ? null
                              : () async {
                                  final ok = await _confirmAction(
                                    title: 'تأكيد الرفض',
                                    message: 'هل تريد رفض الطلب #$orderId؟',
                                    okText: 'تأكيد',
                                  );
                                  if (!ok) return;
                                  await c.markRejected(
                                    orderId,
                                    reason: 'رفض السائق',
                                  );
                                  Get.back();
                                },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MainActionButton(
                          text: 'تم التسليم',
                          color: _green,
                          onPressed: busy
                              ? null
                              : () async {
                                  final ok = await _confirmAction(
                                    title: 'تأكيد التسليم',
                                    message: 'هل تم تسليم الطلب #$orderId؟',
                                    okText: 'تأكيد',
                                  );
                                  if (!ok) return;
                                  await c.markDelivered(orderId);
                                  Get.back();
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _HeaderSummaryCard extends StatelessWidget {
  const _HeaderSummaryCard({
    required this.orderId,
    required this.branchName,
    required this.isOffer,
    required this.remainingBuilder,
  });

  final int orderId;
  final String branchName;
  final bool isOffer;
  final Widget remainingBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [OrderDetailsView._primary, OrderDetailsView._primaryDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'طلب #$orderId',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الفرع: $branchName',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.92),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  isOffer ? 'مهلة القبول' : 'الحالة',
                  style: const TextStyle(
                    color: OrderDetailsView._textMute,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                remainingBuilder,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    this.compact = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: OrderDetailsView._card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OrderDetailsView._divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.045),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: OrderDetailsView._primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: OrderDetailsView._primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: OrderDetailsView._textMute,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: OrderDetailsView._text,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MainActionButton extends StatelessWidget {
  const _MainActionButton({
    required this.text,
    required this.color,
    required this.onPressed,
  });

  final String text;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(.38),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    );
  }
}
