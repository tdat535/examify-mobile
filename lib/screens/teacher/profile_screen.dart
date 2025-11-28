// lib/screens/teacher/TeacherProfileScreen.dart
import 'package:flutter/material.dart';
import '../../api/auth.dart';
import '../../utils/token_storage.dart';
import '../authentication/login_screen.dart';
import '../student/EditProfileScreen.dart';

class TeacherProfileScreen extends StatefulWidget {
  static const routeName = '/profile-teacher';
  final String token;

  const TeacherProfileScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _teacher;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await AuthAPI.getProfile(widget.token);
      setState(() {
        _teacher = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông tin: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _teacher?['realName'] ?? _teacher?['username'] ?? 'Giáo viên';
    final email = _teacher?['email'] ?? 'chua_cap_nhat@example.com';
    final phone = _teacher?['phone'] ?? 'Chưa cập nhật';

    return Scaffold(
        appBar: AppBar(
          title: const Text('Hồ sơ'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(name, email),
                      const SizedBox(height: 24),
                      _buildInfoCard(name, email, phone),
                      const SizedBox(height: 8),
                      _buildMenuSection(),
                    ],
                  ),
                ),
              ));
  }

  Widget _buildHeader(String name, String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Text(
                  _getInitials(name),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.camera_alt,
                        size: 16, color: Colors.blue.shade700),
                    onPressed: () {
                      // TODO: Upload avatar
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String name, String email, String phone) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16), // ← thêm margin
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin cá nhân',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.person, 'Họ tên', name),
              const Divider(),
              _buildInfoRow(Icons.email, 'Email', email),
              const Divider(),
              _buildInfoRow(Icons.phone, 'Số điện thoại', phone),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: Colors.grey.shade600),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    token: widget.token,
                    realName: _teacher?['realName'],
                    email: _teacher?['email'],
                    phone: _teacher?['phone'],
                  ),
                ),
              );
              if (updated != null) _loadProfile(); // reload after edit
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Card(
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.edit,
                  title: 'Chỉnh sửa hồ sơ',
                  onTap: () async {
                    if (_teacher == null) return;
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          token: widget.token,
                          realName: _teacher?['realName'],
                          email: _teacher?['email'],
                          phone: _teacher?['phone'],
                        ),
                      ),
                    );
                    if (updated != null) _loadProfile();
                  },
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  icon: Icons.lock_outline,
                  title: 'Đổi mật khẩu',
                  onTap: () {
                    // TODO
                  },
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Thông báo',
                  onTap: () {
                    // TODO
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'Trợ giúp',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: 'Về ứng dụng',
                  onTap: () => _showAboutDialog(),
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Đăng xuất',
                  textColor: Colors.red,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Đăng xuất'),
                        content: const Text(
                            'Bạn có chắc chắn muốn đăng xuất không?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Đăng xuất',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    await TokenStorage.clear();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(
                          context, LoginScreen.routeName);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.blue.shade700),
      title: Text(title,
          style: TextStyle(
              color: textColor ?? Colors.black87, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Examify',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.school, size: 48, color: Colors.blue),
      children: const [
        Text('Ứng dụng thi trắc nghiệm trực tuyến'),
        SizedBox(height: 8),
        Text('Phát triển bởi Team Examify'),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.isEmpty) return 'GV';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }
}
