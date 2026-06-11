import 'package:africanmovies/features/payment/application/payment_providers.dart';
import 'package:africanmovies/features/payment/data/payment_preferences_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  test(
    'save-card prompt controller mirrors ask-after-checkout preference',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        await container.read(saveCardPromptPreferenceControllerProvider.future),
        isTrue,
      );

      await container
          .read(saveCardPromptPreferenceControllerProvider.notifier)
          .setShouldAskAfterCheckout(false);

      expect(
        container.read(saveCardPromptPreferenceControllerProvider).value,
        isFalse,
      );
      expect(await PaymentPreferencesStore().isSaveCardPromptHidden(), isTrue);

      await container
          .read(saveCardPromptPreferenceControllerProvider.notifier)
          .setShouldAskAfterCheckout(true);

      expect(
        container.read(saveCardPromptPreferenceControllerProvider).value,
        isTrue,
      );
      expect(await PaymentPreferencesStore().isSaveCardPromptHidden(), isFalse);
    },
  );
}
