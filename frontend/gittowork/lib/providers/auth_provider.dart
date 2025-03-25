import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/api_service.dart';
import '../profile/user_profile.dart';

class AuthProvider with ChangeNotifier {
  String? _accessToken;
  UserProfile? _userProfile;
  SignInResponse? signInResponse;
  final ApiService _apiService = ApiService();

  String? get accessToken => _accessToken;
  UserProfile? get userProfile => _userProfile;

  void setAccessToken(String? token) {
    _accessToken = token;
    notifyListeners();
  }

  void logout() {
    _accessToken = null;
    _userProfile = null;
    notifyListeners();
  }

  /// GitHub OAuth 로그인 플로우 (WebView 사용)
  Future<SignInResponse?> loginWithGitHub(BuildContext context) async {
    final clientId = dotenv.env['GITHUB_CLIENT_ID'] ?? '';
    final redirectUrl = 'gittowork://callback';
    final authUrl =
        'https://github.com/login/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUrl&scope=read:user%20user:email';

    String? code;

    // WebView를 열고 인증 코드를 추출
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewPage(
          initialUrl: authUrl,
          onCodeReceived: (receivedCode) {
            debugPrint('Received code in loginWithGitHub: $receivedCode');
            code = receivedCode;
          },
        ),
      ),
    );
    debugPrint('Final code after WebView: $code');
    if (code == null) {
      debugPrint('인증 코드가 null입니다.');
      return null;
    }

    try {
      final response = await _apiService.signInWithGitHub(code!);
      signInResponse = response;
      _accessToken = response.accessToken;
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('GitHub 로그인 에러: $e');
      return null;
    }
  }

  /// 사용자 프로필 조회
  Future<void> fetchUserProfile() async {
    if (_accessToken == null) return;
    try {
      final profile = await _apiService.fetchUserProfile(_accessToken!);
      _userProfile = profile;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}

/// WebView 페이지를 위한 별도 위젯
class WebViewPage extends StatefulWidget {
  final String initialUrl;
  final Function(String) onCodeReceived;

  const WebViewPage({
    required this.initialUrl,
    required this.onCodeReceived,
    Key? key,
  }) : super(key: key);

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Page started: $url');
            _handleRedirect(url);
          },
          onPageFinished: (String url) {
            debugPrint('Page finished: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView 에러: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  void _handleRedirect(String url) {
    final uri = Uri.parse(url);
    if (uri.scheme == 'gittowork' && uri.host == 'callback') {
      final code = uri.queryParameters['code'];
      if (code != null) {
        widget.onCodeReceived(code);
        Navigator.pop(context); // WebView 닫기
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GitHub Login')),
      body: WebViewWidget(controller: _controller),
    );
  }
}