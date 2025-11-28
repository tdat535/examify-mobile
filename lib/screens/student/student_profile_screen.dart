import 'package:examify_app/screens/student/EditProfileScreen.dart';
import 'package:flutter/material.dart';
import '../../api/auth.dart';
import '../../utils/token_storage.dart';
import '../authentication/login_screen.dart';
import './EditProfileScreen.dart';

class StudentProfileScreen extends StatefulWidget {
  final String token;

  const StudentProfileScreen({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await AuthAPI.getProfile(widget.token);
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải thông tin: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 20),
                    _buildProfileInfo(),
                    const SizedBox(height: 20),
                    _buildMenuSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final displayName = _profile?['realName'] ?? 'Tên người dùng';
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
                  _getInitials(displayName),
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
            displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _profile?['email'] ?? 'email@example.com',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    final displayName = _profile?['realName'] ?? 'Chưa cập nhật';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
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
              _buildInfoRow(Icons.person, 'Họ tên', displayName),
              const Divider(),
              _buildInfoRow(
                  Icons.email, 'Email', _profile?['email'] ?? 'Chưa cập nhật'),
              const Divider(),
              _buildInfoRow(Icons.phone, 'Số điện thoại',
                  _profile?['phone'] ?? 'Chưa cập nhật'),
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
              if (_profile == null) return;
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(
                    token: widget.token,
                    realName: _profile?['realName'],
                    email: _profile?['email'],
                    phone: _profile?['phone'],
                  ),
                ),
              );
              if (updated != null) _loadProfile(); // 🔄 reload profile
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
                    if (_profile == null) return;
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          token: widget.token,
                          realName: _profile?['realName'],
                          email: _profile?['email'],
                          phone: _profile?['phone'],
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

  Widget _buildMenuItem(
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      Color? textColor}) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.blue.shade700),
      title: Text(title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
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
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }
}
