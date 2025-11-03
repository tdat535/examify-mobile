import 'package:flutter/material.dart';
import '../../widgets/modern_appbar.dart';
import '../../api/exam.dart'; // file có ExamApi
import '../../utils/token_storage.dart';
import '../authentication/login_screen.dart';

class CreateExamScreen extends StatefulWidget {
  static const routeName = '/create-exam';
  
  final int classId;
  const CreateExamScreen({super.key, required this.classId});

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _title = TextEditingController();
  final _duration = TextEditingController();
  bool isLoading = false;

  Future<void> _createExam() async {
    if (_title.text.isEmpty || _duration.text.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
        return;
      }

      // Chuẩn bị dữ liệu gửi lên API
      final examData = {
        'title': _title.text.trim(),
        'duration': int.tryParse(_duration.text.trim()) ?? 0,
        'quantityQuestion': 0, // mặc định
        'classId': widget.classId, // <-- dùng classId truyền vào
      };

      // Gọi API
      final newExam = await ExamApi.createExam(token, examData);

      if (context.mounted) {
        Navigator.pop(context, newExam);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Tạo bài thi "${newExam['title']}" thành công!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo bài thi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ModernAppBar(title: 'Tạo bài thi'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thông tin bài thi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                decoration: const InputDecoration(hintText: 'Tên bài thi'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _duration,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Thời gian (phút)'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B61FF)),
                  onPressed: isLoading ? null : _createExam,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Tạo bài thi', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontWeight:FontWeight.w600),),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
