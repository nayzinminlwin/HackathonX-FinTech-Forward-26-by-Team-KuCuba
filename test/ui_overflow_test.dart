import 'package:eternal_guardian/providers/analysis_provider.dart';
import 'package:eternal_guardian/providers/stats_provider.dart';
import 'package:eternal_guardian/screens/home_screen.dart';
import 'package:eternal_guardian/screens/overlay_screen.dart';
import 'package:eternal_guardian/services/mock_api_service.dart';
import 'package:eternal_guardian/theme/bank_islam_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const notificationChannel = MethodChannel('com.kucuba/notification_service');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationChannel, (call) async {
      if (call.method == 'isRunning') return false;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationChannel, null);
  });

  testWidgets('core app screens do not overflow on compact viewport',
      (tester) async {
    await _setCompactViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_appShell(const ScamDetectorPage()));
    await tester.pump();
    _expectNoFlutterException(tester);

    await tester.tap(find.text('Quick Scan'));
    await tester.pumpAndSettle();
    _expectNoFlutterException(tester);

    await tester.enterText(
      find.byType(TextField),
      'PDRM: Your IC is linked to a case. Transfer RM5000 now.',
    );
    await tester.tap(find.text('Analyze'));
    await tester.pump();
    _expectNoFlutterException(tester);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    _expectNoFlutterException(tester);
  });

  testWidgets('share overlay does not overflow on compact viewport',
      (tester) async {
    await _setCompactViewport(tester, height: 480);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_appShell(OverlayScreen(
      sharedText:
          'Tahniah! Anda menang hadiah RM10,000. Klik bit.ly/example-now '
          'untuk tuntut hadiah sebelum tengah malam. Sila masukkan TAC.',
      onDismiss: () {},
    )));

    await tester.pump();
    _expectNoFlutterException(tester);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    _expectNoFlutterException(tester);
  });
}

Future<void> _setCompactViewport(
  WidgetTester tester, {
  double width = 320,
  double height = 568,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
}

Widget _appShell(Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AnalysisProvider(MockApiService())),
      ChangeNotifierProvider(create: (_) => StatsProvider()),
    ],
    child: MaterialApp(
      theme: bankIslamTheme(),
      home: home,
    ),
  );
}

void _expectNoFlutterException(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception == null) return;

  if (exception is FlutterError) {
    fail(exception.toStringDeep());
  }

  fail(exception.toString());
}
