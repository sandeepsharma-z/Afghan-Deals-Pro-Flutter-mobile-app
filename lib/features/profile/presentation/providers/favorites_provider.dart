import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  static const String _favoritesKey = 'favorites_listings';
  static SharedPreferences? _prefs;

  FavoritesNotifier() : super(const {}) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final list = _prefs?.getStringList(_favoritesKey) ?? [];
    state = list.toSet();
  }

  Future<void> toggleFavorite(String listingId) async {
    if (state.contains(listingId)) {
      state = state.where((id) => id != listingId).toSet();
    } else {
      state = {...state, listingId};
    }
    await _save();
  }

  Future<void> _save() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setStringList(_favoritesKey, state.toList());
  }
}
