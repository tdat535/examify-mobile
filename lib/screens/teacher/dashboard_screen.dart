// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:advanced_salomon_bottom_bar/advanced_salomon_bottom_bar.dart';
import '../../utils/token_storage.dart';
import '../../api/dashboard.dart';
import '../authentication/login_screen.dart';
import '../teacher/class_list_screen.dart';
import '../teacher/notification_screen.dart';
import '../teacher/profile_screen.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/class_card.dart';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/dashboard';
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  String? token; // lưu token
  Map<String, dynamic>? dashboardData;
  List<dynamic> recentClasses = [];
  bool isLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initTokenAndDashboard();
  }

  Future<void> _initTokenAndDashboard() async {
    token = await TokenStorage.getToken();
    if (token == null && context.mounted) {
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      return;
    }
    await _loadDashboard();
    setState(() {}); // refresh UI khi token đã load
  }

  Future<void> _loadDashboard() async {
    if (token == null) return;

    try {
      if (!isRefreshing) {
        setState(() => isLoading = true);
      }

      final data = await DashboardApi.fetchDashboardData(token!);
      final classes = await DashboardApi.fetchDashboardClasses(token!);

      setState(() {
        dashboardData = data;
        recentClasses = classes is List ? classes : [];
        isLoading = false;
        isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu dashboard: $e')),
        );
      }
    }
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || token == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      _dashboardTab(),
      const ClassListScreen(),
      NotificationScreen(token: token!),
      TeacherProfileScreen(token: token!), // ✅ token đã có
    ];

    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: AdvancedSalomonBottomBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        items: [
          AdvancedSalomonBottomBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            title: const Text('Trang chủ'),
            selectedColor: const Color(0xFF7B61FF),
          ),
          AdvancedSalomonBottomBarItem(
            icon: const Icon(Icons.class_outlined),
            activeIcon: const Icon(Icons.class_),
            title: const Text('Lớp học'),
            selectedColor: const Color(0xFF7B61FF),
          ),
          AdvancedSalomonBottomBarItem(
            icon: const Icon(Icons.notifications_none),
            activeIcon: const Icon(Icons.notifications),
            title: const Text('Thông báo'),
            selectedColor: const Color(0xFF7B61FF),
          ),
          AdvancedSalomonBottomBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            title: const Text('Hồ sơ'),
            selectedColor: const Color(0xFF7B61FF),
          ),
        ],
      ),
    );
  }

  // ====== Dashboard Tab ======
  Widget _dashboardTab() {
    final teacherName = dashboardData?['teacherName'] ?? 'Giáo viên';
    final totalClasses = dashboardData?['totalClasses']?.toString() ?? '0';
    final totalExams = dashboardData?['totalExams']?.toString() ?? '0';

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => isRefreshing = true);
        await _loadDashboard();
      },
      color: const Color(0xFF7B61FF),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _greeting(teacherName),
            const SizedBox(height: 12),
            _statsRow(totalClasses, totalExams),
            const SizedBox(height: 18),
            const Text(
              'Lớp của bạn',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (recentClasses.isEmpty) const Text('Chưa có lớp học nào.'),
            ListView.separated(
              itemCount: recentClasses.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final c = recentClasses[index];
                return ClassCard(
                  title: c['className'] ?? 'Không rõ',
                  subtitle:
                      '${c['classCode'] ?? ''} • ${c['createdAt']?.toString().split("T").first ?? ''}',
                  onTap: () async {
                    await Navigator.pushNamed(context, '/class-detail',
                        arguments: c);
                    _loadDashboard();
                  },
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _greeting(String name) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundColor: Color(0xFFF3E8FF),
          child: Icon(Icons.person, size: 28, color: Color(0xFF7B61FF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Xin chào, $name!',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            softWrap: true,
          ),
        ),
        IconButton(
          icon: isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF7B61FF),
                  ),
                )
              : const Icon(Icons.refresh, color: Color(0xFF7B61FF)),
          tooltip: 'Làm mới dữ liệu',
          onPressed: isRefreshing
              ? null
              : () async {
                  setState(() => isRefreshing = true);
                  await _loadDashboard();
                },
        ),
      ],
    );
  }

  Widget _statsRow(String totalClasses, String totalExams) {
    return Row(
      children: [
        Expanded(
          child: StatsCard(
            title: 'Lớp học',
            count: totalClasses,
            icon: Icons.menu_book,
            color: const Color(0xFF7B61FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatsCard(
            title: 'Bài thi',
            count: totalExams,
            icon: Icons.question_answer,
            color: const Color(0xFF00C2FF),
          ),
        ),
      ],
    );
  }
}
