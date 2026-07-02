import 'package:africanmovies/core/storage/json_cache_store.dart';
import 'package:africanmovies/features/payment/data/pending_native_purchase_store.dart';
import 'package:africanmovies/features/payment/domain/pending_native_purchase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PendingNativePurchaseStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = PendingNativePurchaseStore(cacheStore: JsonCacheStore());
  });

  PendingNativePurchase attempt({
    required String txRef,
    String userId = 'user-1',
    String productId = 'movie-1-rental',
  }) {
    return PendingNativePurchase(
      userId: userId,
      txRef: txRef,
      movieId: 'movie-1',
      productId: productId,
      platform: 'android',
      createdAt: DateTime.utc(2026, 7, 2),
    );
  }

  test('stores attempts per authenticated user', () async {
    await store.upsert(attempt(txRef: 'tx-1'));
    await store.upsert(attempt(txRef: 'tx-2', userId: 'user-2'));

    expect((await store.readAll('user-1')).single.txRef, 'tx-1');
    expect((await store.readAll('user-2')).single.txRef, 'tx-2');
  });

  test('new attempt for the same product replaces the old attempt', () async {
    await store.upsert(attempt(txRef: 'tx-1'));
    await store.upsert(attempt(txRef: 'tx-2'));

    final attempts = await store.readAll('user-1');
    expect(attempts, hasLength(1));
    expect(attempts.single.txRef, 'tx-2');
  });

  test('removes a completed or cancelled attempt', () async {
    await store.upsert(attempt(txRef: 'tx-1'));
    await store.remove(userId: 'user-1', txRef: 'tx-1');

    expect(await store.readAll('user-1'), isEmpty);
  });
}
