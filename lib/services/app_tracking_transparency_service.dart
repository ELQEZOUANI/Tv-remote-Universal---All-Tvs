import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/app_logger.dart';

enum TrackingAuthorizationStatus {
  authorized,
  denied,
  restricted,
  notDetermined,
  notSupported,
  unavailable,
}

/// Requests Apple's App Tracking Transparency authorization on iOS.
///
/// Other platforms do not require ATT and return [TrackingAuthorizationStatus.notSupported].
class AppTrackingTransparencyService {
  AppTrackingTransparencyService._();

  static const _channel = MethodChannel('tvremote/app_tracking_transparency');

  static Future<TrackingAuthorizationStatus> requestAuthorization() async {
    if (kIsWeb || !Platform.isIOS) {
      return TrackingAuthorizationStatus.notSupported;
    }

    try {
      final value = await _channel.invokeMethod<String>(
        'requestTrackingAuthorization',
      );
      return _statusFromPlatform(value);
    } on MissingPluginException catch (error) {
      appLog('ATT is unavailable: $error');
      return TrackingAuthorizationStatus.unavailable;
    } on PlatformException catch (error) {
      appLog('ATT request failed: ${error.message}');
      return TrackingAuthorizationStatus.unavailable;
    }
  }

  static TrackingAuthorizationStatus _statusFromPlatform(String? status) {
    return switch (status) {
      'authorized' => TrackingAuthorizationStatus.authorized,
      'denied' => TrackingAuthorizationStatus.denied,
      'restricted' => TrackingAuthorizationStatus.restricted,
      'notDetermined' => TrackingAuthorizationStatus.notDetermined,
      'notSupported' => TrackingAuthorizationStatus.notSupported,
      _ => TrackingAuthorizationStatus.unavailable,
    };
  }
}
