import 'package:flutter/material.dart';

class LocaleModel extends ChangeNotifier {
  Locale _locale;
  LocaleModel(this._locale);

  /// Arabic when the device is in Arabic, English otherwise.
  factory LocaleModel.fromDevice() {
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    return LocaleModel(Locale(device.languageCode == 'ar' ? 'ar' : 'en'));
  }

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  void toggle() {
    _locale = isArabic ? const Locale('en') : const Locale('ar');
    notifyListeners();
  }
}
