import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'firebase_options.dart';

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
      final chatId = response.payload;
      if (chatId != null && chatId.isNotEmpty) {
        final ctx = appNavigatorKey.currentContext;
        if (ctx != null) {
          ctx.go('/chat/$chatId');
        }
      }
    },
  );
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_chatNotificationChannel);

  await Supabase.initialize(
    url: 'https://nxgniehrrcpqqymorjxq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im54Z25pZWhycmNwcXF5bW9yanhxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwODk5MDAsImV4cCI6MjA4OTY2NTkwMH0.F6r42k-M0OzbyjOrUA91Wyvi4gSru4uSgUckxaQxrkE',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

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
  if (chatId != null && chatId.isNotEmpty) {
    final ctx = appNavigatorKey.currentContext;
    if (ctx != null) {
      ctx.go('/chat/$chatId');
    }
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
  if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
    return;
  }

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
    payload: chatId.isEmpty ? null : chatId,
  );
}

class AfghanDealsPro extends ConsumerStatefulWidget {
  const AfghanDealsPro({super.key});

  @override
  ConsumerState<AfghanDealsPro> createState() => _AfghanDealsProState();
}

class _AfghanDealsProState extends ConsumerState<AfghanDealsPro>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupFcm();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        _saveFcmToken();
      }
      if (data.event == AuthChangeEvent.tokenRefreshed ||
          data.event == AuthChangeEvent.signedIn) {
        ref.invalidate(chatThreadsProvider);
      }
    });
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
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      final updated = await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', me.id)
          .select('id')
          .maybeSingle();

      if (updated == null) {
        final displayName =
            (me.userMetadata?['name']?.toString().trim().isNotEmpty ?? false)
                ? me.userMetadata!['name'].toString().trim()
                : (me.email?.split('@').first ?? 'User');
        await Supabase.instance.client.from('profiles').upsert({
          'id': me.id,
          'name': displayName,
          'email': me.email,
          'fcm_token': token,
        }, onConflict: 'id');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Afghan Deals Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
