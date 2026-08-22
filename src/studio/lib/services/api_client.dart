import 'dart:convert';

import 'package:http/http.dart' as http;

/// 共享数据服务客户端：地址与令牌由构建期注入
///
/// 本地开发默认 http://localhost:8787/api；
/// 生产构建通过 --dart-define=API_BASE=... --dart-define=QTBUS_TOKEN=... 注入
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const String _base = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:8787/api',
  );
  static const String _token = String.fromEnvironment('QTBUS_TOKEN');

  /// 最近一次请求是否失败（供界面提示网络异常）
  bool lastCallFailed = false;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=utf-8',
    if (_token.isNotEmpty) 'X-Auth-Token': _token,
  };

  Uri _uri(String path) => Uri.parse('$_base/$path');

  /// 拉取全量数据；失败返回 null（由调用方降级）
  Future<Map<String, dynamic>?> getState() async {
    try {
      final res = await http.get(_uri('state'), headers: _headers);
      lastCallFailed = res.statusCode != 200;
      if (res.statusCode != 200) return null;
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      lastCallFailed = true;
      return null;
    }
  }

  /// 新建/更新实体；返回是否成功
  Future<bool> saveEntity(
    String collection,
    String id,
    Map<String, dynamic> json, {
    bool create = false,
  }) async {
    try {
      final body = utf8.encode(jsonEncode(json));
      final res =
          create
          ? await http.post(_uri(collection), headers: _headers, body: body)
          : await http.put(_uri('$collection/$id'), headers: _headers, body: body);
      lastCallFailed = res.statusCode != 200;
      return res.statusCode == 200;
    } catch (_) {
      lastCallFailed = true;
      return false;
    }
  }

  /// 删除实体（业务为级联删除）；返回是否成功
  Future<bool> deleteEntity(String collection, String id) async {
    try {
      final res = await http.delete(
        _uri('$collection/$id'),
        headers: _headers,
      );
      lastCallFailed = res.statusCode != 200;
      return res.statusCode == 200;
    } catch (_) {
      lastCallFailed = true;
      return false;
    }
  }
}
