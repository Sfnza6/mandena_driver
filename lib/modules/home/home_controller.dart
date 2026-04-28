import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/api.dart';
import '../../core/bg_location_service.dart';
import '../../core/env.dart';
import '../../core/power_optimizations.dart';

class HomeController extends GetxController {
  final loading = false.obs;
  final actionBusy = false.obs;

  final range = 'all'.obs;
  final isOnline = false.obs;

  final driverName = ''.obs;
  final driverPhone = ''.obs;
  final driverLastSeen = ''.obs;

  final delivered = 0.obs;
  final rejected = 0.obs;
  final profitAll = 0.0.obs;
  final duesToday = 0.0.obs;
  final debtToday = 0.0.obs;

  final orders = <Map<String, dynamic>>[].obs;
  final nowTick = DateTime.now().obs;

  Timer? _poller;
  Timer? _secondTicker;
  bool _isTicking = false;
  late final GetStorage _box;

  static const String _cachePrefix = 'home_cache_v2_driver_offers';
  static const Duration _ttlOrders = Duration(seconds: 20);
  static const Duration _ttlDriverInfo = Duration(hours: 6);

  @override
  void onInit() {
    super.onInit();
    _box = GetStorage();

    if (Env.driverId == 0) {
      Get.offAllNamed('/login');
      return;
    }

    isOnline.value = _box.read('driverOnline') == true;
    _hydrateFromCache();

    loadDriverInfo();
    _tick();

    _poller = Timer.periodic(Env.pollInterval, (_) => _tick());
    _secondTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      nowTick.value = DateTime.now();
      _removeExpiredLocalOffers();
    });
  }

  @override
  void onClose() {
    _poller?.cancel();
    _secondTicker?.cancel();
    super.onClose();
  }

  String _k(String bucket) => '$_cachePrefix:${Env.driverId}:$bucket';

  Duration _ttlDashboardForRange(String r) {
    switch (r) {
      case 'today':
        return const Duration(minutes: 2);
      case 'week':
        return const Duration(minutes: 5);
      case 'month':
        return const Duration(minutes: 10);
      case 'all':
      default:
        return const Duration(minutes: 15);
    }
  }

  Map<String, dynamic>? _readCache(String key, {required bool preferFresh}) {
    final raw = _box.read(key);
    if (raw is! Map) return null;

    final cachedAt = _asInt(raw['cached_at']);
    final ttlMs = _asInt(raw['ttl_ms']);
    if (cachedAt == null || ttlMs == null) return null;

    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final isFresh = (now - cachedAt) <= ttlMs;
    if (preferFresh && !isFresh) return null;

    return raw.map((k, v) => MapEntry(k.toString(), v));
  }

  Future<void> _writeCache(
    String key,
    Map<String, dynamic> payload,
    Duration ttl,
  ) async {
    await _box.write(key, <String, dynamic>{
      ...payload,
      'cached_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      'ttl_ms': ttl.inMilliseconds,
    });
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }

  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0.0;
  }

  void _hydrateFromCache() {
    final dash = _readCache(_k('dashboard:${range.value}'), preferFresh: true);
    if (dash != null) _applyDashboardFromCache(dash);

    final ord = _readCache(_k('orders'), preferFresh: true);
    if (ord != null) _applyOrdersFromCache(ord);

    final drv = _readCache(_k('driver_info'), preferFresh: true);
    if (drv != null) _applyDriverFromCache(drv);
  }

  Future<void> _tick() async {
    if (_isTicking) return;
    _isTicking = true;
    try {
      await Future.wait([loadDashboard(), loadOrders()]);

      if (isOnline.value) {
        await _pushDriverStatus(true);
        await _sendDriverPing();
        try {
          await BackgroundLocationService.start(Env.driverId);
        } catch (_) {}
      }
    } finally {
      _isTicking = false;
    }
  }

  Future<void> loadDriverInfo() async {
    final cacheKey = _k('driver_info');
    final cached = _readCache(cacheKey, preferFresh: true);
    if (cached != null) _applyDriverFromCache(cached);

    try {
      Map<String, dynamic> r = await Api.getJson('driver_profile.php', {
        'driver_id': '${Env.driverId}',
      });

      if (r['status'] != 'ok' && r['driver'] == null) {
        r = await Api.getJson('driver_me.php', {
          'driver_id': '${Env.driverId}',
        });
      }

      final d = (r['driver'] ?? r['data'] ?? r) as Map<String, dynamic>?;
      final name = (d?['name'] ?? '').toString();
      final phone = (d?['phone'] ?? '').toString();
      final last = (d?['last_seen'] ?? '').toString();

      driverName.value = name;
      driverPhone.value = phone;
      driverLastSeen.value = last;

      await _writeCache(cacheKey, {
        'name': name,
        'phone': phone,
        'last_seen': last,
      }, _ttlDriverInfo);
    } catch (_) {
      final any = _readCache(cacheKey, preferFresh: false);
      if (any != null) _applyDriverFromCache(any);
    }
  }

  void _applyDriverFromCache(Map<String, dynamic> c) {
    driverName.value = (c['name'] ?? '').toString();
    driverPhone.value = (c['phone'] ?? '').toString();
    driverLastSeen.value = (c['last_seen'] ?? '').toString();
  }

  Future<void> loadDashboard() async {
    final cacheKey = _k('dashboard:${range.value}');
    final ttl = _ttlDashboardForRange(range.value);

    final cached = _readCache(cacheKey, preferFresh: true);
    if (cached != null) _applyDashboardFromCache(cached);

    try {
      final m = await Api.getJson('dashboard.php', {
        'driver_id': '${Env.driverId}',
        'range': range.value,
      });

      delivered.value = _asInt(m['delivered']) ?? 0;
      rejected.value = _asInt(m['rejected']) ?? 0;
      profitAll.value = _asDouble(m['profit_all']);
      duesToday.value = _asDouble(m['dues_today']);
      debtToday.value = _asDouble(m['debt_today']);

      await _writeCache(cacheKey, {
        'delivered': delivered.value,
        'rejected': rejected.value,
        'profit_all': profitAll.value,
        'dues_today': duesToday.value,
        'debt_today': debtToday.value,
      }, ttl);
    } catch (_) {
      final any = _readCache(cacheKey, preferFresh: false);
      if (any != null) _applyDashboardFromCache(any);
    }
  }

  void _applyDashboardFromCache(Map<String, dynamic> c) {
    delivered.value = _asInt(c['delivered']) ?? 0;
    rejected.value = _asInt(c['rejected']) ?? 0;
    profitAll.value = _asDouble(c['profit_all']);
    duesToday.value = _asDouble(c['dues_today']);
    debtToday.value = _asDouble(c['debt_today']);
  }

  Future<void> loadOrders() async {
    final cacheKey = _k('orders');
    final cached = _readCache(cacheKey, preferFresh: true);
    if (cached != null) _applyOrdersFromCache(cached);

    try {
      final m = await Api.getJson('orders_assigned.php', {
        'driver_id': '${Env.driverId}',
      });
      final list = (m['orders'] ?? m['data']?['orders'] ?? []) as List;
      orders.assignAll(
        list.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );
      _sortOrders();
      _removeExpiredLocalOffers();

      await _writeCache(cacheKey, {'orders': orders.toList()}, _ttlOrders);
    } catch (_) {
      final any = _readCache(cacheKey, preferFresh: false);
      if (any != null) _applyOrdersFromCache(any);
    }
  }

  void _applyOrdersFromCache(Map<String, dynamic> c) {
    final list = (c['orders'] ?? const []) as List;
    orders.assignAll(
      list.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
    _sortOrders();
    _removeExpiredLocalOffers();
  }

  void _sortOrders() {
    orders.sort((a, b) {
      final ao = isOffer(a) ? 0 : 1;
      final bo = isOffer(b) ? 0 : 1;
      if (ao != bo) return ao.compareTo(bo);
      final ai = _asInt(a['id']) ?? 0;
      final bi = _asInt(b['id']) ?? 0;
      return bi.compareTo(ai);
    });
  }

  bool isOffer(Map<String, dynamic> o) =>
      '${o['assignment_type'] ?? ''}' == 'offer';

  bool isAcceptedOrder(Map<String, dynamic> o) => !isOffer(o);

  String orderStatus(Map<String, dynamic> o) {
    return '${o['status_order'] ?? o['status'] ?? ''}'.toLowerCase().trim();
  }

  bool canStartDeliveryFor(Map<String, dynamic> o) {
    final st = orderStatus(o);
    if (st.isEmpty) return true;
    return !(st.contains('delivering') ||
        st.contains('on_the_way') ||
        st.contains('out_for_delivery') ||
        st.contains('delivered') ||
        st.contains('success') ||
        st.contains('cancel'));
  }

  List<Map<String, dynamic>> get acceptedOrders => orders
      .where(isAcceptedOrder)
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  List<Map<String, dynamic>> get startableOrders =>
      acceptedOrders.where(canStartDeliveryFor).toList();

  int remainingSeconds(Map<String, dynamic> o) {
    nowTick.value;
    final direct = _asInt(o['offer_remaining_seconds']);
    final expiresAt = DateTime.tryParse('${o['offer_expires_at'] ?? ''}');
    if (expiresAt != null) {
      final diff = expiresAt.difference(DateTime.now()).inSeconds;
      return diff < 0 ? 0 : diff;
    }
    return direct == null || direct < 0 ? 0 : direct;
  }

  void _removeExpiredLocalOffers() {
    final before = orders.length;
    orders.removeWhere((o) => isOffer(o) && remainingSeconds(o) <= 0);
    if (orders.length != before) {
      _writeCache(_k('orders'), {'orders': orders.toList()}, _ttlOrders);
    }
  }

  Future<void> setOnline(bool v) async {
    if (actionBusy.value) return;
    actionBusy.value = true;
    final old = isOnline.value;
    isOnline.value = v;
    await _box.write('driverOnline', v);

    try {
      if (v) {
        await PowerOptimizations.maybePromptOnce();
        await _ensureLocationReady();
        await _pushDriverStatus(true);
        await _sendDriverPing();
        await BackgroundLocationService.start(Env.driverId);
      } else {
        await _pushDriverStatus(false);
        await BackgroundLocationService.stop();
      }

      Get.snackbar(
        'الحالة',
        v
            ? 'أنت متصل الآن وستصلك الطلبات القريبة منك'
            : 'أنت غير متصل ولن تصلك طلبات جديدة',
        snackPosition: SnackPosition.BOTTOM,
      );
      await loadOrders();
    } catch (e) {
      isOnline.value = old;
      await _box.write('driverOnline', old);
      Get.snackbar(
        'تعذر تغيير الحالة',
        '$e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      actionBusy.value = false;
    }
  }

  Future<void> _pushDriverStatus(bool online) async {
    await Api.postJson('driver_toggle_online.php', {
      'driver_id': '${Env.driverId}',
      'online': online ? '1' : '0',
    });
  }

  Future<void> _ensureLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('فعّل خدمة الموقع أولًا');

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw Exception('يجب السماح بصلاحية الموقع للسائق');
    }
  }

  Future<void> _sendDriverPing() async {
    try {
      await _ensureLocationReady();
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      await Api.postJson('driver_ping.php', {
        'driver_id': '${Env.driverId}',
        'lat': pos.latitude.toStringAsFixed(7),
        'lng': pos.longitude.toStringAsFixed(7),
        'is_online': isOnline.value ? '1' : '0',
        'is_available': '1',
      });
    } catch (_) {}
  }

  Future<void> acceptOffer(Map<String, dynamic> order) async {
    final orderId = _asInt(order['id']);
    if (orderId == null || actionBusy.value) return;
    actionBusy.value = true;
    try {
      final r = await Api.postJson('driver_respond_offer.php', {
        'order_id': '$orderId',
        'driver_id': '${Env.driverId}',
        'action': 'accept',
      });
      if (r['ok'] == true || r['status'] == 'ok' || r['status'] == 'assigned') {
        Get.snackbar(
          'تم القبول',
          'تم تعيين الطلب #$orderId عليك',
          snackPosition: SnackPosition.BOTTOM,
        );
        await loadOrders();
        await loadDashboard();
      } else {
        Get.snackbar(
          'تنبيه',
          '${r['message'] ?? 'لم يتم قبول العرض'}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar('تعذر القبول', '$e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      actionBusy.value = false;
    }
  }

  Future<void> rejectOffer(Map<String, dynamic> order) async {
    final orderId = _asInt(order['id']);
    if (orderId == null || actionBusy.value) return;
    actionBusy.value = true;
    try {
      final r = await Api.postJson('driver_respond_offer.php', {
        'order_id': '$orderId',
        'driver_id': '${Env.driverId}',
        'action': 'reject',
      });
      if (r['ok'] == true || r['status'] == 'ok') {
        Get.snackbar(
          'تم الرفض',
          'تم تمرير الطلب لسائق آخر',
          snackPosition: SnackPosition.BOTTOM,
        );
        orders.removeWhere((o) => _asInt(o['id']) == orderId && isOffer(o));
        await loadOrders();
      } else {
        Get.snackbar(
          'تنبيه',
          '${r['message'] ?? 'لم يتم رفض العرض'}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar('تعذر الرفض', '$e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      actionBusy.value = false;
    }
  }

  Future<void> markAllOnTheWay() async {
    final batch = startableOrders;
    if (batch.isEmpty || actionBusy.value) {
      if (batch.isEmpty) {
        Get.snackbar(
          'تنبيه',
          'لا توجد طلبات بحاجة إلى بدء التوصيل حالياً',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return;
    }

    actionBusy.value = true;
    try {
      int successCount = 0;
      int failedCount = 0;

      for (final order in batch) {
        final orderId = _asInt(order['order_id'] ?? order['id']);
        if (orderId == null || orderId <= 0) {
          failedCount++;
          continue;
        }

        try {
          final r = await Api.postJson('driver_update_order_status.php', {
            'order_id': '$orderId',
            'driver_id': '${Env.driverId}',
            'action': 'delivering',
          });

          if (r['ok'] == true || r['status'] == 'ok') {
            successCount++;
          } else {
            failedCount++;
          }
        } catch (_) {
          failedCount++;
        }
      }

      await loadOrders();
      await loadDashboard();

      final message = failedCount > 0
          ? 'تم بدء التوصيل لـ $successCount طلبات وتعذر تحديث $failedCount.'
          : 'تم بدء التوصيل لـ $successCount طلبات بنجاح.';

      Get.snackbar(
        successCount > 0 ? 'تم' : 'تنبيه',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      actionBusy.value = false;
    }
  }

  Future<void> markOnTheWay(int orderId) async {
    await _updateAssignedOrder(orderId, 'delivering', 'تم بدء التوصيل');
  }

  Future<void> markDelivered(int orderId) async {
    await _updateAssignedOrder(orderId, 'delivered', 'تم تسليم الطلب');
  }

  Future<void> markRejected(int orderId, {String? reason}) async {
    await _updateAssignedOrder(
      orderId,
      'rejected',
      'تم رفض الطلب',
      reason: reason,
    );
  }

  Future<void> _updateAssignedOrder(
    int orderId,
    String action,
    String okMessage, {
    String? reason,
  }) async {
    if (actionBusy.value) return;
    actionBusy.value = true;
    try {
      final r = await Api.postJson('driver_update_order_status.php', {
        'order_id': '$orderId',
        'driver_id': '${Env.driverId}',
        'action': action,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      if (r['ok'] == true || r['status'] == 'ok') {
        Get.snackbar('تم', okMessage, snackPosition: SnackPosition.BOTTOM);
        await loadOrders();
        await loadDashboard();
      } else {
        Get.snackbar(
          'تنبيه',
          '${r['message'] ?? 'لم يتم التحديث'}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar('خطأ', '$e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      actionBusy.value = false;
    }
  }

  Future<void> closeDriverDaily() async {
    if (loading.value) return;
    loading.value = true;
    try {
      final r = await Api.postJson('close_driver_daily.php', {
        'driver_id': '${Env.driverId}',
        'period': 'day',
      });
      Get.snackbar(
        r['status'] == 'ok' ? 'تم' : 'تنبيه',
        '${r['message'] ?? 'تمت العملية'}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      loading.value = false;
      await _tick();
    }
  }

  Future<void> closeRestaurantDaily() async {
    if (loading.value) return;
    loading.value = true;
    try {
      final r = await Api.postJson('close_restaurant_daily.php', {
        'driver_id': '${Env.driverId}',
        'period': 'day',
      });
      Get.snackbar(
        r['status'] == 'ok' ? 'تم' : 'تنبيه',
        '${r['message'] ?? 'تمت العملية'}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      loading.value = false;
      await _tick();
    }
  }

  Future<void> _invalidateHomeCache() async {
    for (final k in [
      _k('orders'),
      _k('driver_info'),
      _k('dashboard:today'),
      _k('dashboard:week'),
      _k('dashboard:month'),
      _k('dashboard:all'),
    ]) {
      await _box.remove(k);
    }
  }

  Future<void> logout() async {
    try {
      await setOnline(false);
    } catch (_) {}
    await _invalidateHomeCache();
    await _box.remove('driverId');
    await _box.remove('driverOnline');
    Env.driverId = 0;
    Get.offAllNamed('/login');
  }
}
