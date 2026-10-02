import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings({this.persistent = false});
  final bool persistent;
  static const _keyUserName = 'user_name';
  static const _keyLang = 'lang_code';
  static const _keyOnboarded = 'onboarded';

  late SharedPreferences _prefs;
  String _userName = '';
  String _langCode = 'th';
  bool _onboarded = false;

  String get userName => _userName;
  String get langCode => _langCode;
  bool get isFirstLaunch => !_onboarded;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _userName = persistent ? (_prefs.getString(_keyUserName) ?? '') : '';
    _langCode = _prefs.getString(_keyLang) ?? 'th';
    _onboarded = persistent ? (_prefs.getBool(_keyOnboarded) ?? false) : false;
  }

  Future<void> completeOnboarding(String name) async {
    _userName = name.trim();
    _onboarded = true;
    if (persistent) await _prefs.setString(_keyUserName, _userName);
    if (persistent) await _prefs.setBool(_keyOnboarded, true);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _langCode = _langCode == 'th' ? 'en' : 'th';
    await _prefs.setString(_keyLang, _langCode);
    notifyListeners();
  }

  Future<void> updateUserName(String name) async {
    _userName = name.trim();
    if (persistent) await _prefs.setString(_keyUserName, _userName);
    notifyListeners();
  }
}
