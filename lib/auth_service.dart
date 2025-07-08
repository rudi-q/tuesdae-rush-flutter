import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Magic link authentication
  Future<void> signInWithMagicLink(String email) async {
    await Supabase.instance.client.auth.signInWithOtp(email: email);
  }

  // Check auth state
  bool get isAuthenticated => Supabase.instance.client.auth.currentUser != null;

  // Sign out
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}

