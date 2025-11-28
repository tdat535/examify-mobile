// lib/screens/add_questions_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import '../../api/question.dart';
import '../../utils/token_storage.dart';
import '../../widgets/modern_appbar.dart';
import '../authentication/login_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AddQuestionsScreen extends StatefulWidget {
  final String examId;
  const AddQuestionsScreen({super.key, required this.examId});

  @override
  State<AddQuestionsScreen> createState() => _AddQuestionsScreenState();
}

class _AddQuestionsScreenState extends State<AddQuestionsScreen> {
  final List<Map<String, dynamic>> tempQuestions = [];

  // ======== Thêm câu hỏi thủ công ========
  void _addNewQuestion() {
    setState(() {
      tempQuestions.add({
        'questionCtrl': TextEditingController(),
        'optionsCtrls': List.generate(4, (_) => TextEditingController()),
        'correctIndex': 0,
      });
    });
  }

  // ======== Dispose controllers ========
  void _disposeQuestionControllers(Map<String, dynamic> q) {
    q['questionCtrl'].dispose();
    for (var c in q['optionsCtrls']) {
      c.dispose();
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo; // <-- đây

      if (androidInfo.version.sdkInt >= 30) {
        // Android 11 trở lên
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            openAppSettings();
            return false;
          }
        }
      } else {
        // Android 10 trở xuống
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            openAppSettings();
            return false;
          }
        }
      }
    }
    return true;
  }

  // ======== Tạo Excel mẫu ========
  Future<void> createSampleExcel(BuildContext context) async {
    try {
      // 1. Tạo Excel
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow([
        TextCellValue('Question'),
        TextCellValue('Option A'),
        TextCellValue('Option B'),
        TextCellValue('Option C'),
        TextCellValue('Option D'),
        TextCellValue('Correct')
      ]);

      sheet.appendRow([
        TextCellValue('Câu hỏi mẫu'),
        TextCellValue('Đáp án A'),
        TextCellValue('Đáp án B'),
        TextCellValue('Đáp án C'),
        TextCellValue('Đáp án D'),
        TextCellValue('C')
      ]);

      final fileBytes = excel.encode();
      if (fileBytes == null) throw Exception('Không tạo được file Excel');

      // 2. Lưu vào App Documents (luôn được phép)
      final docsDir = await getApplicationDocumentsDirectory();
      final docsPath = '${docsDir.path}/sample_questions.xlsx';
      final docsFile = File(docsPath);
      await docsFile.writeAsBytes(fileBytes, flush: true);

      String msg = '✅ File lưu tại App Docs: $docsPath';

      // 3. Lưu vào Download (Scoped Storage)
      if (Platform.isAndroid) {
        // Thư viện path_provider không cung cấp trực tiếp Download, dùng đường dẫn cố định
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (!downloadDir.existsSync()) downloadDir.createSync(recursive: true);

        final downloadPath = '${downloadDir.path}/sample_questions.xlsx';
        final downloadFile = File(downloadPath);
        await downloadFile.writeAsBytes(fileBytes, flush: true);

        msg = '✅ File lưu tại:\nDownload: $downloadPath\nApp Docs: $docsPath';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );

      // 4. Mở file
      await OpenFile.open(
        Platform.isAndroid
            ? '/storage/emulated/0/Download/sample_questions.xlsx'
            : docsPath,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi tạo file: $e')),
      );
    }
  }

  // ======== Import từ Excel ========
  Future<void> _importFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null) return;

      final file = File(result.files.single.path!);
      final bytes = file.readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      final sheet = excel.sheets.values.first;
      if (sheet.maxRows < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File Excel trống hoặc sai định dạng')),
        );
        return;
      }

      final newQuestions = <Map<String, dynamic>>[];

      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.length < 6) continue;

        final question = row[0]?.value.toString() ?? '';
        final options =
            List.generate(4, (j) => row[j + 1]?.value.toString() ?? '');
        final correctChar = row[5]?.value.toString().toUpperCase() ?? 'A';
        final correctIndex = 'ABCD'.indexOf(correctChar);

        if (question.trim().isEmpty ||
            options.any((o) => o.trim().isEmpty) ||
            correctIndex == -1) continue;

        newQuestions.add({
          'questionCtrl': TextEditingController(text: question),
          'optionsCtrls':
              options.map((o) => TextEditingController(text: o)).toList(),
          'correctIndex': correctIndex,
        });
      }

      setState(() => tempQuestions.addAll(newQuestions));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('✅ Đã nhập ${newQuestions.length} câu hỏi từ Excel')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi import Excel: $e')),
      );
    }
  }

  // ======== Popup Excel ========
  void _showExcelOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Tải Excel mẫu'),
              onTap: () {
                Navigator.pop(context);
                createSampleExcel(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Import từ Excel'),
              onTap: () {
                Navigator.pop(context);
                _importFromExcel();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ======== Lưu tất cả câu hỏi ========
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16))),
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
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        }
        return;
      }

      await QuestionApi.addQuestionsToExam(
          token: token, examId: widget.examId, questions: saved);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Thêm câu hỏi thành công')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('❌ Lỗi khi lưu: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Thêm câu hỏi',
        actions: [
          IconButton(
              icon: const Icon(Icons.grid_on),
              tooltip: 'Excel',
              onPressed: _showExcelOptions),
          TextButton(
            onPressed: _saveAll,
            child: const Text('LƯU',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: tempQuestions.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có câu hỏi nào.\nNhấn nút + hoặc import Excel để thêm.',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        onPressed: () {
                                          setState(() {
                                            _disposeQuestionControllers(q);
                                            tempQuestions.removeAt(i);
                                          });
                                        },
                                        tooltip: 'Xóa câu hỏi',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...List.generate(4, (index) {
                                    final isSelected =
                                        q['correctIndex'] == index;
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.green.withOpacity(0.12)
                                            : Colors.grey.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Radio<int>(
                                            value: index,
                                            groupValue: q['correctIndex'],
                                            activeColor: Colors.green,
                                            onChanged: (val) => setState(
                                                () => q['correctIndex'] = val!),
                                          ),
                                          Expanded(
                                            child: TextField(
                                              controller: optsCtrls[index],
                                              decoration: InputDecoration(
                                                prefixText:
                                                    '${String.fromCharCode(65 + index)}. ',
                                                prefixStyle: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87),
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
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7B61FF),
        onPressed: _addNewQuestion,
        child: const Icon(Icons.add),
      ),
    );
  }
}
