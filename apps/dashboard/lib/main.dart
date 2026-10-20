import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import 'screens/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await createRepository();
  runApp(DashboardApp(repo: repo, localeModel: LocaleModel.fromDevice()));
}

class DashboardApp extends StatelessWidget {
  final MyOrdersRepository repo;
  final LocaleModel localeModel;
  const DashboardApp({super.key, required this.repo, required this.localeModel});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: repo),
        ChangeNotifierProvider.value(value: localeModel),
        StreamProvider<AppUser?>.value(value: repo.userChanges, initialData: repo.currentUser),
      ],
      child: Consumer<LocaleModel>(
        builder: (context, locale, _) => MaterialApp(
          title: 'MyOrders Dashboard',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          locale: locale.locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const _Gate(),
        ),
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppUser?>();
    if (user == null || !(user.role == UserRole.admin || user.role == UserRole.partner)) {
      return StaffSignInScreen(
        title: context.t('staffSignIn'),
        allowedRoles: const {UserRole.admin, UserRole.partner},
      );
    }
    return DashboardShell(key: ValueKey(user.id), user: user);
  }
}
