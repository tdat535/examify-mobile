// lib/screens/NotificationScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class NotificationScreen extends StatelessWidget {
  static const routeName = '/notifications';
  final String token;

  const NotificationScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    // Decode token để lấy userId
    final payload = JwtDecoder.decode(token);
    final userId = payload['id'].toString(); // ép kiểu string
    print('🔹 userId from token: $userId');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text('❌ Lỗi khi load dữ liệu: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            print('🔹 docs length: ${docs.length}');
            for (var d in docs) {
              print('🔹 doc: ${d.data()}');
            }

            if (docs.isEmpty) {
              return const Center(child: Text('Chưa có thông báo nào.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final n = docs[idx];
                final data = n.data() as Map<String, dynamic>;
                final title = data['title'] ?? '';
                final content = data['content'] ?? '';
                final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                final timeString = timestamp != null
                    ? '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.day}/${timestamp.month}'
                    : '';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF00C2FF), Color(0xFF7B61FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child:
                          const Icon(Icons.notifications, color: Colors.white),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          content,
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          timeString,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {},
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
