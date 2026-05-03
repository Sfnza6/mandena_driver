import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../driver/driver_profile_view.dart';
import '../history/history_types.dart';
import '../history/history_view.dart';
import '../dashboard/driver_dashboard_view.dart';
import '../settlement/financial_settlement_view.dart';
import '../orders/order_details_view.dart';
import 'home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  static const Color _bg = Color(0xFFF7F7F7);
  static const Color _primary = Color(0xFFC15A20);
  static const Color _primaryDark = Color(0xFF8A4C31);
  static const Color _green = Color(0xFF05B94E);
  static const Color _red = Color(0xFFFF3040);
  static const Color _text = Color(0xFF222222);
  static const Color _muted = Color(0xFF7A7A7A);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(HomeController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: RefreshIndicator(
            color: _primary,
            onRefresh: () async {
              await c.loadOrders();
              await c.loadDashboard();
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: _TopHeader(controller: c),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 22)),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'الطلبات الواردة',
                        style: TextStyle(
                          color: _primaryDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                Obx(() {
                  final orders = c.orders.toList();
                  if (orders.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: _EmptyOrdersCard(
                          message: c.isOnline.value
                              ? 'لا توجد طلبات واردة حاليًا. عند اختيارك كأقرب سائق ستظهر الطلبية هنا.'
                              : 'أنت غير متصل. فعّل الحالة لاستقبال الطلبات.',
                        ),
                      ),
                    );
                  }

                  final acceptedCount = c.acceptedOrders.length;

                  return SliverMainAxisGroup(
                    slivers: [
                      if (acceptedCount > 0)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                            child: _StartDeliveryStrip(controller: c),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 34),
                        sliver: SliverList.separated(
                          itemCount: orders.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (_, i) {
                            final order = orders[i];
                            if (c.isOffer(order)) {
                              return _IncomingOrderCard(
                                controller: c,
                                order: order,
                              );
                            }
                            return _AcceptedOrderCard(
                              controller: c,
                              order: order,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.controller});
  final HomeController controller;

  static const Color _primary = HomeView._primary;
  static const Color _green = HomeView._green;

  String _initials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'س';
    final parts = clean.split(RegExp(r'\s+'));
    return parts.take(2).map((e) => e.characters.first).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Obx(() {
              final name = controller.driverName.value;
              return InkWell(
                onTap: () => Get.to(
                  () => const DriverProfileView(),
                  arguments: {
                    'name': controller.driverName.value,
                    'phone': controller.driverPhone.value,
                    'last_seen': controller.driverLastSeen.value,
                  },
                ),
                borderRadius: BorderRadius.circular(999),
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: Colors.white,
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 12),
            Obx(() {
              final busy = controller.actionBusy.value;
              final online = controller.isOnline.value;
              return SizedBox(
                width: 58,
                child: Switch.adaptive(
                  value: online,
                  activeColor: Colors.white,
                  activeTrackColor: _green,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFD8DFE8),
                  onChanged: busy ? null : controller.setOnline,
                ),
              );
            }),
            const SizedBox(width: 10),
            Expanded(
              child: Obx(() {
                final name = controller.driverName.value.trim();
                final phone = controller.driverPhone.value.trim();
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'السائق',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        name.isEmpty ? 'السائق' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (phone.isNotEmpty)
                        Text(
                          phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.82),
                            fontSize: 11,
                            height: 1.1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _openMenu(context),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: _primary,
                  size: 25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMenu(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'إغلاق القائمة',
      barrierColor: Colors.black.withOpacity(.55),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (_, animation, _, _) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.centerRight,
            child: FractionalTranslation(
              translation: Offset(1 - curved.value, 0),
              child: _DriverSideMenu(controller: controller),
            ),
          ),
        );
      },
    );
  }
}

class _DriverSideMenu extends StatelessWidget {
  const _DriverSideMenu({required this.controller});
  final HomeController controller;

  String _initials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'س';
    return clean
        .split(RegExp(r'\s+'))
        .take(2)
        .map((e) => e.characters.first)
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width * .76,
        constraints: const BoxConstraints(maxWidth: 330),
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            bottomLeft: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(-8, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 130,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: const BoxDecoration(
                color: HomeView._primary,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(28)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.28),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Obx(() {
                      final name = controller.driverName.value.trim();
                      final phone = controller.driverPhone.value.trim();
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Text(
                              _initials(name),
                              style: const TextStyle(
                                color: HomeView._primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'السائق',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  name.isEmpty ? 'السائق' : name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                if (phone.isNotEmpty)
                                  Text(
                                    phone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(.78),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _MenuTile(
              icon: Icons.history_rounded,
              title: 'الطلبات السابقة',
              subtitle: 'جميع الطلبات التي تم استلامها وتسليمها',
              onTap: () {
                Navigator.of(context).pop();
                Get.to(
                  () => const HistoryView(
                    kind: HistoryKind.delivered,
                    initialRange: 'all',
                  ),
                );
              },
            ),
            _MenuTile(
              icon: Icons.bar_chart_rounded,
              title: 'الإحصائيات',
              subtitle: 'لوحة تحكم السائق: التسليم، الرفض، الربح، المديونية',
              onTap: () {
                Navigator.of(context).pop();
                Get.to(() => const DriverDashboardView());
              },
            ),
            _MenuTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'التسوية المالية',
              subtitle: 'تصفير المديونية وتسجيل إغلاق الحساب',
              danger: true,
              onTap: () {
                Navigator.of(context).pop();
                Get.to(() => const FinancialSettlementView());
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
              child: OutlinedButton.icon(
                onPressed: controller.logout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('تسجيل الخروج'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: HomeView._primaryDark,
                  side: BorderSide(
                    color: HomeView._primaryDark.withOpacity(.35),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFD82727) : HomeView._primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: danger ? color : HomeView._text,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HomeView._muted,
                          fontSize: 11.5,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded, color: color.withOpacity(.75)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartDeliveryStrip extends StatelessWidget {
  const _StartDeliveryStrip({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final totalAccepted = controller.acceptedOrders.length;
      final startableCount = controller.startableOrders.length;
      final busy = controller.actionBusy.value;

      if (totalAccepted <= 0) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HomeView._primary.withOpacity(.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: HomeView._primary.withOpacity(.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: HomeView._primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'بدأ التوصيل',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: HomeView._text,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        startableCount > 0
                            ? 'سيتم بدء التوصيل لـ $startableCount من أصل $totalAccepted طلبات حالية.'
                            : 'تم بدء التوصيل لكل الطلبات الحالية بالفعل.',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: HomeView._muted,
                          fontSize: 12.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: busy || startableCount <= 0
                    ? null
                    : controller.markAllOnTheWay,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.route_rounded, size: 20),
                label: Text(
                  busy ? 'جاري التنفيذ...' : 'بدأ التوصيل لكل الطلبات',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HomeView._primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _IncomingOrderCard extends StatelessWidget {
  const _IncomingOrderCard({required this.controller, required this.order});
  final HomeController controller;
  final Map<String, dynamic> order;

  static const Color _primary = HomeView._primary;
  static const Color _green = HomeView._green;
  static const Color _red = HomeView._red;

  String _s(dynamic v, [String fallback = '-']) {
    final text = '${v ?? ''}'.trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  double _num(dynamic v) {
    if (v == null) return 0;
    return double.tryParse('$v'.replaceAll(',', '').trim()) ?? 0;
  }

  String _money(dynamic v) {
    final n = _num(v);
    final out = n.truncateToDouble() == n
        ? n.toStringAsFixed(0)
        : n.toStringAsFixed(2);
    return '$out د.ل';
  }

  String _distance() {
    final v =
        order['driver_distance_km'] ??
        order['offer_distance_km'] ??
        order['distance_km'] ??
        order['distance'];
    final n = _num(v);
    if (n <= 0) return '-';
    return '${n.toStringAsFixed(n >= 10 ? 0 : 1)} كم';
  }

  String _title() {
    final branch = _s(order['branch_name'], '');
    final restaurant = _s(order['restaurant_name'], '');
    if (branch.isNotEmpty) return branch;
    if (restaurant.isNotEmpty) return restaurant;
    return 'طلبية #${_s(order['id'], '')}';
  }

  dynamic _orderPrice() {
    if (order['order_price'] != null) return order['order_price'];
    if (order['items_total'] != null) return order['items_total'];
    final total = _num(order['grand_total'] ?? order['total']);
    final delivery = _num(order['delivery_fee'] ?? order['delivery_price']);
    final v = total - delivery;
    return v > 0 ? v : total;
  }

  dynamic _deliveryFee() =>
      order['delivery_fee'] ??
      order['delivery_price'] ??
      order['driver_fee'] ??
      0;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rem = controller.remainingSeconds(order);
      final busy = controller.actionBusy.value;
      final address = _s(order['address'] ?? order['delivery_address'], '-');
      final orderId = _s(order['order_id'] ?? order['id'], '');
      final warning = rem <= 10;

      return _DriverOrderShell(
        onTap: () => Get.to(() => const OrderDetailsView(), arguments: order),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBadge(
                  text: rem > 0 ? 'عرض جديد' : 'انتهى العرض',
                  icon: warning ? Icons.timer_off_rounded : Icons.bolt_rounded,
                  color: warning ? _red : _primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        orderId.isEmpty ? 'طلبية جديدة' : 'طلبية #$orderId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: HomeView._text,
                          fontSize: 21,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _title(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: HomeView._muted,
                          fontSize: 12.5,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _InfoBox(
                    icon: Icons.route_outlined,
                    label: 'المسافة',
                    value: _distance(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoBox(
                    icon: Icons.timer_outlined,
                    label: 'وقت الرد',
                    value: rem > 0 ? '$rem ثانية' : 'انتهى الوقت',
                    color: warning ? _red : _primary,
                    softColor: warning
                        ? _red.withOpacity(.08)
                        : _primary.withOpacity(.08),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _AddressBox(address: address),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PricePill(
                    label: 'قيمة الطلب',
                    value: _money(_orderPrice()),
                    icon: Icons.receipt_long_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PricePill(
                    label: 'التوصيل',
                    value: _money(_deliveryFee()),
                    icon: Icons.delivery_dining_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    text: 'رفض',
                    icon: Icons.close_rounded,
                    color: _red,
                    disabled: busy || rem <= 0,
                    onTap: () => controller.rejectOffer(order),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    text: 'قبول',
                    icon: Icons.check_rounded,
                    color: _green,
                    disabled: busy || rem <= 0,
                    onTap: () => controller.acceptOffer(order),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _AcceptedOrderCard extends StatelessWidget {
  const _AcceptedOrderCard({required this.controller, required this.order});
  final HomeController controller;
  final Map<String, dynamic> order;

  static const Color _primary = HomeView._primary;
  static const Color _primaryDark = HomeView._primaryDark;
  static const Color _green = HomeView._green;

  String _s(dynamic v, [String fallback = '-']) {
    final text = '${v ?? ''}'.trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  int _id() => int.tryParse('${order['order_id'] ?? order['id'] ?? 0}') ?? 0;

  String _branchName() {
    final branch = _s(order['branch_name'], '');
    if (branch.isNotEmpty) return branch;

    final branchAlt = _s(order['branch'], '');
    if (branchAlt.isNotEmpty) return branchAlt;

    return 'الفرع غير محدد';
  }

  String _phone() => _s(order['phone'] ?? order['user_phone']);

  String _customerName() => _s(order['username'] ?? order['user_name']);

  String _address() =>
      _s(order['address'] ?? order['delivery_address'], 'لا يوجد عنوان');

  (String, Color, IconData) _statusBadge() {
    final st = controller.orderStatus(order);
    final isAuto = controller.isDirectAssignment(order);

    switch (st) {
      case 'processing':
      case 'approved':
      case 'accepted':
        return (
          'جاري التحضير',
          const Color(0xFF1976D2),
          Icons.restaurant_rounded,
        );
      case 'assigned':
      case 'ready':
      case 'ready_for_driver':
        return (
          isAuto ? 'تعيين تلقائي' : 'جاهز للاستلام',
          const Color(0xFF7B1FA2),
          Icons.check_circle_outline_rounded,
        );
      case 'delivering':
      case 'on_the_way':
      case 'out_for_delivery':
        return (
          'جاري التوصيل',
          const Color(0xFFE65100),
          Icons.delivery_dining_rounded,
        );
      default:
        return (
          isAuto ? 'تعيين تلقائي' : 'مقبولة',
          _primaryDark,
          Icons.assignment_turned_in_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = '${order['maps_url'] ?? ''}'.trim();
    final orderId = _id();
    final branchName = _branchName();
    final customerName = _customerName();
    final phone = _phone();
    final address = _address();
    final (badgeText, badgeColor, badgeIcon) = _statusBadge();
    final canStart = controller.canStartDeliveryFor(order);

    return _DriverOrderShell(
      onTap: () => Get.to(() => const OrderDetailsView(), arguments: order),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusBadge(text: badgeText, icon: badgeIcon, color: badgeColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      orderId > 0 ? 'طلبية #$orderId' : 'طلبية',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: HomeView._text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'الفرع: $branchName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: HomeView._muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  icon: Icons.person_outline_rounded,
                  label: 'الزبون',
                  value: customerName,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoBox(
                  icon: Icons.phone_outlined,
                  label: 'الهاتف',
                  value: phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _AddressBox(address: address),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _OutlineOrderButton(
                  label: 'الموقع',
                  icon: Icons.directions_rounded,
                  enabled: url.isNotEmpty,
                  onTap: url.isEmpty
                      ? null
                      : () => launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        ),
                ),
              ),
              if (canStart) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _FilledOrderButton(
                    label: 'بدأ التوصيل',
                    icon: Icons.route_rounded,
                    color: const Color(0xFFE65100),
                    enabled: orderId > 0,
                    onTap: () => controller.markOnTheWay(orderId),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: _FilledOrderButton(
                  label: 'تم التسليم',
                  icon: Icons.check_rounded,
                  color: _green,
                  enabled: orderId > 0,
                  onTap: () => controller.markDelivered(orderId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DriverOrderShell extends StatelessWidget {
  const _DriverOrderShell({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: HomeView._primary.withOpacity(.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.055),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.icon,
    required this.color,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.label,
    required this.value,
    this.color = HomeView._primary,
    this.softColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color? softColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: softColor ?? const Color(0xFFF9F5F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: HomeView._muted,
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: HomeView._text,
                    fontSize: 13.5,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
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

class _AddressBox extends StatelessWidget {
  const _AddressBox({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeView._primary.withOpacity(.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: HomeView._primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'العنوان',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: HomeView._muted,
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: HomeView._text,
                    fontSize: 13.2,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
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

class _PricePill extends StatelessWidget {
  const _PricePill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: HomeView._primary.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeView._primary.withOpacity(.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: HomeView._primary, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: HomeView._muted,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: HomeView._primaryDark,
                    fontSize: 13.6,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
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

class _OutlineOrderButton extends StatelessWidget {
  const _OutlineOrderButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 15),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: HomeView._primary,
          side: BorderSide(color: HomeView._primary.withOpacity(.35)),
          disabledForegroundColor: HomeView._muted.withOpacity(.45),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _FilledOrderButton extends StatelessWidget {
  const _FilledOrderButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 15),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.2),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(.35),
          disabledForegroundColor: Colors.white.withOpacity(.7),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.disabled,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final Color color;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? .55 : 1,
      child: SizedBox(
        height: 44,
        child: ElevatedButton.icon(
          onPressed: disabled ? null : onTap,
          icon: Icon(icon, size: 18),
          label: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyOrdersCard extends StatelessWidget {
  const _EmptyOrdersCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.inbox_outlined, color: HomeView._primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: HomeView._muted,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
