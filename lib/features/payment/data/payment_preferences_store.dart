import 'package:shared_preferences/shared_preferences.dart';

class PaymentPreferencesStore {
  static const _hideSaveCardPromptKey = 'payment.hide_save_card_prompt';

  Future<bool> isSaveCardPromptHidden() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_hideSaveCardPromptKey) ?? false;
  }

  Future<void> hideSaveCardPrompt() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_hideSaveCardPromptKey, true);
  }

  Future<void> showSaveCardPrompt() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_hideSaveCardPromptKey);
  }
}
