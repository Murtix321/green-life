import 'package:google_sign_in/google_sign_in.dart';

class AuthUser {
  final String name;
  final String email;
  final String? photoUrl;
  const AuthUser(this.name, this.email, this.photoUrl);
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Google ile giriş. Kurulum adımları README.md içinde.
class AuthService {
  static final GoogleSignIn _google = GoogleSignIn(scopes: const ['email', 'profile']);

  static Future<AuthUser> signInWithGoogle() async {
    try {
      final acc = await _google.signIn();
      if (acc == null) throw AuthException('Giriş iptal edildi.');
      return AuthUser(
        (acc.displayName ?? '').trim().isEmpty ? acc.email.split('@').first : acc.displayName!,
        acc.email,
        acc.photoUrl,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'Google girişi henüz yapılandırılmamış görünüyor. README\'deki "Google ile giriş" adımlarını tamamla. ($e)',
      );
    }
  }

  static Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {}
  }
}
