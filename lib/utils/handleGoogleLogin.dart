import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../api/auth.dart';
import '../screens/teacher/dashboard_screen.dart';
import '../screens/student/student_screen.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  serverClientId:
      '1006892178317-ubr437h64t812bghvtn39b6ntneej78r.apps.googleusercontent.com',
);

Future<void> handleGoogleLogin(BuildContext context, [String? roleId]) async {
  try {
    // Đăng xuất trước để chọn lại tài khoản Google
    await _googleSignIn.signOut();

    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) return;

    final name = account.displayName ?? 'User';
    final email = account.email;
    final providerId = account.id;

    // Gọi API socialLogin mà KHÔNG gửi roleId
    final res = await AuthAPI.socialLogin(
      name: name,
      email: email,
      provider: 'google',
      providerId: providerId,
      roleId: roleId,
    );

    if (res['status'] == false &&
        (res['message']?.contains('role') ?? false)) {
      // Nếu backend báo thiếu role → chuyển sang màn hình chọn role
      Navigator.pushNamed(context, '/chooseRole', arguments: {
        'name': name,
        'email': email,
        'providerId': providerId,
        'provider': 'google',
      });
      return;
    }

    // Nếu thành công → lưu token & chuyển màn hình
    if (res['status'] == true && res['data'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', res['data']['accessToken']);
      await prefs.setString('refreshToken', res['data']['refreshToken']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập thành công!')),
      );

      // Điều hướng dựa theo role
      final decoded = JwtDecoder.decode(res['data']['accessToken']);
      final role = decoded['role'];
      if (role == 2) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (role == 3) {
        Navigator.pushReplacementNamed(context, '/student');
      } else {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  } catch (e, stack) {
    print('Google login error: $e');
    print(stack);
  }
}
