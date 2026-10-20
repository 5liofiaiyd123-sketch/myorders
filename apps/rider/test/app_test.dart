import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:myorders_rider/main.dart';

import 'helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('rider signs in, takes a ready order and delivers it', (tester) async {
    usePhoneScreen(tester);
    final repo = MockRepository();
    await tester.pumpWidget(RiderApp(repo: repo, localeModel: LocaleModel(const Locale('en'))));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'rider@myorders.app');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'x');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Ahmed Salem'), findsOneWidget);

    final ready = (await repo.watchAvailableDeliveries().first).firstWhere(
      (o) => o.status == OrderStatus.ready,
    );
    await tester.tap(
      find
          .widgetWithText(FilledButton, 'Take order')
          .at((await repo.watchAvailableDeliveries().first).indexOf(ready)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Order #${ready.code}'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Picked up'));
    await tester.pumpAndSettle();
    expect((await repo.watchOrder(ready.id).first)!.status, OrderStatus.pickedUp);

    await tester.tap(find.textContaining('Delivered ·'));
    await tester.pumpAndSettle();
    expect((await repo.watchOrder(ready.id).first)!.status, OrderStatus.delivered);
  });

  testWidgets('only riders can sign in to the rider app', (tester) async {
    usePhoneScreen(tester);
    final repo = MockRepository();
    await tester.pumpWidget(RiderApp(repo: repo, localeModel: LocaleModel(const Locale('en'))));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'admin@myorders.app');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('This account has no access here.'), findsOneWidget);
    expect(repo.currentUser, isNull);
  });
}
