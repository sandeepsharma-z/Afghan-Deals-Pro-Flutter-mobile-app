import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/phone_login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/email_login_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/chat/presentation/screens/chats_screen.dart';
import '../../features/chat/presentation/screens/chat_detail_screen.dart';
import '../../features/chat/data/models/chat_thread_model.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/account_screen.dart';
import '../../features/profile/presentation/screens/favorites_screen.dart';
import '../../features/profile/presentation/screens/notifications_screen.dart';
import '../../features/categories/cars/presentation/screens/cars_screen.dart';
import '../../features/categories/properties/presentation/screens/properties_screen.dart';
import '../../features/categories/mobiles/presentation/screens/mobiles_screen.dart';
import '../../features/categories/spare_parts/presentation/screens/spare_parts_screen.dart';
import '../../features/categories/electronics/presentation/screens/electronics_screen.dart';
import '../../features/categories/furniture/presentation/screens/furniture_screen.dart';
import '../../features/categories/jobs/presentation/screens/jobs_screen.dart';
import '../../features/categories/classifieds/presentation/screens/classifieds_screen.dart';
import '../../features/sell/presentation/screens/sell_screen.dart';
import '../../features/sell/presentation/screens/post_ad_screen.dart';
import '../../features/sell/presentation/screens/post_mobile_screen.dart';
import '../../features/sell/presentation/screens/post_car_screen.dart';
import '../../features/sell/presentation/screens/post_property_screen.dart';
import '../../features/admin/presentation/screens/admin_chats_screen.dart';
import '../../features/admin/presentation/screens/admin_classifieds_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_filter_options_screen.dart';
import '../../features/admin/presentation/screens/admin_regions_screen.dart';
import '../../features/admin/presentation/screens/admin_price_settings_screen.dart';
import '../../features/profile/presentation/screens/my_ads_screen.dart';
import 'route_names.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      // Use Supabase directly — avoids GoRouter rebuild on auth change
      final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
      final location = state.matchedLocation;

      // Splash always shows first
      if (location == RouteNames.splash) return null;

      // If logged in and on auth screens, go to home
      final isOnAuthRoute = location == RouteNames.onboarding ||
          location == RouteNames.phoneLogin ||
          location.startsWith('/otp') ||
          location == RouteNames.emailLogin;

      if (isAuthenticated && isOnAuthRoute) return RouteNames.home;

      // Protected routes — login required
      final isProtectedRoute = location == RouteNames.sell ||
          location == RouteNames.chats ||
          location.startsWith('/chat') ||
          location == RouteNames.myAds ||
          location == RouteNames.favorites ||
          location == RouteNames.profile ||
          location == RouteNames.account ||
          location == RouteNames.accountSettings ||
          location == RouteNames.notifications ||
          location.startsWith('/post-ad') ||
          location == RouteNames.postMobile ||
          location == RouteNames.postCar ||
          location == RouteNames.postProperty;

      if (!isAuthenticated && isProtectedRoute) return RouteNames.onboarding;

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.phoneLogin,
        builder: (context, state) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: '/otp/:phone',
        builder: (context, state) {
          final phone = state.pathParameters['phone'] ?? '';
          return OtpScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/otp-email/:email',
        builder: (context, state) {
          final email =
              Uri.decodeComponent(state.pathParameters['email'] ?? '');
          return OtpScreen(email: email);
        },
      ),
      GoRoute(
        path: RouteNames.emailLogin,
        builder: (context, state) => const EmailLoginScreen(),
      ),
      GoRoute(
        path: RouteNames.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: RouteNames.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.chats,
        builder: (context, state) => const ChatsScreen(),
      ),
      GoRoute(
        path: RouteNames.chat,
        builder: (context, state) {
          final chatId = state.pathParameters['chatId'] ?? '';
          final initialThread = state.extra is ChatThreadModel
              ? state.extra as ChatThreadModel
              : null;
          return ChatDetailScreen(
            chatId: chatId,
            initialThread: initialThread,
          );
        },
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.account,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: RouteNames.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.cars,
        builder: (context, state) => const CarsScreen(),
      ),
      GoRoute(
        path: RouteNames.properties,
        builder: (context, state) => const PropertiesScreen(),
      ),
      GoRoute(
        path: RouteNames.mobiles,
        builder: (context, state) => const MobilesScreen(),
      ),
      GoRoute(
        path: RouteNames.spareParts,
        builder: (context, state) => const SparePartsScreen(),
      ),
      GoRoute(
        path: RouteNames.electronics,
        builder: (context, state) => const ElectronicsScreen(),
      ),
      GoRoute(
        path: RouteNames.furniture,
        builder: (context, state) => const FurnitureScreen(),
      ),
      GoRoute(
        path: RouteNames.jobs,
        builder: (context, state) => const JobsScreen(),
      ),
      GoRoute(
        path: RouteNames.classifieds,
        builder: (context, state) => const ClassifiedsScreen(),
      ),
      GoRoute(
        path: RouteNames.sell,
        builder: (context, state) => const SellScreen(),
      ),
      GoRoute(
        path: '/post-ad/:category',
        builder: (context, state) {
          final category = state.pathParameters['category'] ?? 'classifieds';
          return PostAdScreen(category: category);
        },
      ),
      GoRoute(
        path: RouteNames.postMobile,
        builder: (context, state) => const PostMobileScreen(),
      ),
      GoRoute(
        path: RouteNames.postCar,
        builder: (context, state) => const PostCarScreen(),
      ),
      GoRoute(
        path: RouteNames.postProperty,
        builder: (context, state) => const PostPropertyScreen(),
      ),
      GoRoute(
        path: RouteNames.adminChats,
        builder: (context, state) => const AdminChatsScreen(),
      ),
      GoRoute(
        path: RouteNames.adminClassifieds,
        builder: (context, state) => const AdminClassifiedsScreen(),
      ),
      GoRoute(
        path: RouteNames.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.adminFilterOptions,
        builder: (context, state) => const AdminFilterOptionsScreen(),
      ),
      GoRoute(
        path: RouteNames.adminRegions,
        builder: (context, state) => const AdminRegionsScreen(),
      ),
      GoRoute(
        path: RouteNames.adminPriceSettings,
        builder: (context, state) => const AdminPriceSettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.adminSubcategories,
        builder: (context, state) => const AdminClassifiedsScreen(),
      ),
      GoRoute(
        path: RouteNames.myAds,
        builder: (context, state) => const MyAdsScreen(),
      ),
    ],
  );
});
