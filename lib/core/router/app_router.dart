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
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/account_screen.dart';
import '../../features/profile/presentation/screens/favorites_screen.dart';
import '../../features/profile/presentation/screens/notifications_screen.dart';
import '../../features/categories/cars/presentation/screens/cars_screen.dart';
import '../../features/sell/presentation/screens/sell_screen.dart';
import '../../features/sell/presentation/screens/post_ad_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
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
          location.startsWith('/post-ad');

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
          final email = Uri.decodeComponent(state.pathParameters['email'] ?? '');
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
    ],
  );
});
