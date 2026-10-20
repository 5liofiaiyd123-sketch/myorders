import 'package:flutter/material.dart';

import 'data/models.dart';

/// Colors taken from the light "beach / teal" design.
class AppColors {
  static const teal = Color(0xFF0E8FA3);
  static const tealDark = Color(0xFF0A6C7C);
  static const tealLight = Color(0xFFE3F4F6);
  static const sand = Color(0xFFF6F1E7);
  static const promo = Color(0xFFFFC233); // yellow borrowed from the dark design
  static const text = Color(0xFF1B2B34);
  static const textMuted = Color(0xFF5B6B73);
  static const border = Color(0xFFE2E8EA);
  static const star = Color(0xFFF5A623);

  static const food = Color(0xFFF5782B);
  static const drinks = Color(0xFF2E86DE);
  static const supermarket = Color(0xFF2EAE5F);
  static const pharmacy = Color(0xFF8E5BD8);
  static const delivery = Color(0xFFE5483B);
  static const more = Color(0xFF7C8A92);
}

/// Cairo, bundled in this package, covers Arabic and Latin.
const appFont = 'packages/myorders_core/Cairo';

/// Status colors used on order chips across the apps.
Color statusColor(OrderStatus s) => switch (s) {
  OrderStatus.pending => const Color(0xFFE58A00),
  OrderStatus.accepted || OrderStatus.preparing => AppColors.drinks,
  OrderStatus.ready => AppColors.pharmacy,
  OrderStatus.pickedUp => AppColors.teal,
  OrderStatus.delivered => AppColors.supermarket,
  OrderStatus.cancelled => AppColors.delivery,
};

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: appFont,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      primary: AppColors.teal,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFF7FAFA),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: appFont,
        color: AppColors.text,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.teal,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontFamily: appFont, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.tealLight,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontFamily: appFont, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
  );
}
