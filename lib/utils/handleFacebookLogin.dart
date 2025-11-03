import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../api/auth.dart';

Future<void> handleFacebookLogin([String? selectedRole]) async {
  try {
    final result = await FacebookAuth.instance.login(); // Login
    if (result.status == LoginStatus.success) {
      final userData = await FacebookAuth.instance.getUserData();
      final name = userData['name'] ?? 'User';
      final email = userData['email'] ?? '';
      final providerId = userData['id'];

      final res = await AuthAPI.socialLogin(
        name: name,
        email: email,
        provider: 'facebook',
        providerId: providerId,
        roleId: selectedRole,
      );

      print('Facebook login success: $res');
      // Lưu accessToken, refreshToken vào app storage
    } else {
      print('Facebook login canceled or failed');
    }
  } catch (e) {
    print('Facebook login error: $e');
  }
}
