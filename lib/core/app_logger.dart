import 'package:flutter/foundation.dart';

/// Emits diagnostic output in debug builds without leaking protocol details
/// into production logs.
void appLog(Object? message) {
  if (kDebugMode) debugPrint(message?.toString());
}
