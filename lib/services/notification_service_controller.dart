import 'package:flutter/services.dart';

import '../config/app_config.dart';

class NotificationServiceController {
  static const MethodChannel _channel = MethodChannel(
    'com.kucuba/notification_service',
  );

  static Future<void> startService() async {
    await _channel.invokeMethod<void>('startService', {
      'backend_url': AppConfig.backendBaseUrl,
    });
  }

  static Future<void> stopService() async {
    await _channel.invokeMethod<void>('stopService');
  }

  static Future<bool> isRunning() async {
    return await _channel.invokeMethod<bool>('isRunning') ?? false;
  }
}
