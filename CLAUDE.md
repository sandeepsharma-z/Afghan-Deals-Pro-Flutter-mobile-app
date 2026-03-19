# Afghan Deals Pro — Cursor Rules & Architecture Guide

> This file is the single source of truth for AI-assisted development.
> Every screen, widget, provider, and model MUST follow these rules.
> Do NOT deviate from this structure under any circumstances.

---

## 1. Project Overview

**App:** Afghan Deals Pro — Buy & Sell Classified Marketplace (OLX/Dubizzle style)
**Platform:** Flutter (iOS + Android)
**Backend:** Firebase (Firestore + Auth + Storage + FCM)
**State Management:** Riverpod (flutter_riverpod + hooks_riverpod)
**Navigation:** GoRouter
**Architecture:** Feature-first Clean Architecture

---

## 2. Tech Stack — Exact Packages

```yaml
# pubspec.yaml dependencies
flutter_riverpod: ^2.5.1
riverpod_annotation: ^2.3.5
hooks_riverpod: ^2.5.1
flutter_hooks: ^0.20.5
go_router: ^13.2.0
firebase_core: ^2.30.0
firebase_auth: ^4.19.0
cloud_firestore: ^4.17.0
firebase_storage: ^11.7.0
firebase_messaging: ^14.9.0
freezed_annotation: ^2.4.1
json_annotation: ^4.9.0
cached_network_image: ^3.3.1
image_picker: ^1.1.2
google_fonts: ^6.2.1
dio: ^5.4.3
equatable: ^2.0.5
intl: ^0.19.0
shared_preferences: ^2.2.3
flutter_secure_storage: ^9.0.0
geolocator: ^11.0.0

# dev_dependencies
build_runner: ^2.4.9
freezed: ^2.5.2
json_serializable: ^6.8.0
riverpod_generator: ^2.4.0
custom_lint: ^0.6.4
riverpod_lint: ^2.3.10
```

---

## 3. Folder Structure — STRICTLY FOLLOW THIS

