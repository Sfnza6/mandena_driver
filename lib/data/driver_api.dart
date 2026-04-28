import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/env.dart';

class DriverApi {
  static Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> q,
  ) async {
    final uri = Uri.parse('${Env.baseUrl}/$path').replace(queryParameters: q);
    final r = await http.get(uri);
    final j = json.decode(r.body);
    if (j['status'] != 'ok') throw Exception(j['message'] ?? 'API error');
    return j['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, String> body,
  ) async {
    final r = await http.post(Uri.parse('${Env.baseUrl}/$path'), body: body);
    final j = json.decode(r.body);
    if (j['status'] != 'ok') throw Exception(j['message'] ?? 'API error');
    return j['data'] as Map<String, dynamic>;
  }

  /// الطلبات المكلّف بها (نفس حالاتك الحالية)
  static Future<List<dynamic>> getAssignedOrders() async {
    final data = await _get('orders_assigned.php', {
      'driver_id': '${Env.driverId}',
      'status': 'assigned,delivering', // ← متوافقة مع جدولك الحالي
    });
    return data['orders'] as List<dynamic>;
  }

  /// لوحة الإحصائيات
  static Future<Map<String, dynamic>> getDashboard(String range) async {
    final data = await _get('dashboard.php', {
      'driver_id': '${Env.driverId}',
      'range': range, // all | month | today
    });
    return data;
  }

  /// تغيير حالة الطلب (تم التسليم / تم الرفض)
  static Future<bool> updateOrder({
    required int orderId,
    required String action, // delivered | rejected
    String? reason,
  }) async {
    await _post('order_update_status.php', {
      'order_id': '$orderId',
      'driver_id': '${Env.driverId}',
      'action': action,
      'reason': ?reason,
    });
    return true;
  }
}
