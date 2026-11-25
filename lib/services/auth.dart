import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthUser {
  final String name;
  final String email;
  final String? photoUrl;
  const AuthUser(this.name, this.email, this.photoUrl);
}

class AuthException implements Exception {
  final String message;
  final bool cancelled;
  AuthException(this.message, {this.cancelled = false});
  @override
  String toString() => message;
}

/// Google ile giriş (Firebase gerekmez). Google Cloud'da bu uygulamanın paket adı
/// (com.greenlife.green_life) ve imza parmak izi (SHA-1) ile bir "Android OAuth istemcisi"
/// kayıtlı olmalıdır. Ayrıntılar: README.md › Google ile giriş.
class AuthService {
  static final GoogleSignIn _google = GoogleSignIn(scopes: const ['email', 'profile']);

  static Future<AuthUser> signInWithGoogle() async {
    try {
      final acc = await _google.signIn();
      if (acc == null) throw AuthException('Giriş iptal edildi.', cancelled: true);
      final name = (acc.displayName ?? '').trim();
      return AuthUser(name.isEmpty ? acc.email.split('@').first : name, acc.email, acc.photoUrl);
    } on AuthException {
      rethrow;
    } on PlatformException catch (e) {
      throw AuthException(_explain(e));
    } catch (e) {
      throw AuthException('Google girişi başarısız oldu. ($e)');
    }
  }

  /// Google Play Hizmetleri hata kodlarını Türkçe ve anlaşılır hale getirir.
  static String _explain(PlatformException e) {
    final text = '${e.code} ${e.message ?? ''} ${e.details ?? ''}';
    if (e.code == 'sign_in_canceled' || text.contains('12501')) return 'Giriş iptal edildi.';
    if (e.code == 'network_error' || text.contains('ApiException: 7')) {
      return 'İnternet bağlantısı yok gibi görünüyor.';
    }
    if (text.contains('ApiException: 10') || text.contains('12500')) {
      return 'Google bu uygulamayı henüz tanımıyor. Google Cloud\'da uygulamanın SHA-1 parmak izi kayıtlı olmalı '
          '(README › Google ile giriş). Şimdilik "E-posta ile giriş" ile devam edebilirsin.';
    }
    return 'Google girişi başarısız oldu (${e.code}).';
  }

  static Future<void> signOut() async {
    try {
      await _google.signOut().timeout(const Duration(seconds: 5));
    } catch (_) {}
  }
}