```
lib/
├── main.dart
├── firebase_options.dart
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart        # All colors defined here
│   │   ├── app_text_styles.dart   # All text styles
│   │   ├── app_theme.dart         # ThemeData
│   │   └── app_dimensions.dart    # Spacing, radius constants
│   ├── router/
│   │   ├── app_router.dart        # GoRouter config
│   │   └── route_names.dart       # All route name constants
│   ├── constants/
│   │   ├── app_constants.dart     # App-wide constants
│   │   └── firestore_paths.dart   # All Firestore collection/doc paths
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   └── extensions.dart
│   ├── error/
│   │   ├── app_exception.dart
│   │   └── failure.dart
│   └── widgets/
│       ├── app_button.dart        # Primary reusable button
│       ├── app_text_field.dart    # Reusable input field
│       ├── app_bottom_nav.dart    # Bottom navigation bar
│       ├── app_loading.dart       # Loading indicator
│       ├── listing_card.dart      # Reusable listing card
│       └── empty_state.dart      # Empty state widget
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart    # abstract interface
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart
│   │   │   └── screens/
│   │   │       ├── splash_screen.dart
│   │   │       ├── onboarding_screen.dart
│   │   │       ├── sign_in_screen.dart
│   │   │       ├── sign_up_screen.dart
│   │   │       ├── forgot_password_screen.dart
│   │   │       ├── otp_screen.dart
│   │   │       └── phone_login_screen.dart
│   │
│   ├── home/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── home_provider.dart
│   │       └── screens/
│   │           └── home_screen.dart
│   │
│   ├── listings/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── listing_model.dart         # base listing
│   │   │   │   ├── car_listing_model.dart
│   │   │   │   ├── property_listing_model.dart
│   │   │   │   ├── mobile_listing_model.dart
│   │   │   │   ├── electronics_listing_model.dart
│   │   │   │   ├── furniture_listing_model.dart
│   │   │   │   ├── spare_parts_listing_model.dart
│   │   │   │   ├── jobs_listing_model.dart
│   │   │   │   └── classified_listing_model.dart
│   │   │   └── repositories/
│   │   │       └── listings_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── listing_entity.dart
│   │   │   └── repositories/
│   │   │       └── listings_repository.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── listings_provider.dart
│   │       │   └── filter_provider.dart
│   │       └── screens/
│   │           ├── listing_detail_screen.dart
│   │           ├── search_results_screen.dart
│   │           └── filter_screen.dart
│   │
│   ├── sell/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── sell_provider.dart
│   │       └── screens/
│   │           ├── sell_screen.dart           # category picker
│   │           ├── post_car_screen.dart
│   │           ├── post_property_screen.dart
│   │           ├── post_mobile_screen.dart
│   │           ├── post_electronics_screen.dart
│   │           ├── post_furniture_screen.dart
│   │           ├── post_jobs_screen.dart
│   │           └── post_classified_screen.dart
│   │
│   ├── chat/
│   │   ├── data/
│   │   │   └── models/
│   │   │       ├── chat_model.dart
│   │   │       └── message_model.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── chat_provider.dart
│   │       └── screens/
│   │           ├── chats_screen.dart
│   │           └── message_screen.dart
│   │
│   ├── profile/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── profile_provider.dart
│   │       └── screens/
│   │           ├── profile_screen.dart
│   │           ├── my_ads_screen.dart
│   │           ├── favorites_screen.dart
│   │           ├── notifications_screen.dart
│   │           └── account_settings_screen.dart
│   │
│   └── categories/
│       ├── cars/
│       │   └── presentation/screens/
│       │       ├── cars_screen.dart
│       │       ├── car_detail_screen.dart
│       │       ├── rental_cars_screen.dart
│       │       └── cars_filter_screen.dart
│       ├── properties/
│       │   └── presentation/screens/
│       │       ├── properties_screen.dart
│       │       └── properties_filter_screen.dart
│       ├── mobiles/
│       ├── electronics/
│       ├── furniture/
│       ├── spare_parts/
│       ├── jobs/
│       └── classifieds/
```

---

## 4. Design Tokens — ALWAYS USE THESE, NEVER HARDCODE COLORS

```dart
// core/theme/app_colors.dart
class AppColors {
  // Primary
  static const primary = Color(0xFF027329);       // Main green
  static const primaryDark = Color(0xFF015C20);
  static const primaryLight = Color(0xFFE8F5E9);

  // Accent
  static const red = Color(0xFFC92325);           // Deals red
  static const redLight = Color(0xFFFEEBEB);

  // Neutrals
  static const black = Color(0xFF090909);
  static const grey = Color(0xFF7C7C7C);
  static const greyLight = Color(0xFFF6F6F6);
  static const greyBorder = Color(0xFFE0E0E0);
  static const white = Color(0xFFFFFFFF);

  // Backgrounds
  static const background = Color(0xFFFFFFFF);
  static const surfaceGrey = Color(0xFFF8F8F8);

  // Status
  static const success = Color(0xFF027329);
  static const warning = Color(0xFFFFA000);
  static const error = Color(0xFFC92325);
}
```

```dart
// core/theme/app_text_styles.dart
// Font: Work Sans (google_fonts package)
class AppTextStyles {
  static TextStyle heading1 = GoogleFonts.workSans(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.5);
  static TextStyle heading2 = GoogleFonts.workSans(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3);
  static TextStyle heading3 = GoogleFonts.workSans(fontSize: 18, fontWeight: FontWeight.w600);
  static TextStyle body     = GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w400);
  static TextStyle bodyBold = GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w600);
  static TextStyle caption  = GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.grey);
  static TextStyle small    = GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w400);
  static TextStyle button   = GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.48);
}
```

