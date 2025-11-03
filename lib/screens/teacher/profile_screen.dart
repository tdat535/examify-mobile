// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../../api/auth.dart';
import '../../utils/token_storage.dart';
import '../../widgets/modern_appbar.dart';
import 'edit_profile.screen.dart';
import '../authentication/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? teacher;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
        return;
      }

      final data = await AuthAPI.getProfile(token); // API của bạn
      setState(() {
        teacher = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải thông tin giáo viên')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = teacher?['realName'] ?? teacher?['username'];
    final email = teacher?['email'] ?? 'chua_cap_nhat@example.com';
    final phone = teacher?['phone'] ?? 'Chưa cập nhật';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hồ sơ',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7B61FF), Color(0xFF00C2FF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty
                                  ? name.substring(0, 2).toUpperCase()
                                  : 'GV',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (() {
                                  final roleName = teacher?['role']?['name'];
                                  if (roleName == 'teacher') return 'Giáo viên';
                                  if (roleName == 'admin')
                                    return 'Quản trị viên';
                                  if (roleName == 'student') return 'Sinh viên';
                                  return 'Người dùng';
                                })(),
                                style: const TextStyle(
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(email),
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('Số điện thoại'),
                      subtitle: Text(phone),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(
                                realName: name,
                                email: email,
                                phone: phone,
                              ),
                            ),
                          );
                          if (updated == true) {
                            _loadProfile();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B61FF),
                        ),
                        child: const Text('Chỉnh sửa hồ sơ'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await TokenStorage.clear();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(
                                context, LoginScreen.routeName);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: const Text('Đăng xuất'),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
      ),
    );
  }
}
