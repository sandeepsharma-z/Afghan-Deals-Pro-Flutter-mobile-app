import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/router/route_names.dart';
import '../../data/models/listing_model.dart';

/// Generic listing detail screen that loads a listing and routes to the appropriate detail screen
class ListingDetailScreen extends ConsumerWidget {
  final String listingId;
  final String? category;

  const ListingDetailScreen({
    super.key,
    required this.listingId,
    this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<ListingModel?>(
      future: _fetchListing(listingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(RouteNames.home);
                  }
                },
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Colors.black87,
                ),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(RouteNames.home);
                  }
                },
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Colors.black87,
                ),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Listing not found',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(RouteNames.home);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Go Back',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final listing = snapshot.data!;
        return _routeToDetailScreen(listing);
      },
    );
  }

  /// Fetch listing from Supabase
  Future<ListingModel?> _fetchListing(String id) async {
    try {
      final response = await Supabase.instance.client
          .from('listings')
          .select()
          .eq('id', id)
          .single();

      return ListingModel.fromMap(response);
    } catch (e) {
      debugPrint('Error fetching listing: $e');
      return null;
    }
  }

  /// Route to the appropriate detail screen based on category
  Widget _routeToDetailScreen(ListingModel listing) {
    final cat = listing.category.toLowerCase().trim();

    switch (cat) {
      case 'cars':
      case 'car':
        // For cars, we pass the listing as-is since CarSaleDetailScreen expects CarSaleModel
        // The screen will need to handle ListingModel or we convert it
        return _buildUnavailableScreen('Car detail screen requires additional setup');

      case 'properties':
      case 'property':
        return _buildUnavailableScreen('Property detail screen requires additional setup');

      case 'mobiles':
      case 'mobile':
        return _buildUnavailableScreen('Mobile detail screen requires additional setup');

      case 'electronics':
      case 'electronic':
        return _buildUnavailableScreen('Electronics detail screen requires additional setup');

      case 'furniture':
        return _buildUnavailableScreen('Furniture detail screen requires additional setup');

      case 'jobs':
      case 'job':
        return _buildUnavailableScreen('Jobs detail screen requires additional setup');

      case 'classifieds':
      case 'classified':
        return _buildUnavailableScreen('Classifieds detail screen requires additional setup');

      case 'spare-parts':
      case 'spare_parts':
        return _buildUnavailableScreen('Spare parts detail screen requires additional setup');

      default:
        return _buildUnavailableScreen('Detail screen not available for this category');
    }
  }

  /// Build a screen showing that the detail view is not available
  Widget _buildUnavailableScreen(String message) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            // This won't work in a non-BuildContext, will be handled by parent
          },
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.black87,
          ),
        ),
      ),
      body: Center(
        child: Text(message),
      ),
    );
  }
}
