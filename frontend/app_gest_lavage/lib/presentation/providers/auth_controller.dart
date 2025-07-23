import 'package:app_gest_lavage/core/utils/navigator.dart';
import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:app_gest_lavage/data/services/base_service.dart';
import 'package:app_gest_lavage/data/services/client_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends ChangeNotifier {
  static AuthController? _instance;

  AuthController._();

  factory AuthController() {
    _instance ??= AuthController._();
    return _instance!;
  }

  final clientSp = Supabase.instance.client;

  BaseService? _service;
  AuthModel? _user;

  BaseService get service => _service!;

  AuthModel get user => _user!;
  Client get client => user as Client;
  Admin get admin => user as Admin;
  String get currentRole => user.currentRole.id;
  bool loading = true;
  String? error;

  Future<void> redirect() async {
    try {
      final response = await clientSp.auth.getUser();

      if (response.user == null) {
        return AppNavigator.pushReplacement('/login');
      }

      // final role = response.user!.userMetadata!['roles'][0];

      _service = ClientService();

      await getUserAndPushToHome();
    } catch (e) {
      return AppNavigator.pushReplacement('/login');
    }
  }

  Future<void> getUserAndPushToHome() async {
    await getUser();

    if (_user != null) {
      pushToHome();
    }
  }

  Future<void> getUser() async {
    try {
      loading = true;
      notifyListeners();

      final response = await service.getUser();

      if (response == null) {
        throw 'User doesn\'t exist';
      }

      _user = response;

      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      error = e.toString();
      notifyListeners();
    }
  }

  void pushToHome() {
    AppNavigator.pushReplacement('/home');
  }
}