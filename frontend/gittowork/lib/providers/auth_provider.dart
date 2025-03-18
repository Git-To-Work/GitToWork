import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  String? _accessToken;

  String? get accessToken => _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
    notifyListeners();
  }

  void logout() {
    _accessToken = null;
    notifyListeners();
  }
}
