import 'package:app_gest_lavage/data/models/auth_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class BaseService<T extends AuthModel> {
  final SupabaseClient client = Supabase.instance.client;

  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final auth = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return auth;
    } catch (e) {
      print("❌ signIn failed: $e");
      rethrow; // Re-throw to handle specific errors in the UI
    }
  }

  Future<AuthResponse?> signUp({
  required String name,
  required String email,
  required String password,
}) async {
  try {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
      },
    );
    return response;
  } catch (e) {
    print("❌ signUp failed: $e");
    rethrow;
  }
}



  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<T?> getUser();

  // Future<T?> getEmployer();
}