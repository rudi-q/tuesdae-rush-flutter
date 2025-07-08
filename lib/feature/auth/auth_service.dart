import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Send OTP to email
  Future<void> sendOtp(String email) async {
    await Supabase.instance.client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
    );
  }

  // Verify OTP code
  Future<void> verifyOtp(String email, String token) async {
    await Supabase.instance.client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  // Check auth state
  bool get isAuthenticated => Supabase.instance.client.auth.currentUser != null;

  // Sign out
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}
