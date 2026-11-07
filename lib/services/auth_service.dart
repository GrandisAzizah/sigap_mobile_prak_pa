import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _sb = Supabase.instance.client;

  User? get currentUser => _sb.auth.currentUser;
  Session? get currentSession => _sb.auth.currentSession;

  /// Login pakai NIM. NIM dicari dulu email-nya lewat RPC,
  /// lalu login dengan email + password.
  Future<AuthResponse> loginWithNim({
    required String nim,
    required String password,
  }) async {
    final email =
        await _sb.rpc('email_by_nim', params: {'p_nim': nim}) as String?;

    if (email == null || email.isEmpty) {
      throw const AuthException('NIM tidak terdaftar.');
    }

    return _sb.auth.signInWithPassword(email: email, password: password);
  }

  /// Register user baru. nim & name masuk ke metadata,
  /// lalu trigger mengisi tabel public.users.
  Future<AuthResponse> register({
    required String nim,
    required String name,
    required String email,
    required String password,
  }) async {
    return _sb.auth.signUp(
      email: email,
      password: password,
      data: {'nim': nim, 'name': name},
    );
  }
  
  /// Ambil nama pengguna yang sedang login dari tabel users.
  Future<String> getCurrentUserName() async {
    final uid = currentUser?.id;

    if (uid == null) return 'Pengguna';

    try {
      final row = await _sb
          .from('users')
          .select('name')
          .eq('id', uid)
          .maybeSingle();

      final name = row?['name'] as String?;

      if (name != null && name.trim().isNotEmpty) {
        return name.trim();
      }

      // Fallback jika nama belum tersedia di tabel users.
      final metadataName = currentUser?.userMetadata?['name'] as String?;

      return metadataName?.trim().isNotEmpty == true
          ? metadataName!.trim()
          : 'Pengguna';
    } catch (e) {
      debugPrint('Gagal mengambil nama pengguna: $e');
      return 'Pengguna';
    }
  }

  Future<void> logout() => _sb.auth.signOut();

  Future<void> forgotPassword(String email) =>
      _sb.auth.resetPasswordForEmail(email);

  /// Ambil role user dari public.users.
  /// Return 'user' kalau tidak ketemu (fail-safe).
  Future<String> getRole() async {
    final uid = currentUser?.id;
    if (uid == null) return 'guest';
    try {
      final row = await _sb
          .from('users')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      return (row?['role'] as String?) ?? 'user';
    } catch (_) {
      return 'user';
    }
  }
}
