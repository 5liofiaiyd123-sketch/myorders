import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import 'cart.dart';
import 'screens/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await createRepository(simulateProgress: true);
  runApp(MyOrdersApp(repo: repo, localeModel: LocaleModel.fromDevice()));
}

class MyOrdersApp extends StatelessWidget {
  final MyOrdersRepository repo;
  final LocaleModel localeModel;
  const MyOrdersApp({super.key, required this.repo, required this.localeModel});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: repo),
        ChangeNotifierProvider.value(value: localeModel),
        ChangeNotifierProvider(create: (_) => CartModel()),
        ChangeNotifierProvider(create: (_) => FavoritesModel(repo)),
        StreamProvider<AppUser?>.value(value: repo.userChanges, initialData: repo.currentUser),
      ],
      child: Consumer<LocaleModel>(
        builder: (context, locale, _) => MaterialApp(
          title: 'MyOrders Dahab',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          locale: locale.locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const AppShell(),
        ),
      ),
    );
  }
}