```dart
// core/theme/app_dimensions.dart
class AppDimensions {
  // Spacing
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;

  // Radius
  static const radiusSm  = 4.0;
  static const radiusMd  = 8.0;
  static const radiusLg  = 16.0;
  static const radiusXl  = 24.0;
  static const radiusFull = 100.0;

  // Button
  static const buttonHeight = 44.0;
  static const buttonRadius = 8.0;

  // Screen padding
  static const screenPadding = 16.0;

  // Bottom nav height
  static const bottomNavHeight = 72.0;
}
```

---

## 5. Naming Conventions — ALWAYS FOLLOW

| What | Convention | Example |
|---|---|---|
| Files | snake_case | `car_listing_model.dart` |
| Classes | PascalCase | `CarListingModel` |
| Variables | camelCase | `listingTitle` |
| Constants | camelCase | `primaryColor` |
| Providers | camelCase + Provider suffix | `authProvider`, `listingsProvider` |
| Screens | PascalCase + Screen suffix | `HomeScreen`, `CarDetailScreen` |
| Widgets | PascalCase + no suffix if reusable | `ListingCard`, `AppButton` |
| Routes | `/kebab-case` | `/car-detail`, `/sign-in` |
| Firestore collections | camelCase | `listings`, `users`, `chats` |

---

## 6. Firestore Data Structure

```
firestore/
├── users/{userId}
│   ├── uid: string
│   ├── name: string
│   ├── email: string
│   ├── phone: string
│   ├── avatarUrl: string
│   ├── country: string
│   ├── region: string
│   ├── createdAt: timestamp
│   └── isVerified: bool
│
├── listings/{listingId}
│   ├── id: string
│   ├── category: string        # 'cars' | 'properties' | 'mobiles' | etc.
│   ├── subcategory: string
│   ├── title: string
│   ├── description: string
│   ├── price: number
│   ├── currency: string        # 'AFN' | 'USD'
│   ├── images: string[]
│   ├── sellerId: string
│   ├── sellerName: string
│   ├── location: {country, region, city}
│   ├── createdAt: timestamp
│   ├── isActive: bool
│   ├── isFeatured: bool
│   ├── viewCount: number
│   └── categoryData: map       # category-specific fields
│       # For cars: {make, model, year, mileage, transmission, fuelType, ...}
│       # For properties: {type, bedrooms, bathrooms, area, furnishing, ...}
│       # For mobiles: {brand, model, storage, condition, ...}
│
├── chats/{chatId}
│   ├── participants: string[]
│   ├── listingId: string
│   ├── lastMessage: string
│   ├── lastMessageAt: timestamp
│   └── messages/{messageId}
│       ├── senderId: string
│       ├── text: string
│       ├── imageUrl: string?
│       └── createdAt: timestamp
│
└── favorites/{userId}/items/{listingId}
    └── addedAt: timestamp
```

---

## 7. Provider Pattern — ALWAYS USE THIS PATTERN

```dart
// Use Riverpod with code generation (@riverpod annotation)
// Every provider file follows this pattern:

part 'auth_provider.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => const AuthState.initial();

  Future<void> signIn({required String email, required String password}) async {
    state = const AuthState.loading();
    final result = await ref.read(authRepositoryProvider).signIn(email: email, password: password);
    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (user) => state = AuthState.success(user),
    );
  }
}

// State with Freezed
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.success(UserEntity user) = _Success;
  const factory AuthState.error(String message) = _Error;
}
```

---

## 8. Screen Template — EVERY SCREEN MUST FOLLOW THIS

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

class ExampleScreen extends ConsumerWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Title', style: AppTextStyles.heading3),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            children: [
              // content here
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 9. GoRouter Setup — Route Names

```dart
// core/router/route_names.dart
class RouteNames {
  static const splash         = '/';
  static const onboarding     = '/onboarding';
  static const signIn         = '/sign-in';
  static const signUp         = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const otp            = '/otp';
  static const phoneLogin     = '/phone-login';
  static const home           = '/home';
  static const carDetail      = '/car-detail/:id';
  static const propertyDetail = '/property-detail/:id';
  static const mobileDetail   = '/mobile-detail/:id';
  static const searchResults  = '/search/:query';
  static const filter         = '/filter/:category';
  static const chat           = '/chat/:chatId';
  static const chats          = '/chats';
  static const sell           = '/sell';
  static const postAd         = '/post-ad/:category';
  static const myAds          = '/my-ads';
  static const favorites      = '/favorites';
  static const profile        = '/profile';
  static const notifications  = '/notifications';
  static const accountSettings = '/account-settings';
}
```

