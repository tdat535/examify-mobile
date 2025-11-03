import 'package:flutter/material.dart';
import '../../widgets/class_card.dart';
import '../../api/class.dart';
import '../../utils/token_storage.dart';
import '../authentication/login_screen.dart';

class ClassListScreen extends StatefulWidget {
  static const routeName = '/classes';
  const ClassListScreen({super.key});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  List<dynamic> classes = [];
  bool isLoading = true;
  bool isRefreshing = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      if (!isRefreshing) setState(() => isLoading = true);

      final token = await TokenStorage.getToken();
      if (token == null) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
        return;
      }

      final data = await ClassApi.getClasses(token);

      setState(() {
        classes = data is List ? data : [];
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
          SnackBar(content: Text('Lỗi tải danh sách lớp: $e')),
        );
      }
    }
  }

  void _showCreateClass(BuildContext context) {
    final nameController = TextEditingController();
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Tạo lớp mới',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: 'Tên lớp'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isCreating
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;

                          setDialogState(() => isCreating = true);

                          try {
                            final token = await TokenStorage.getToken();
                            if (token == null) {
                              Navigator.pushReplacementNamed(
                                  context, LoginScreen.routeName);
                              return;
                            }

                            final newClass = await ClassApi.createClass(token, {
                              'className': name,
                            });

                            await _loadClasses();

                            Navigator.pop(ctx);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Tạo lớp "${newClass['className']}" thành công!'),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isCreating = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi tạo lớp học: $e')),
                              );
                            }
                          }
                        },
                  child: isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Tạo', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredClasses = classes
        .where((c) =>
            c['className']?.toLowerCase().contains(searchQuery.toLowerCase()) ==
                true ||
            c['classCode']?.toLowerCase().contains(searchQuery.toLowerCase()) ==
                true)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF7B61FF)),
                  )
                : const Icon(Icons.refresh, color: Color(0xFF7B61FF)),
            onPressed: isRefreshing
                ? null
                : () async {
                    setState(() => isRefreshing = true);
                    await _loadClasses();
                  },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadClasses,
                color: const Color(0xFF7B61FF),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _searchBar(),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredClasses.isEmpty
                            ? const Center(child: Text('Chưa có lớp học nào.'))
                            : ListView.separated(
                                itemCount: filteredClasses.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (ctx, idx) {
                                  final c = filteredClasses[idx];
                                  return ClassCard(
                                      title: c['className'] ?? 'Không rõ',
                                      subtitle:
                                          '${c['classCode'] ?? ''} • ${c['createdAt']?.toString().split("T").first ?? ''}',
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/class-detail',
                                          arguments: c,
                                        );
                                      });
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B61FF), Color(0xFFB388FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: FloatingActionButton(
          onPressed: () => _showCreateClass(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Color.fromARGB(255, 255, 255, 255))
        ),
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      onChanged: (val) => setState(() => searchQuery = val),
      decoration: InputDecoration(
        hintText: 'Tìm lớp, mã lớp...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFFF7F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
