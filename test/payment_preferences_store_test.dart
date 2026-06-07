import 'package:africanmovies/features/payment/data/payment_preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('hides and restores save card prompt preference', () async {
    final store = PaymentPreferencesStore();

    expect(await store.isSaveCardPromptHidden(), isFalse);

    await store.hideSaveCardPrompt();

    expect(await store.isSaveCardPromptHidden(), isTrue);

    await store.showSaveCardPrompt();

    expect(await store.isSaveCardPromptHidden(), isFalse);
  });
}
