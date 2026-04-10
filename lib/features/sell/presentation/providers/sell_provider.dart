import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── State ──────────────────────────────────────────────────────────────────────

class SellState {
  final List<XFile> images;
  final bool isSubmitting;
  final String? error;
  final bool success;
  final String? createdListingId;

  const SellState({
    this.images = const [],
    this.isSubmitting = false,
    this.error,
    this.success = false,
    this.createdListingId,
  });

  SellState copyWith({
    List<XFile>? images,
    bool? isSubmitting,
    String? error,
    bool? success,
    String? createdListingId,
  }) {
    return SellState(
      images: images ?? this.images,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      success: success ?? this.success,
      createdListingId: createdListingId ?? this.createdListingId,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────────

class SellNotifier extends StateNotifier<SellState> {
  SellNotifier() : super(const SellState());

  final _picker = ImagePicker();
  final _client = Supabase.instance.client;

  static const int _maxImages = 10;
  static const String _bucket = 'listing-images';

  // ── Image picking ────────────────────────────────────────────────────────────

  Future<void> pickFromGallery() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    final combined = [...state.images, ...picked];
    state = state.copyWith(
      images: combined.length > _maxImages
          ? combined.sublist(0, _maxImages)
          : combined,
    );
  }

  Future<void> pickFromCamera() async {
    if (state.images.length >= _maxImages) return;
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked == null) return;
    state = state.copyWith(images: [...state.images, picked]);
  }

  void removeImage(int index) {
    final updated = [...state.images]..removeAt(index);
    state = state.copyWith(images: updated);
  }

  void reorderImages(int oldIndex, int newIndex) {
    final updated = [...state.images];
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = state.copyWith(images: updated);
  }

  // ── Upload ───────────────────────────────────────────────────────────────────

  Future<List<String>> _uploadImages(String listingId) async {
    final urls = <String>[];
    for (int i = 0; i < state.images.length; i++) {
      final file = File(state.images[i].path);
      final ext = state.images[i].path.split('.').last.toLowerCase();
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final path = 'listings/$listingId/$i.$ext';

      await _client.storage.from(_bucket).upload(
        path,
        file,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );

      final url = _client.storage.from(_bucket).getPublicUrl(path);
      urls.add(url);
    }
    return urls;
  }

  // ── Create listing ───────────────────────────────────────────────────────────

  Future<void> createListing({
    required String category,
    required Map<String, dynamic> baseData,
    required Map<String, dynamic> categoryData,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null, success: false);

    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Please log in to post an ad');

      // Fetch seller name from profiles
      final profile = await _client
          .from('profiles')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();
      final manualSellerName = (baseData['seller_name']?.toString() ?? '').trim();
      final normalizedCategory = category.trim().toLowerCase().replaceAll('_', '-');

      final insertData = {
        ...baseData,
        'category': normalizedCategory,
        'category_data': categoryData,
        'seller_id': user.id,
        'seller_name': manualSellerName.isNotEmpty
            ? manualSellerName
            : (profile?['name'] ?? ''),
        'country': baseData['country'] ?? 'Afghanistan',
        'images': <String>[],
        // User-posted listings stay pending until admin approval.
        'is_active': false,
        'is_featured': false,
        'view_count': 0,
      };

      // Insert listing to get the ID
      final response = await _client
          .from('listings')
          .insert(insertData)
          .select('id')
          .single();
      final listingId = response['id'] as String;

      // Upload images and update listing
      if (state.images.isNotEmpty) {
        final imageUrls = await _uploadImages(listingId);
        await _client
            .from('listings')
            .update({'images': imageUrls})
            .eq('id', listingId);
      }

      state = state.copyWith(
        isSubmitting: false,
        success: true,
        createdListingId: listingId,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() => state = const SellState();
}

// ── Provider ───────────────────────────────────────────────────────────────────

final sellProvider =
    StateNotifierProvider.autoDispose<SellNotifier, SellState>(
  (ref) => SellNotifier(),
);
