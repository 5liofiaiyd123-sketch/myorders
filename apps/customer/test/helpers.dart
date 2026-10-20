// Test helpers shared by this app's widget tests.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the real Cairo font so text is measured like on a phone.
/// [coreDir] is the path to packages/core from the app's directory.
Future<void> loadAppFonts({String coreDir = '../../packages/core'}) async {
  final loader = FontLoader('packages/myorders_core/Cairo');
  for (final w in [400, 500, 600, 700, 800]) {
    final bytes = File('$coreDir/assets/fonts/Cairo-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

/// A phone-sized test screen.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
