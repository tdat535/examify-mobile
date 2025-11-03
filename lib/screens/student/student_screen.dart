import 'package:flutter/material.dart';

class StudentScreen extends StatelessWidget {
  static const routeName = '/student-screens';
  const StudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Student Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