---

## 10. AppButton Widget — ALWAYS USE, NEVER CREATE NEW BUTTONS

```dart
// core/widgets/app_button.dart
enum AppButtonType { primary, secondary, outline, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppButtonType type;
  final bool isLoading;
  final bool fullWidth;
  final Widget? prefixIcon;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    // primary: green background, white text
    // secondary: grey background, black text
    // outline: green border, green text
    // text: no border, green text
  }
}
```

---

## 11. Category-Specific Rules

Each category has its own filter model. NEVER mix category fields:

**Cars:** make, model, year, mileage, transmission (automatic/manual), fuelType, bodyType, color, regionalSpecs, condition, sellerType, price, region, city

**Properties:** propertyType (apartment/villa/land), purpose (rent/sale), bedrooms, bathrooms, area (sqft), furnishing, amenities, listedBy (owner/agent), rentPeriod, region, city

**Mobiles:** brand, model, storage, ram, condition (new/used/refurbished), screenSize, color, warranty, damageDetails, region

**Electronics:** brand, category (TV/Fridge/AC/etc), condition, warranty, region

**Furniture:** type, brand, condition, color, material, roomType, region

**Jobs:** title, company, jobType (full-time/part-time/freelance), experience, salary, industry, region

**Classifieds:** subcategory, condition, region

---

## 12. Firebase Security Rules Philosophy

- Users can only edit their own listings and profile
- Anyone can read active listings
- Chat messages only readable by participants
- Favorites only readable/writable by owner
- Admin collection protected

---

## 13. Image Handling Rules

- Always use `cached_network_image` for network images — NEVER `Image.network`
- Always show placeholder while loading
- Compress images before upload (max 1MB)
- Store in Firebase Storage: `listings/{listingId}/{imageIndex}.jpg`
- Max 10 images per listing

---

## 14. Error Handling — ALWAYS DO THIS

```dart
// Use Either<Failure, Success> pattern in repositories
// NEVER throw exceptions from repository layer — return Failure instead
// Show SnackBar for user-facing errors — NEVER print or ignore

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(errorMessage, style: AppTextStyles.body.copyWith(color: AppColors.white)),
    backgroundColor: AppColors.error,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
  ),
);
```

---

## 15. DO NOT — Hard Rules

- ❌ NEVER hardcode colors — always use `AppColors`
- ❌ NEVER hardcode text styles — always use `AppTextStyles`
- ❌ NEVER hardcode spacing numbers — always use `AppDimensions`
- ❌ NEVER use `setState` in a screen that needs shared state — use Riverpod
- ❌ NEVER put business logic inside widgets/screens — it goes in providers
- ❌ NEVER put Firestore/Firebase calls directly in screens — goes in repository
- ❌ NEVER create a new Button widget — use `AppButton`
- ❌ NEVER use `Image.network` — use `CachedNetworkImage`
- ❌ NEVER ignore errors silently
- ❌ NEVER create files outside the defined folder structure

---

## 16. Vibe Coding Prompt Template

When asking AI to build a screen, ALWAYS use this prompt format:

```
Build [ScreenName] screen for Afghan Deals Pro Flutter app.

Follow CURSOR_RULES.md strictly:
- Use AppColors, AppTextStyles, AppDimensions from core/theme/
- Use ConsumerWidget with Riverpod
- Provider in features/[feature]/presentation/providers/
- Screen in features/[feature]/presentation/screens/
- Use AppButton for all buttons, AppTextField for inputs
- Use GoRouter for navigation

Screen design: [paste Figma node ID or describe the screen]

The screen should include: [describe functionality]
```
