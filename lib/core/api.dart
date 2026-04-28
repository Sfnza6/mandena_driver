import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'env.dart';

class Api {
  static Uri _uri(String path, [Map<String, String>? q]) {
    final cleanBase = Env.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.replaceAll(RegExp(r'^/+'), '');
    return Uri.parse('$cleanBase/$cleanPath').replace(queryParameters: q);
  }

  static Future<Map<String, dynamic>> getJson(
    String path, [
    Map<String, String>? q,
  ]) async {
    final uri = _uri(path, q);
    final res = await http.get(uri).timeout(const Duration(seconds: 20));
    final txt = utf8.decode(res.bodyBytes);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = json.decode(txt);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('INVALID_RESPONSE: $txt');
    }
    throw Exception('HTTP ${res.statusCode}: $txt');
  }

  static Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> data,
  ) async {
    final uri = _uri(path);
    final body = data.map((k, v) => MapEntry(k, '$v'));
    final res = await http
        .post(uri, body: body)
        .timeout(const Duration(seconds: 20));
    final txt = utf8.decode(res.bodyBytes);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = json.decode(txt);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('INVALID_RESPONSE: $txt');
    }
    throw Exception('HTTP ${res.statusCode}: $txt');
  }

  static Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String>? fields,
    Map<String, File>? files,
  }) async {
    final uri = _uri(path);
    final req = http.MultipartRequest('POST', uri);
    fields?.forEach((k, v) => req.fields[k] = v);
    if (files != null) {
      for (final e in files.entries) {
        req.files.add(await http.MultipartFile.fromPath(e.key, e.value.path));
      }
    }
    final resp = await req.send().timeout(const Duration(seconds: 30));
    final bytes = await resp.stream.toBytes();
    final txt = utf8.decode(bytes);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final decoded = json.decode(txt);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('INVALID_RESPONSE: $txt');
    }
    throw Exception('HTTP ${resp.statusCode}: $txt');
  }
}
