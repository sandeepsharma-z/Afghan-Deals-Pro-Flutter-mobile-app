import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import 'core/auth/app_auth.dart';
import 'core/router/app_router.dart';
import 'core/router/route_names.dart';
import 'core/localization/app_language_provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'firebase_options.dart';

const _supabaseUrl = 'https://cmebycscxjeudegsqzmx.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNtZWJ5Y3NjeGpldWRlZ3Nxem14Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxMzEzNDIsImV4cCI6MjA5MzcwNzM0Mn0.K0dMmJ7Oi2RV-YfTNaHGhsUFySD_PatUBo2k0iYRJuQ';

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

const AndroidNotificationChannel _chatNotificationChannel =
    AndroidNotificationChannel(
  'chat_messages',
  'Chat Messages',
  description: 'Notifications for incoming chat messages',
  importance: Importance.max,
  playSound: true,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );
  await _localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) {
      final route = response.payload;
      if (route != null && route.startsWith('/')) {
        final ctx = appNavigatorKey.currentContext;
        if (ctx != null) {
          ctx.go(route);
        }
      }
    },
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_chatNotificationChannel);

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  await AppAuth.initializeSupabaseForCurrentAuth();
  if (AppAuth.isFirebaseAuthenticated) {
    try {
      await AppAuth.ensureFirebaseProfileId(
        displayName: AppAuth.currentUserEntity?.name,
        email: AppAuth.currentUserEmail,
        phone: AppAuth.currentUserPhone,
      );
    } catch (_) {}
  }

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    _handleNotificationTap(initialMessage);
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  assert(() {
    debugPaintSizeEnabled = false;
    debugPaintBaselinesEnabled = false;
    debugPaintPointersEnabled = false;
    debugRepaintRainbowEnabled = false;
    return true;
  }());

  runApp(const ProviderScope(child: AfghanDealsPro()));
}

void _handleNotificationTap(RemoteMessage message) {
  final chatId = message.data['chat_id'] as String?;
  final actionUrl = message.data['action_url'] as String?;
  final type = message.data['type'] as String?;
  final targetRoute =
      actionUrl != null && actionUrl.startsWith('/') ? actionUrl : null;

  if (chatId != null && chatId.isNotEmpty) {
    final ctx = appNavigatorKey.currentContext;
    if (ctx != null) {
      ctx.go('/chat/$chatId');
    }
    return;
  }

  final ctx = appNavigatorKey.currentContext;
  if (ctx != null) {
    ctx.go(targetRoute ?? (type == 'message' ? RouteNames.chats : RouteNames.notifications));
  }
}

void _showForegroundSnack(RemoteMessage message) {
  final ctx = appNavigatorKey.currentContext;
  if (ctx == null) return;

  final title = message.notification?.title?.trim();
  final body = message.notification?.body?.trim();
  final text = [
    if (title != null && title.isNotEmpty) title,
    if (body != null && body.isNotEmpty) body,
  ].join('\n');

  if (text.isEmpty) return;

  final messenger = ScaffoldMessenger.maybeOf(ctx);
  messenger?.showSnackBar(
    SnackBar(
      content: Text(text),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Future<void> _showForegroundLocalNotification(RemoteMessage message) async {
  final title = message.notification?.title?.trim();
  final body = message.notification?.body?.trim();
  final chatId = message.data['chat_id']?.toString() ?? '';
  final actionUrl = message.data['action_url']?.toString() ?? '';
  final type = message.data['type']?.toString() ?? '';
  if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
    return;
  }

  final payload = chatId.isNotEmpty
      ? '/chat/$chatId'
      : actionUrl.startsWith('/')
          ? actionUrl
          : type == 'message'
              ? RouteNames.chats
              : RouteNames.notifications;

  await _localNotifications.show(
    message.hashCode,
    title ?? 'New message',
    body ?? '',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'Notifications for incoming chat messages',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: payload,
  );
}

class AfghanDealsPro extends ConsumerStatefulWidget {
  const AfghanDealsPro({super.key});

  @override
  ConsumerState<AfghanDealsPro> createState() => _AfghanDealsProState();
}

class _AfghanDealsProState extends ConsumerState<AfghanDealsPro>
    with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _supabaseAuthSub;
  StreamSubscription? _firebaseAuthSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupFcm();

    _firebaseAuthSub = AppAuth.firebase.authStateChanges().listen((user) {
      if (user != null) {
        _saveFcmToken();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.invalidate(chatThreadsProvider);
          }
        });
      }
    });

    if (!AppAuth.isFirebaseAuthenticated) {
      _supabaseAuthSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn ||
            data.event == AuthChangeEvent.tokenRefreshed) {
          _saveFcmToken();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.invalidate(chatThreadsProvider);
            }
          });
        }
      });
    }
  }

  Future<void> _setupFcm() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM permission denied by user.');
    }

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _saveFcmToken();

    messaging.onTokenRefresh.listen((_) => _saveFcmToken());

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    FirebaseMessaging.onMessage.listen((message) async {
      await _showForegroundLocalNotification(message);
      _showForegroundSnack(message);
    });
  }

  Future<void> _saveFcmToken() async {
    if (AppAuth.isFirebaseAuthenticated) {
      await AppAuth.ensureFirebaseProfileId(
        displayName: AppAuth.currentUserEntity?.name,
        email: AppAuth.currentUserEmail,
        phone: AppAuth.currentUserPhone,
      );
    }

    final me = AppAuth.currentUserEntity;
    if (me == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      final lookupValue = AppAuth.currentProfileLookupValue;
      if (lookupValue == null) return;
      final updated = await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq(AppAuth.profileLookupColumn, lookupValue)
          .select('id')
          .maybeSingle();

      if (updated == null) {
        final displayName = me.name?.trim().isNotEmpty == true
            ? me.name!.trim()
                : (me.email?.split('@').first ?? me.phone ?? 'User');
        await Supabase.instance.client.from('profiles').upsert({
          if (AppAuth.isFirebaseAuthenticated) 'firebase_uid': AppAuth.currentAuthUid,
          if (!AppAuth.isFirebaseAuthenticated) 'id': me.id,
          'name': displayName,
          'email': me.email,
          'phone': me.phone,
          'is_verified': me.isVerified,
          'fcm_token': token,
        }, onConflict: AppAuth.profileLookupColumn);
      }
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _saveFcmToken();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _supabaseAuthSub?.cancel();
    _firebaseAuthSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(appLanguageProvider);

    return MaterialApp.router(
      title: 'Afghan Deals Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}
