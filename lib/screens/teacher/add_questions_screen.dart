import 'package:flutter/material.dart';
import '../../api/question.dart';
import '../../utils/token_storage.dart';
import '../../widgets/modern_appbar.dart';
import '../authentication/login_screen.dart';

class AddQuestionsScreen extends StatefulWidget {
  final String examId;

  const AddQuestionsScreen({super.key, required this.examId});

  @override
  State<AddQuestionsScreen> createState() => _AddQuestionsScreenState();
}

class _AddQuestionsScreenState extends State<AddQuestionsScreen> {
  final List<Map<String, dynamic>> tempQuestions = [];

  void _addNewQuestion() {
    setState(() {
      tempQuestions.add({
        'questionCtrl': TextEditingController(),
        'optionsCtrls': List.generate(4, (_) => TextEditingController()),
        'correctIndex': 0, // mặc định chọn đáp án đầu
      });
    });
  }

  Future<void> _saveAll() async {
    final saved = tempQuestions
        .where((q) => q['questionCtrl'].text.trim().isNotEmpty)
        .map((q) => {
              'question': q['questionCtrl'].text.trim(),
              'options': (q['optionsCtrls'] as List<TextEditingController>)
                  .map((c) => c.text.trim())
                  .toList(),
              'correctIndex': q['correctIndex'],
            })
        .toList();

    if (saved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 câu hỏi')),
      );
      return;
    }

    // Hiển thị popup loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Đang tạo câu hỏi...",
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        if (context.mounted) {
          Navigator.pop(context); // đóng dialog loading
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
        return;
      }

      final examId = widget.examId;
      await QuestionApi.addQuestionsToExam(
        token: token,
        examId: examId,
        questions: saved,
      );

      if (context.mounted) {
        Navigator.pop(context); // đóng popup loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm câu hỏi thành công')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // đóng popup loading nếu có lỗi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Thêm câu hỏi',
        actions: [
          TextButton(
            onPressed: _saveAll,
            child: const Text(
              'LƯU',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: tempQuestions.isEmpty
              ? Center(
                  child: Text(
                    'Chưa có câu hỏi nào.\nNhấn nút + để thêm.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: tempQuestions.length,
                  itemBuilder: (_, i) {
                    final q = tempQuestions[i];
                    final optsCtrls =
                        q['optionsCtrls'] as List<TextEditingController>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: q['questionCtrl'],
                                    decoration: InputDecoration(
                                      labelText: 'Câu hỏi ${i + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  onPressed: () =>
                                      setState(() => tempQuestions.removeAt(i)),
                                  tooltip: 'Xóa câu hỏi',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(4, (index) {
                              final isSelected = q['correctIndex'] == index;
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.green.withOpacity(0.12)
                                      : Colors.grey.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Radio<int>(
                                      value: index,
                                      groupValue: q['correctIndex'],
                                      activeColor: Colors.green,
                                      onChanged: (val) {
                                        setState(
                                            () => q['correctIndex'] = val!);
                                      },
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: optsCtrls[index],
                                        decoration: InputDecoration(
                                          prefixText:
                                              '${String.fromCharCode(65 + index)}. ',
                                          prefixStyle: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10, right: 10),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF7B61FF),
          onPressed: _addNewQuestion,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
