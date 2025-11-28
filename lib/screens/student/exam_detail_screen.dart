import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../api/student.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ExamDetailScreen extends StatefulWidget {
  final String token;
  final String examId;
  final String examTitle;
  final int duration; // Thời gian làm bài (phút)

  const ExamDetailScreen({
    Key? key,
    required this.token,
    required this.examId,
    required this.examTitle,
    required this.duration,
  }) : super(key: key);

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _examData;
  Map<int, int> _selectedAnswers = {}; // questionId -> answerId

  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadExamDetail();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Theo dõi trạng thái app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Khi app đi background → tự động nộp
    if (state == AppLifecycleState.paused && !_isSubmitting) {
      _submitExam(auto: true);
    }
  }

  Future<void> _loadExamDetail() async {
    setState(() => _isLoading = true);
    try {
      final data = await StudentAPI.getExamDetailForStudent(
        token: widget.token,
        examId: widget.examId,
      );

      // XÁO TRỘN ĐÁP ÁN CHO MỖI CÂU HỎI
      if (data['Questions'] != null) {
        final questions = data['Questions'] as List;
        for (var question in questions) {
          if (question['Answers'] != null) {
            final answers = question['Answers'] as List;
            // Xáo trộn danh sách đáp án
            answers.shuffle(Random());
          }
        }
      }

      setState(() {
        _examData = data;
        _isLoading = false;
        _remainingSeconds = widget.duration * 60;
        _startTimer();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải đề thi: $e')),
      );
      Navigator.pop(context);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _autoSubmit();
      }
    });
  }

  void _autoSubmit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hết giờ! Đang tự động nộp bài...')),
    );
    _submitExam(auto: true);
  }

  /// [auto] = true nếu tự động nộp (hết giờ / rời app)
  Future<void> _submitExam({bool auto = false}) async {
    if (_isSubmitting) return;

    // Nếu submit tự động, không hiện confirm dialog
    if (!auto) {
      final totalQuestions = (_examData?['Questions'] as List?)?.length ?? 0;
      if (_selectedAnswers.length < totalQuestions) {
        final shouldSubmit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Chưa hoàn thành'),
            content: Text(
              'Bạn mới trả lời ${_selectedAnswers.length}/$totalQuestions câu. '
              'Bạn có chắc muốn nộp bài?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tiếp tục làm'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Nộp bài'),
              ),
            ],
          ),
        );
        if (shouldSubmit != true) return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final answers = _selectedAnswers.entries
          .map((e) => {"questionId": e.key, "answerId": e.value})
          .toList();

      await StudentAPI.submitExam(
        token: widget.token,
        examId: widget.examId,
        answers: answers,
      );

      Map<String, dynamic> decoded = JwtDecoder.decode(widget.token);
      print(decoded); // xem các key có gì

      String realName = decoded['realName'] ?? 'Học sinh';
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Học sinh đã nộp bài',
        'content':
            '$realName vừa nộp bài ${widget.examTitle} trong ${_examData?['Class']?['className'] ?? ''}.',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _timer?.cancel();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              auto
                  ? 'Bài thi đã được tự động nộp do rời app hoặc hết giờ.'
                  : 'Nộp bài thành công!',
            ),
          ),
        );
        Navigator.pop(context, true); // Return true để refresh danh sách
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi nộp bài: $e')),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Thoát bài thi?'),
            content: const Text(
                'Bài làm của bạn sẽ không được lưu. Bạn có chắc muốn thoát?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Ở lại'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Thoát'),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.examTitle),
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _remainingSeconds < 300 ? Colors.red : Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildProgressBar(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          (_examData?['Questions'] as List?)?.length ?? 0,
                      itemBuilder: (context, index) {
                        final question = _examData!['Questions'][index];
                        return _buildQuestionCard(question, index);
                      },
                    ),
                  ),
                  _buildSubmitButton(),
                ],
              ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final totalQuestions = (_examData?['Questions'] as List?)?.length ?? 0;
    final answered = _selectedAnswers.length;
    final progress = totalQuestions > 0 ? answered / totalQuestions : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã trả lời: $answered/$totalQuestions câu',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index) {
    final questionId = question['id'];
    final answers = question['Answers'] as List<dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Câu ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question['content'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${question['score']} điểm',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...answers.map((answer) {
              final answerId = answer['id'];
              final isSelected = _selectedAnswers[questionId] == answerId;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedAnswers[questionId] = answerId;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade50
                          : Colors.grey.shade50,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            answer['content'],
                            style: TextStyle(
                              fontSize: 15,
                              color: isSelected
                                  ? Colors.blue.shade900
                                  : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitExam,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'NỘP BÀI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
