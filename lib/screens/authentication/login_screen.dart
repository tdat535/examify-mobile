// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../../api/auth.dart';
import '../../utils/handleFacebookLogin.dart';
import '../../utils/handleGoogleLogin.dart';
import '../../utils/token_storage.dart';
import '../teacher/dashboard_screen.dart';
import 'register_screen.dart';
import '../student/student_screen.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _pass = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_username.text.isEmpty || _pass.text.isEmpty) {
      _showError('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await AuthAPI.login(_username.text, _pass.text);

      if (res['status'] == true && res['data']?['accessToken'] != null) {
        final accessToken = res['data']['accessToken'];

        await TokenStorage.saveToken(accessToken);

        final decoded = JwtDecoder.decode(accessToken);
        final role = decoded['role'];

        if (role == 2) {
          Navigator.pushReplacementNamed(context, DashboardScreen.routeName);
        } else if (role == 3) {
          Navigator.pushReplacementNamed(context, StudentScreen.routeName);
        } else {
          _showError('Không xác định được vai trò người dùng.');
        }
      } else {
        _showError(res['message'] ?? 'Sai tên đăng nhập hoặc mật khẩu');
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Text(
                  "Chưa có tài khoản?",
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                        context, RegisterScreen.routeName);
                  },
                  child: const Text(
                    'Đăng ký',
                    style: TextStyle(
                        color: Color(0xFF7B61FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(seconds: 1),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * 20),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B61FF), Color(0xFFD083FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF7B61FF), Color(0xFFD083FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        'Examify',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _buildLoginCard(context),
              const SizedBox(height: 20),
              _buildSocialLoginOptions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _buildTextField(
            controller: _username,
            hintText: 'Tài khoản',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _pass,
            hintText: 'Mật khẩu',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                // 1. Xóa padding ở đây để Container bên trong lấp đầy
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                // 2. Xóa 'gradient' khỏi styleFrom
              ),
              child: Ink(
                // 3. Sử dụng Ink để có hiệu ứng splash
                decoration: BoxDecoration(
                  // 4. Áp dụng gradient và border radius ở đây
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B61FF), Color(0xFFD083FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  // 5. Container này để áp dụng padding
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Đăng nhập',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Quên mật khẩu?',
                style: TextStyle(color: Color(0xFF7B61FF), fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    IconData? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText ? _obscurePassword : false,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black45),
          prefixIcon: Icon(prefixIcon, color: Colors.black54),
          suffixIcon: obscureText
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.black54,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildSocialLoginOptions() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            children: [
              Expanded(child: Divider(color: Colors.black26)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('Hoặc đăng nhập với',
                    style: TextStyle(color: Colors.black54)),
              ),
              Expanded(child: Divider(color: Colors.black26)),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton('Google', 'assets/google_logo.png', () {
              handleGoogleLogin(context);
            }),
            const SizedBox(width: 20),
            _buildSocialButton('Facebook', 'assets/facebook_logo.png', () {
              handleFacebookLogin();
            }),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSocialButton(String text, String iconPath, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          side: const BorderSide(color: Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, height: 20), // Placeholder for social icons
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
