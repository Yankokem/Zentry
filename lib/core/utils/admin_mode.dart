import 'package:flutter/foundation.dart';

/// Simple front-end only admin mode flag for testing.
/// Use `AdminMode.enabled` as a `ValueNotifier<bool>` so UI can listen.
class AdminMode {
  AdminMode._();

  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  static void toggle() => enabled.value = !enabled.value;

  static void set(bool value) => enabled.value = value;
}
