import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  IconData getIcon(String level) {
    switch (level) {
      case 'warning':
        return Icons.warning_amber;
      case 'info':
        return Icons.info_outline;
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.notifications;
    }
  }

  Color getColor(String level) {
    switch (level) {
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String formatWaktu(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    return DateFormat("dd MMMM yyyy • HH:mm", "id_ID").format(date);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Anda belum login")),
      );
    }

    final messenger = ScaffoldMessenger.of(context);
    final notifRef = FirebaseFirestore.instance
        .collection('notifikasi')
        .doc(uid)
        .collection('data')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      appBar: AppBar(
        title: const Text("Notifikasi"),
        backgroundColor: const Color(0xFF6B8BFF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notifRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text("Tidak ada notifikasi."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['judul'] ?? 'Notifikasi';
              final message = data['pesan'] ?? '';
              final level = data['level'] ?? 'info';
              final timestamp = data['timestamp'] as Timestamp?;

              return Dismissible(
                key: Key(doc.id),
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  doc.reference.delete().then((_) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Notifikasi dihapus')),
                    );
                  }).catchError((e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Gagal menghapus: $e')),
                    );
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: getColor(level).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          getIcon(level),
                          color: getColor(level),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D2939),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF475467),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatWaktu(timestamp),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF98A2B3),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
