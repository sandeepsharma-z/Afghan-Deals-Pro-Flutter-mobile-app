import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/listings_repository_impl.dart';
import '../../domain/entities/listing_entity.dart';
import '../../domain/repositories/listings_repository.dart';

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  return ListingsRepositoryImpl(Supabase.instance.client);
});

// All listings (optional category + country filter)
final listingsProvider = FutureProvider.family<List<ListingEntity>, ({String? category, String? country})>(
  (ref, args) async {
    return ref.read(listingsRepositoryProvider).getListings(
      category: args.category,
      country: args.country,
    );
  },
);

// Single listing detail
final listingDetailProvider = FutureProvider.family<ListingEntity?, String>((ref, id) async {
  return ref.read(listingsRepositoryProvider).getListingById(id);
});

// My listings
final myListingsProvider = FutureProvider.family<List<ListingEntity>, String>((ref, sellerId) async {
  return ref.read(listingsRepositoryProvider).getMyListings(sellerId);
});

// Favorites
final favoritesProvider = FutureProvider.family<List<ListingEntity>, String>((ref, userId) async {
  return ref.read(listingsRepositoryProvider).getFavorites(userId);
});

// Is favorite check
final isFavoriteProvider = FutureProvider.family<bool, ({String userId, String listingId})>(
  (ref, args) async {
    return ref.read(listingsRepositoryProvider).isFavorite(args.userId, args.listingId);
  },
);

// Sell / create listing state
class SellNotifier extends StateNotifier<AsyncValue<String?>> {
  final ListingsRepository _repo;

  SellNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> createListing(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repo.createListing(data);
      state = AsyncValue.data(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final sellNotifierProvider = StateNotifierProvider<SellNotifier, AsyncValue<String?>>((ref) {
  return SellNotifier(ref.read(listingsRepositoryProvider));
});
