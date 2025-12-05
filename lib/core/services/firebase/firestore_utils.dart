import 'dart:convert';

Map<String, dynamic> docDataToMap(dynamic raw) {
  if (raw == null) return {};
  try {
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    return Map<String, dynamic>.from(jsonDecode(jsonEncode(raw)));
  } catch (_) {
    return {};
  }
}
