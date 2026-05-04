import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/presentation/providers/favorites_provider.dart';

class FavoriteButton extends ConsumerWidget {
  final String listingId;
  final double size;
  final Color backgroundColor;
  final Color unselectedIconColor;
  final Color selectedIconColor;
  final bool showShadow;
  final VoidCallback? onToggle;

  const FavoriteButton({
    super.key,
    required this.listingId,
    this.size = 28,
    this.backgroundColor = Colors.white,
    this.unselectedIconColor = Colors.black54,
    this.selectedIconColor = Colors.red,
    this.showShadow = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoriteIdsProvider);
    final isFavorited = favoriteIds.contains(listingId);

    return GestureDetector(
      onTap: () async {
        await ref.read(favoriteIdsProvider.notifier).toggleFavorite(listingId);
        onToggle?.call();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: showShadow ? const [BoxShadow(color: Color(0x30000000), blurRadius: 4)] : null,
        ),
        child: Icon(
          isFavorited ? Icons.favorite : Icons.favorite_border,
          size: size * 0.57,
          color: isFavorited ? selectedIconColor : unselectedIconColor,
        ),
      ),
    );
  }
}
