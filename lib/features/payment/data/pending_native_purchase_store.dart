import '../../../core/storage/json_cache_store.dart';
import '../domain/pending_native_purchase.dart';

class PendingNativePurchaseStore {
  PendingNativePurchaseStore({required JsonCacheStore cacheStore})
    : _cacheStore = cacheStore;

  static const _keyPrefix = 'payment.native.pending.';

  final JsonCacheStore _cacheStore;

  Future<List<PendingNativePurchase>> readAll(String userId) async {
    final cached = await _cacheStore.read(_key(userId));
    final data = cached?.data;
    if (data is! List) return const [];

    return data
        .whereType<Map>()
        .map(
          (item) =>
              PendingNativePurchase.fromJson(Map<String, dynamic>.from(item)),
        )
        .where(
          (attempt) =>
              attempt.userId == userId &&
              attempt.txRef.isNotEmpty &&
              attempt.productId.isNotEmpty,
        )
        .toList();
  }

  Future<void> upsert(PendingNativePurchase attempt) async {
    final attempts = await readAll(attempt.userId);
    final updated =
        attempts
            .where(
              (item) =>
                  item.txRef != attempt.txRef &&
                  item.productId != attempt.productId,
            )
            .toList()
          ..add(attempt);

    await _cacheStore.write(
      _key(attempt.userId),
      updated.map((item) => item.toJson()).toList(),
    );
  }

  Future<void> remove({required String userId, required String txRef}) async {
    final attempts = await readAll(userId);
    final updated = attempts.where((item) => item.txRef != txRef).toList();

    if (updated.isEmpty) {
      await _cacheStore.remove(_key(userId));
      return;
    }

    await _cacheStore.write(
      _key(userId),
      updated.map((item) => item.toJson()).toList(),
    );
  }

  String _key(String userId) => '$_keyPrefix$userId';
}
