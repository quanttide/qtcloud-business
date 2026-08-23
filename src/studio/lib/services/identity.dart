import 'package:shared_preferences/shared_preferences.dart';

/// 当前操作人（需求六最小闭环）：本机署名，随留痕与操作历史上报。
/// v0.1 无账号体系，署名存本机；服务端从请求头读取并记入历史。
class Identity {
  Identity._();

  static const String _key = 'biz_operator_name';

  /// 当前操作人（main 启动时加载）
  static String current = '';

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      current = prefs.getString(_key) ?? '';
    } catch (_) {
      current = '';
    }
  }

  static Future<void> save(String name) async {
    current = name.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, current);
    } catch (_) {}
  }

  /// 署名展示值：未设置时显示"未署名"
  static String get displayName => current.isEmpty ? '未署名' : current;
}
