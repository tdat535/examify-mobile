// lib/screens/exam_question_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/modern_appbar.dart';
import '../../api/exam.dart';
import '../../utils/token_storage.dart';
import 'add_questions_screen.dart';

class ExamQuestionScreen extends StatefulWidget {
  static const routeName = '/exam-questions';
  final Map<String, dynamic> exam;
  const ExamQuestionScreen({super.key, required this.exam});

  @override
  State<ExamQuestionScreen> createState() => _ExamQuestionScreenState();
}

class _ExamQuestionScreenState extends State<ExamQuestionScreen> {
  Map<String, dynamic>? examDetail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExamDetail();
  }

  Future<void> _loadExamDetail() async {
    try {
      final token = await TokenStorage.getToken();
      final examId = widget.exam['id'].toString();
      final res = await ExamApi.getExamDetailForTeacher(token!, examId);
      setState(() {
        examDetail = res;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('❌ Error loading exam: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải đề thi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final examTitle = examDetail?['title'] ?? widget.exam['title'] ?? 'Đề thi';

    return Scaffold(
      appBar: ModernAppBar(
        title: examTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm câu hỏi',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddQuestionsScreen(
                    examId: widget.exam['id'].toString(),
                  ),
                ),
              );
              if (result == true) {
                _loadExamDetail();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExamDetail,
            tooltip: 'Làm mới dữ liệu',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : examDetail == null
              ? const Center(child: Text('Không có dữ liệu đề thi.'))
              : _buildQuestionList(examDetail!['Questions'] ?? []),
    );
  }

  Widget _buildQuestionList(List<dynamic> questions) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.separated(
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final q = questions[i];
          final questionText = q['content'] ?? '';
          final answers = q['Answers'] as List<dynamic>;
          final correctId = q['correctAnswerIndex'];

          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Câu ${i + 1}: $questionText',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...answers.map((ans) {
                    final isCorrect = ans['id'] == correctId;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        title: Text(ans['content'] ?? ''),
                        trailing: isCorrect
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
