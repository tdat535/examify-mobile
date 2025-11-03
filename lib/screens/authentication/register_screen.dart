// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../../api/auth.dart'; // Giả sử AuthAPI.register tồn tại
import '../../utils/handleFacebookLogin.dart';
import '../../utils/handleGoogleLogin.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Đặt _selectedRole là null ban đầu để hiển thị bước 1
  String? _selectedRole;

  Future<void> _handleRegister() async {
    // Đảm bảo vai trò đã được chọn
    if (_selectedRole == null) {
      _showError('Vui lòng chọn vai trò của bạn');
      return;
    }
    if (_name.text.isEmpty ||
        _email.text.isEmpty ||
        _pass.text.isEmpty ||
        _confirm.text.isEmpty) {
      _showError('Vui lòng nhập đầy đủ thông tin');
      return;
    }
    if (_pass.text != _confirm.text) {
      _showError('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await AuthAPI.register(
        _name.text,
        _pass.text,
        _email.text,
        _selectedRole!, // Gửi vai trò đã chọn (giờ không thể null)
      );

      if (res['status'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng ký thành công!')),
          );
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
      } else {
        _showError(res['message'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // Hàm để quay lại Bước 1
  void _resetRoleSelection() {
    setState(() {
      _selectedRole = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8), // Màu nền tổng thể
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () {
            // Nếu đang ở Bước 2, quay lại Bước 1
            if (_selectedRole != null) {
              _resetRoleSelection();
            } else {
              // Nếu đang ở Bước 1, quay lại Login
              Navigator.pushReplacementNamed(context, LoginScreen.routeName);
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Text(
                  "Đã có tài khoản?",
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                        context, LoginScreen.routeName);
                  },
                  child: const Text(
                    'Đăng nhập',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Hiển thị tên thương hiệu (Jobsly) hoặc tiêu đề (Đăng ký)
              // Dựa trên trạng thái
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 20),
                    child: child,
                  ),
                ),
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
                      child: const Icon(Icons.person_add_alt_1_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF7B61FF), Color(0xFFD083FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        _selectedRole == null ? 'Tham gia' : 'Tạo tài khoản',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Logic hiển thị 2 bước
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedRole == null
                    ? _buildStep1RoleSelection() // Bước 1: Chọn vai trò
                    : _buildStep2RegisterForm(), // Bước 2: Điền form
              ),

              const SizedBox(height: 20),
              // Ẩn đăng nhập MXH ở Bước 1
              if (_selectedRole != null) _buildSocialLoginOptions(),
            ],
          ),
        ),
      ),
    );
  }

  // Bước 1: Widget chọn vai trò lớn (giống image_9f8697.png)
  Widget _buildStep1RoleSelection() {
    return Container(
      key: const ValueKey('Step1'),
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
        children: [
          const Text(
            'Đăng ký',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              _buildLargeRoleChoice(
                title: 'Tôi là học sinh',
                icon: Icons.school_outlined,
                role: '3',
              ),
              const SizedBox(width: 20),
              _buildLargeRoleChoice(
                title: 'Tôi là giáo viên',
                icon: Icons.work_outline,
                role: '2',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeRoleChoice(
      {required String title, required IconData icon, required String role}) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: role == '2'
                  ? [const Color(0xFF7B61FF).withOpacity(0.05), Colors.white]
                  : [const Color(0xFFD083FF).withOpacity(0.05), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, size: 50, color: const Color(0xFF7B61FF)),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Bước 2: Widget form đăng ký (giống image_9f86b4.png)
  Widget _buildStep2RegisterForm() {
    return Container(
      key: const ValueKey('Step2'),
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
          // Bộ chọn vai trò kiểu Tab (giống image_9f86b4.png)
          _buildRoleTabSelector(),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _name,
            hintText: 'Tên tài khoản',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _email,
            hintText: 'Email',
            prefixIcon: Icons.email_outlined,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _pass,
            hintText: 'Mật khẩu',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _confirm,
            hintText: 'Xác minh mật khẩu',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 20),
          // Nút Gradient
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B61FF), Color(0xFFD083FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
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
                          'Đăng ký',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper cho bộ chọn vai trò kiểu Tab (Bước 2)
  Widget _buildRoleTabSelector() {
    return Row(
      children: [
        _buildRoleTabChoice(
          title: 'Học sinh',
          icon: Icons.school_outlined,
          role: '3',
        ),
        _buildRoleTabChoice(
          title: 'Giáo viên',
          icon: Icons.work_outline,
          role: '2',
        ),
      ],
    );
  }

  // Widget helper cho từng Tab
  Widget _buildRoleTabChoice(
      {required String title, required IconData icon, required String role}) {
    final bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    isSelected ? const Color(0xFF7B61FF) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF7B61FF) : Colors.black54,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF7B61FF) : Colors.black54,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper cho Text Field (Giống hệt Login Screen)
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

  // Widget helper cho Social Login (Giống hệt Login Screen)
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
                child: Text('Hoặc đăng ký với',
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
              handleGoogleLogin(context, _selectedRole);
            }),
            const SizedBox(width: 20),
            _buildSocialButton('Facebook', 'assets/facebook_logo.png', () {
              handleFacebookLogin(_selectedRole);
            }),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Widget helper cho Social Button (Giống hệt Login Screen)
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
