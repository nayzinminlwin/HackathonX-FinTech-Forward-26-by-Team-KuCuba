import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const layoutFiles = <String>[
    'android/app/src/main/res/layout/notification_idle.xml',
    'android/app/src/main/res/layout/notification_scanning.xml',
    'android/app/src/main/res/layout/notification_status.xml',
    'android/app/src/main/res/layout/notification_result.xml',
  ];

  test('native notification layouts inherit the system card surface', () {
    for (final path in layoutFiles) {
      final content = File(path).readAsStringSync();

      expect(
        content,
        isNot(contains('android:background="#1A1A1A"')),
        reason: '$path should not draw a black box inside the system card.',
      );
      expect(
        content,
        isNot(contains('android:textColor=')),
        reason: '$path should use notification text appearances so Android '
            'chooses readable colors for the current system theme.',
      );
      expect(
        content,
        contains('TextAppearance.Compat.Notification'),
        reason: '$path should use Android notification text appearances.',
      );
    }
  });

  test('native notification surfaces use Eternal Guardian naming', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(manifest, contains('android:label="Eternal Guardian"'));

    for (final path in layoutFiles) {
      final content = File(path).readAsStringSync();
      expect(
        content,
        contains('Eternal Guardian'),
        reason: '$path should make the notification source clear.',
      );
    }
  });
}
