import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/listing_entity.dart';
import '../../domain/repositories/listings_repository.dart';
import '../models/listing_model.dart';

class ListingsRepositoryImpl implements ListingsRepository {
  final SupabaseClient _client;

  ListingsRepositoryImpl(this._client);

  @override
  Future<List<ListingEntity>> getListings({String? category, String? country}) async {
    var query = _client.from('listings').select().eq('is_active', true);

    if (category != null) query = query.eq('category', category);
    if (country != null) query = query.eq('country', country);

    final response = await query.order('created_at', ascending: false).limit(50);
    return (response as List).map((e) => ListingModel.fromMap(e)).toList();
  }

  @override
  Future<ListingEntity?> getListingById(String id) async {
    final response = await _client.from('listings').select().eq('id', id).maybeSingle();
    if (response == null) return null;
    return ListingModel.fromMap(response);
  }

  @override
  Future<String> createListing(Map<String, dynamic> data) async {
    final response = await _client.from('listings').insert(data).select('id').single();
    return response['id'] as String;
  }

  @override
  Future<void> updateListing(String id, Map<String, dynamic> data) async {
    await _client.from('listings').update(data).eq('id', id);
  }

  @override
  Future<void> deleteListing(String id) async {
    await _client.from('listings').delete().eq('id', id);
  }

  @override
  Future<void> incrementViewCount(String id) async {
    await _client.rpc('increment_view_count', params: {'listing_id': id});
  }

  @override
  Future<List<ListingEntity>> searchListings(String query) async {
    final response = await _client
        .from('listings')
        .select()
        .eq('is_active', true)
        .ilike('title', '%$query%')
        .order('created_at', ascending: false)
        .limit(50);
    return (response as List).map((e) => ListingModel.fromMap(e)).toList();
  }

  @override
  Future<List<ListingEntity>> getMyListings(String sellerId) async {
    final response = await _client
        .from('listings')
        .select()
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => ListingModel.fromMap(e)).toList();
  }

  @override
  Future<List<ListingEntity>> getFavorites(String userId) async {
    final response = await _client
        .from('favorites')
        .select('listing_id, listings(*)')
        .eq('user_id', userId)
        .order('added_at', ascending: false);
    return (response as List)
        .map((e) => ListingModel.fromMap(e['listings']))
        .toList();
  }

  @override
  Future<void> addFavorite(String userId, String listingId) async {
    await _client.from('favorites').insert({
      'user_id': userId,
      'listing_id': listingId,
    });
  }

  @override
  Future<void> removeFavorite(String userId, String listingId) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('listing_id', listingId);
  }

  @override
  Future<bool> isFavorite(String userId, String listingId) async {
    final response = await _client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('listing_id', listingId)
        .maybeSingle();
    return response != null;
  }
}
