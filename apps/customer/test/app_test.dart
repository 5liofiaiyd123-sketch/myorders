import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myorders/main.dart';
import 'package:myorders_core/myorders_core.dart';

/// Loads the real Cairo font so text is measured like on a phone.
Future<void> loadFonts() async {
  final loader = FontLoader('packages/myorders_core/Cairo');
  for (final w in [400, 500, 600, 700, 800]) {
    final bytes = File('../../packages/core/assets/fonts/Cairo-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<MockRepository> pumpApp(WidgetTester tester, {String lang = 'en'}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final repo = MockRepository();
  await tester.pumpWidget(MyOrdersApp(repo: repo, localeModel: LocaleModel(Locale(lang))));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUpAll(loadFonts);

  testWidgets('home shows all sections', (tester) async {
    await pumpApp(tester);
    for (final label in ['Food', 'Drinks', 'Supermarket', 'Pharmacy', 'Delivery', 'More']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.text('Popular in Dahab'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Blue Hole Restaurant'), findsWidgets);
  });

  testWidgets('home is translated to Arabic', (tester) async {
    await pumpApp(tester, lang: 'ar');
    expect(find.text('أكل'), findsOneWidget);
    expect(find.text('صيدلية'), findsOneWidget);
  });

  testWidgets('customer orders food end to end', (tester) async {
    final repo = await pumpApp(tester);

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blue Hole Restaurant'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add').first);
    await tester.pumpAndSettle();
    expect(find.text('View cart'), findsOneWidget);

    await tester.tap(find.text('View cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Place order'));
    await tester.pumpAndSettle();

    // Not signed in yet, so the app asks for a phone number first.
    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Sara');
    await tester.enterText(find.widgetWithText(TextField, 'Phone number'), '01012345678');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('Verify'));
    // Checkout continues by itself after signing in. The tracking screen
    // has a running spinner, so pump a few frames instead of settling.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(repo.currentUser?.name, 'Sara');
    expect(repo.currentUser?.phone, '+201012345678');

    expect(find.textContaining('Order #'), findsOneWidget);
    expect(find.text('Order placed'), findsOneWidget);
    final mine = await repo.watchMyOrders().first;
    expect(mine.first.storeId, 'blue-hole');
    expect(mine.first.customerName, 'Sara');
  });
}
