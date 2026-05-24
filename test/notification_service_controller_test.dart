import 'package:eternal_guardian/config/app_config.dart';
import 'package:eternal_guardian/services/notification_service_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.kucuba/notification_service');
  final calls = <MethodCall>[];

  tearDown(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('startService passes backend URL to native guardian service', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    await NotificationServiceController.startService();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'startService');
    expect(
      calls.single.arguments,
      <String, Object>{
        'backend_url': AppConfig.backendBaseUrl,
        'use_mock_api': AppConfig.useMockApi,
      },
    );
  });

  test('stopService delegates to native guardian service', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    await NotificationServiceController.stopService();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'stopService');
  });

  test('isRunning returns native service state', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });

    final isRunning = await NotificationServiceController.isRunning();

    expect(isRunning, isTrue);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'isRunning');
  });

  test('isRunning defaults to false when native returns null', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    final isRunning = await NotificationServiceController.isRunning();

    expect(isRunning, isFalse);
    expect(calls, hasLength(1));
    expect(calls.single.method, 'isRunning');
  });
}
