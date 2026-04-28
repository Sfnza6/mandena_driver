import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/api.dart';
import '../../core/env.dart';

class StatisticsController extends GetxController {
  final range = 'all'.obs;
  final loading = false.obs;
  final error = ''.obs;

  final delivered = 0.obs;
  final rejected = 0.obs;
  final profit = 0.0.obs;
  final debt = 0.0.obs;
  final past = 0.0.obs;

  final _box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> setRange(String value) async {
    if (range.value == value) return;
    range.value = value;
    await load();
  }

  Future<void> load() async {
    if (loading.value) return;
    loading.value = true;
    error.value = '';

    final cacheKey = 'statistics_cache_v2:${Env.driverId}:${range.value}';

    try {
      final cached = _box.read(cacheKey);
      if (cached is Map) {
        _apply(Map<String, dynamic>.from(cached));
      }

      final m = await Api.getJson('dashboard.php', {
        'driver_id': '${Env.driverId}',
        'range': range.value,
      });

      _apply(m);
      await _box.write(cacheKey, m);
    } on SocketException {
      error.value =
          'لا يوجد اتصال بالإنترنت. تم عرض آخر بيانات محفوظة إن وجدت.';
    } on TimeoutException {
      error.value = 'الخادم لم يستجب في الوقت المناسب.';
    } catch (_) {
      error.value = 'تعذر تحميل الإحصائيات.';
    } finally {
      loading.value = false;
    }
  }

  void _apply(Map<String, dynamic> m) {
    delivered.value = _toInt(
      m['delivered'] ??
          m['completed'] ??
          m['completed_orders'] ??
          m['delivered_count'] ??
          m['success'] ??
          0,
    );

    rejected.value = _toInt(
      m['rejected'] ??
          m['cancelled'] ??
          m['rejected_orders'] ??
          m['rejected_count'] ??
          0,
    );

    profit.value = _toDouble(
      m['profit_all'] ??
          m['profit'] ??
          m['total_profit'] ??
          m['sum_profit'] ??
          m['profit_today'] ??
          0,
    );

    debt.value = _toDouble(
      m['debt_all'] ??
          m['debt_total'] ??
          m['total_debt'] ??
          m['sum_debt'] ??
          m['debt_today'] ??
          0,
    );

    past.value = _toDouble(
      m['past'] ??
          m['previous'] ??
          m['previous_balance'] ??
          m['past_balance'] ??
          m['old_balance'] ??
          m['past_debt'] ??
          0,
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value'.replaceAll(',', '')) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse('$value'.replaceAll(',', '')) ?? 0.0;
  }
}
