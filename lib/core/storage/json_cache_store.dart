import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CachedJson {
  final Object? data;
  final DateTime cachedAt;

  const CachedJson({required this.data, required this.cachedAt});

  bool isFresh(Duration maxAge) {
    return DateTime.now().difference(cachedAt) <= maxAge;
  }
}

class JsonCacheStore {
  Future<CachedJson?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) return null;

    final cachedAtValue = decoded['cachedAt'];
    final cachedAt = cachedAtValue is String
        ? DateTime.tryParse(cachedAtValue)
        : null;
    if (cachedAt == null) return null;

    return CachedJson(data: decoded['data'], cachedAt: cachedAt);
  }

  Future<void> write(String key, Object? data) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode({
      'cachedAt': DateTime.now().toIso8601String(),
      'data': data,
    });

    await prefs.setString(key, encoded);
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<void> removeByPrefix(String prefix) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(prefix));

    await Future.wait(keys.map(prefs.remove));
  }
}
