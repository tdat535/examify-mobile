import 'package:flutter/material.dart';
import '../../widgets/modern_appbar.dart';
import '../../widgets/class_card.dart';
import '../../api/class.dart';
import '../../utils/token_storage.dart';
import 'create_exam_screen.dart';
import 'exam_question_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  static const routeName = '/class-detail';
  final Map<String, dynamic> classData;
  const ClassDetailScreen({super.key, this.classData = const {}});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> students = [];
  List<dynamic> exams = [];
  bool loadingStudents = true;
  bool loadingExams = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging && mounted) {
        setState(() {});
      }
    });

    _loadData();
  }

  Future<void> _loadData() async {
    final token = await TokenStorage.getToken();
    if (token == null) return;

    final classId = widget.classData['id'].toString();

    // Gọi song song 2 API
    await Future.wait([
      _loadStudents(token, classId),
      _loadExams(token, classId),
    ]);
  }

  Future<void> _loadStudents(String token, String classId) async {
    try {
      final res = await ClassApi.getStudentInClass(token, classId);
      setState(() {
        students = res;
        loadingStudents = false;
      });
    } catch (e) {
      setState(() => loadingStudents = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tải học sinh: $e')));
    }
  }

  Future<void> _loadExams(String token, String classId) async {
    try {
      final res = await ClassApi.getExamInClass(token, classId);
      setState(() {
        exams = res;
        loadingExams = false;
      });
    } catch (e) {
      setState(() => loadingExams = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tải bài thi: $e')));
    }
  }

  Future<void> _refreshCurrentTab() async {
    final token = await TokenStorage.getToken();
    final classId = widget.classData['id'].toString();
    if (token == null) return;

    if (_tabController.index == 0) {
      setState(() => loadingStudents = true);
      await _loadStudents(token, classId);
    } else {
      setState(() => loadingExams = true);
      await _loadExams(token, classId);
    }
  }

  void _showClassCode() {
    final code = widget.classData['classCode'] ?? 'CODE';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mã lớp',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text(
              code,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B61FF),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createExam() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateExamScreen(classId: widget.classData['id']),
      ),
    );
    if (result != null) {
      setState(() => exams.add(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.classData;

    return Scaffold(
      appBar: ModernAppBar(
        title: c['className'] ?? 'Chi tiết lớp',
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: _showClassCode,
            tooltip: 'Hiển thị Mã lớp',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCurrentTab,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            ClassCard(
              title: c['className'] ?? 'Lớp học',
              subtitle: c['classCode'] ?? '',
              dense: true,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              labelColor: Colors.black87,
              indicatorColor: const Color(0xFF7B61FF),
              tabs: const [
                Tab(text: 'Học sinh'),
                Tab(text: 'Bài thi'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _studentsTab(),
                  _examsTab(),
                ],
              ),
            ),
          ]),
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _createExam,
              label: const Text('Tạo bài thi',  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontWeight:FontWeight.w600),),
              icon: const Icon(Icons.add, color: Color.fromARGB(255, 255, 255, 255),),
              backgroundColor: const Color(0xFF7B61FF),
            )
          : null,
    );
  }

  Widget _studentsTab() {
    if (loadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (students.isEmpty) {
      return const Center(child: Text('Chưa có học sinh trong lớp.'));
    }

    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      color: const Color(0xFF7B61FF),
      child: ListView.separated(
        itemCount: students.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (ctx, idx) {
          final s = students[idx];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF7B61FF),
              child: Text(
                s['username'] != null && s['username'].isNotEmpty
                    ? s['username'][0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(s['username'] ?? 'Học sinh'),
            subtitle: Text('Email: ${s['email'] ?? ''}'),
          );
        },
      ),
    );
  }

  Widget _examsTab() {
    if (loadingExams) {
      return const Center(child: CircularProgressIndicator());
    }

    if (exams.isEmpty) {
      return const Center(child: Text('Chưa có bài thi nào.'));
    }

    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      color: const Color(0xFF7B61FF),
      child: ListView.separated(
        itemCount: exams.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, idx) {
          final e = exams[idx];
          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              title: Text(e['title'] ?? ''),
              subtitle: Text(
                '${e['duration']} phút • ${e['quantityQuestion']} câu hỏi',
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExamQuestionScreen(exam: e),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
                ),
                child: const Text(
                  'Câu hỏi',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
