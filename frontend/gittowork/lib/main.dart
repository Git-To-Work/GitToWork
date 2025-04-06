import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
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

// GlobalKey for ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

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
    payload: message.data['alertType'], // alertType으로 구분 가능
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
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // 로컬 알림 클릭 시 처리 (선택사항)
      final alertType = response.payload;
      if (alertType != null) {
        debugPrint('알림 클릭됨, alertType: $alertType');
        // 여기서 화면 이동 처리 가능
      }
    },
  );

  // FCM 포그라운드 메시지 수신 리스너 설정
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('포그라운드 메시지 수신: ${message.messageId}');
    _showForegroundNotification(message);
  });

  debugPrint('JWT 토큰: $token');
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
      child: MyApp(initialToken: token),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? initialToken;
  const MyApp({super.key, this.initialToken});

  @override
  Widget build(BuildContext context) {
    // 빌드가 완료된 후에 토큰 설정하도록 예약 (여기서는 async gap 없이 사용)
    if (initialToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<AuthProvider>(context, listen: false)
            .setAccessToken(initialToken!);
      });
    }
    return MaterialApp(
      title: 'Git To Work',
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Pretendard',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w500),
          displayMedium: TextStyle(fontWeight: FontWeight.w500),
          displaySmall: TextStyle(fontWeight: FontWeight.w500),
          headlineLarge: TextStyle(fontWeight: FontWeight.w500),
          headlineMedium: TextStyle(fontWeight: FontWeight.w500),
          headlineSmall: TextStyle(fontWeight: FontWeight.w500),
          titleLarge: TextStyle(fontWeight: FontWeight.w500),
          titleMedium: TextStyle(fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(fontWeight: FontWeight.w500),
          bodySmall: TextStyle(fontWeight: FontWeight.w500),
          labelLarge: TextStyle(fontWeight: FontWeight.w500),
          labelMedium: TextStyle(fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontWeight: FontWeight.w500),
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
    // initState에서 Provider를 읽어 저장
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // 2초 스플래시 대기
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // accessToken 존재 여부에 따라 화면 이동
    if (_authProvider.accessToken != null) {
      final success = await _authProvider.autoLoginWithToken();
      if (!mounted) return;

      if (success) {
        try {
          await _authProvider.fetchUserProfile();
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
