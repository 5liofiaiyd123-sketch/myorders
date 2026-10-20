import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:myorders_dashboard/main.dart';

import 'helpers.dart';

Future<MockRepository> signIn(WidgetTester tester, String email) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = MockRepository();
  await tester.pumpWidget(DashboardApp(repo: repo, localeModel: LocaleModel(const Locale('en'))));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextField, 'Email'), email);
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('partner accepts a new order and edits the menu', (tester) async {
    final repo = await signIn(tester, 'partner@myorders.app');
    expect(find.text('Partner portal'), findsOneWidget);
    expect(find.text('Store open'), findsOneWidget);

    final pending = (await repo.watchStoreOrders('blue-hole').first).firstWhere(
      (o) => o.status == OrderStatus.pending,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
    await tester.pumpAndSettle();
    expect((await repo.watchOrder(pending.id).first)!.status, OrderStatus.accepted);

    await tester.tap(find.text('Menu').first);
    await tester.pumpAndSettle();
    expect(find.text('Grilled Fish Plate'), findsOneWidget);

    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name (English)'), 'Lobster');
    await tester.enterText(find.widgetWithText(TextFormField, 'Name (Arabic)'), 'استاكوزا');
    await tester.enterText(find.widgetWithText(TextFormField, 'Price (EGP)'), '900');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Lobster'), findsOneWidget);
    expect((await repo.products('blue-hole')).any((p) => p.name.en == 'Lobster'), isTrue);
  });

  testWidgets('admin sees stats, stores and riders', (tester) async {
    await signIn(tester, 'admin@myorders.app');
    expect(find.text('Admin panel'), findsOneWidget);
    expect(find.text('Orders today'), findsOneWidget);
    expect(find.text('Sales, last 7 days'), findsOneWidget);

    await tester.tap(find.text('Stores'));
    await tester.pumpAndSettle();
    expect(find.text('Blue Hole Restaurant'), findsOneWidget);

    await tester.tap(find.text('Riders'));
    await tester.pumpAndSettle();
    expect(find.text('Ahmed Salem'), findsOneWidget);
  });

  testWidgets('riders cannot open the dashboard', (tester) async {
    final repo = await signIn(tester, 'rider@myorders.app');
    expect(find.text('This account has no access here.'), findsOneWidget);
    expect(repo.currentUser, isNull);
  });
}
