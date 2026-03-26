import '../entities/listing_entity.dart';

abstract class ListingsRepository {
  Future<List<ListingEntity>> getListings({String? category, String? country});
  Future<ListingEntity?> getListingById(String id);
  Future<String> createListing(Map<String, dynamic> data);
  Future<void> updateListing(String id, Map<String, dynamic> data);
  Future<void> deleteListing(String id);
  Future<void> incrementViewCount(String id);
  Future<List<ListingEntity>> searchListings(String query);
  Future<List<ListingEntity>> getMyListings(String sellerId);
  Future<List<ListingEntity>> getFavorites(String userId);
  Future<void> addFavorite(String userId, String listingId);
  Future<void> removeFavorite(String userId, String listingId);
  Future<bool> isFavorite(String userId, String listingId);
}
