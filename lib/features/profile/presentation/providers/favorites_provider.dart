import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  static const String _favoritesKey = 'favorites_listings';
  late SharedPreferences _prefs;
  bool _initialized = false;

  FavoritesNotifier() : super(const {}) {
    _initAsync();
  }

  Future<void> _initAsync() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      final list = _prefs.getStringList(_favoritesKey) ?? [];
      state = list.toSet();
      _initialized = true;
    } catch (e) {
      _initialized = true;
    }
  }

  Future<void> toggleFavorite(String listingId) async {
    // Ensure initialized before toggling
    if (!_initialized) {
      await _initAsync();
    }

    if (state.contains(listingId)) {
      state = state.where((id) => id != listingId).toSet();
    } else {
      state = {...state, listingId};
    }
    await _save();
  }

  Future<void> _save() async {
    try {
      await _prefs.setStringList(_favoritesKey, state.toList());
    } catch (e) {
      // Silently fail if save doesn't work
    }
  }
}
