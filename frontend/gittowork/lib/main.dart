import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Provider
import 'package:provider/provider.dart';
import 'package:gittowork/providers/auth_provider.dart';
import 'package:gittowork/providers/github_analysis_provider.dart';
import 'package:gittowork/providers/quiz_provider.dart';
import 'package:gittowork/providers/company_provider.dart';
import 'package:gittowork/providers/company_detail_provider.dart';
import 'package:gittowork/providers/search_provider.dart';
import 'package:gittowork/providers/lucky_provider.dart';

// 레이아웃 파일 (스플래시로 쓸 화면)
import 'layouts/no_appbar_no_bottom_nav_layout.dart';
// 온보딩 화면 (3초 후 이동)
import 'screens/onboarding/onboarding.dart';
// 홈 화면 (자동 로그인 후 이동할 화면)
import 'layouts/appbar_bottom_nav_layout.dart';

import 'package:gittowork/services/company_api.dart';

// GlobalKey for ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('백그라운드 메시지 수신: ${message.messageId}');
}

// 포그라운드 메시지 핸들러
Future<void> _showForegroundNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'analysis_complete_channel',
    '분석 완료 알림',
    channelDescription: 'Github 및 자기소개서 분석 완료 알림',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@drawable/ic_stat_gittowork_default', // 앱 아이콘 사용
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title ?? '알림',
    message.notification?.body ?? '알림 내용을 확인하세요.',
    notificationDetails,
    payload: message.data.containsKey('selectedRepositoryId')
        ? 'GithubAnalysis:${message.data['selectedRepositoryId']}'
        : 'CoverLetterAnalysis',
  );
}

//AppBarBottomNavLayout으로 이동하는 함수
void _navigateToLayout({required int index}) {
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => AppBarBottomNavLayoutWithIndex(initialIndex: index),
    ),
        (route) => false,
  );
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final storage = FlutterSecureStorage();
  final token = await storage.read(key: 'jwt_token'); // 저장된 JWT 토큰 읽어오기

  // Firebase 초기화
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // FCM 권한 요청 (안드로이드 13 이상)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // flutter_local_notifications 초기화 (안드로이드 설정)
  const AndroidInitializationSettings androidInitSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
  InitializationSettings(android: androidInitSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      final payload = response.payload;
      debugPrint("🔔 [로컬 알림 클릭] payload: $payload");

      if (payload == null) return;

      if (payload.startsWith("GithubAnalysis:")) {
        final repoId = payload.split(":")[1];
        debugPrint("📦 저장할 repoId: $repoId");

        const storage = FlutterSecureStorage();
        await storage.write(key: 'selected_repo_id', value: repoId);

        _navigateToLayout(index: 0); // GitHubScreen
      } else if (payload == "CoverLetterAnalysis") {
        _navigateToLayout(index: 2); // CoverLetterScreen
      }
    },
  );

  // FCM 포그라운드 메시지 수신 리스너 설정
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('📬 [Foreground] FCM 메시지 수신');
    debugPrint('▶ Title: ${message.notification?.title}');
    debugPrint('▶ Body: ${message.notification?.body}');
    debugPrint('▶ selectedRepositoryId: ${message.data['selectedRepositoryId']}');

    // 🔄 Github 분석일 경우 자동 새로고침
    if (message.data.containsKey('selectedRepositoryId')) {
      _navigateToLayout(index: 0);
    }

    _showForegroundNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    debugPrint("📬 [백그라운드 알림 클릭]");
    debugPrint("▶ data: ${message.data}");

    final repoId = message.data['selectedRepositoryId'];
    if (repoId != null) {
      debugPrint("📥 Github 분석 repoId: $repoId");
      const storage = FlutterSecureStorage();
      await storage.write(key: 'selected_repo_id', value: repoId);
      debugPrint("➡ GitHubScreen으로 이동 및 새로고침");
      _navigateToLayout(index: 0); // 화면 전환 후 initState에서 자동 갱신
    } else {
      debugPrint("📝 CoverLetter 분석 알림으로 인식");
      _navigateToLayout(index: 2);
    }
  });


  debugPrint('JWT 토큰: $token');

  RemoteMessage? initialFcmMessage = await FirebaseMessaging.instance.getInitialMessage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GitHubAnalysisProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => CompanyProvider()),
        ChangeNotifierProvider(create: (_) => CompanyDetailProvider()),
        ChangeNotifierProvider(create: (_) => SearchFilterProvider()),
        ChangeNotifierProvider(create: (_) => LuckyProvider()),
      ],
      child: MyApp(
          initialToken: token,
          initialFcmMessage: initialFcmMessage,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final String? initialToken;
  final RemoteMessage? initialFcmMessage;

  const MyApp({super.key, this.initialToken, this.initialFcmMessage});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.initialToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<AuthProvider>(context, listen: false)
            .setAccessToken(widget.initialToken!);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  DateTime? _lastRequestTime;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
      // 3분 제한 체크
      final now = DateTime.now();
      if (_lastRequestTime == null || now.difference(_lastRequestTime!).inMinutes >= 3) {
        _lastRequestTime = now;
        try {
          debugPrint("🛑 앱 종료되어도 requestAction 실행됨.");
          await CompanyApi.requestAction();
        } catch (e) {
          debugPrint("❌ requestAction 에러: $e");
        }
      } else {
        debugPrint("⏱ 3분 내 요청 제한으로 requestAction 실행하지 않음.");
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Git To Work',
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Pretendard',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (_authProvider.accessToken != null) {
      final success = await _authProvider.autoLoginWithToken();
      if (!mounted) return;

      if (success) {
        try {
          await _authProvider.fetchUserProfile();

          final message = (context.findAncestorWidgetOfExactType<MyApp>() as MyApp).initialFcmMessage;

          if (message != null) {
            debugPrint("🚀 [getInitialMessage] 수신");
            final repoId = message.data['selectedRepositoryId'];
            debugPrint("▶ repoId: $repoId");

            if (repoId != null) {
              const storage = FlutterSecureStorage();
              await storage.write(key: 'selected_repo_id', value: repoId);
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => AppBarBottomNavLayoutWithIndex(initialIndex: 0),
                ),
                    (route) => false,
              );
            } else {
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => AppBarBottomNavLayoutWithIndex(initialIndex: 2),
                ),
                    (route) => false,
              );
            }
          }

          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AppBarBottomNavLayout()),
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("로그인에 실패했습니다.")),
            );
          }
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        }
      } else {
        _authProvider.logout();
        final storage = FlutterSecureStorage();
        await storage.delete(key: 'jwt_token');
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } else {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const NoAppBarNoBottomNavLayout();
  }
}
