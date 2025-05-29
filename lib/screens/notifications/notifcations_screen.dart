import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  final List<Map<String, dynamic>> _notifications = const [
    {
      'title': 'Pompa Aktif',
      'message': 'Pompa menyala pada 30 Mei 2025, pukul 14:20',
      'icon': Icons.water,
      'color': Colors.blue
    },
    {
      'title': 'Volume Tercapai',
      'message': 'Pengisian mencapai 500L pada 29 Mei 2025',
      'icon': Icons.check_circle,
      'color': Colors.green
    },
    {
      'title': 'Kalibrasi Diperbarui',
      'message': 'Kalibrasi sensor diubah menjadi 4.50 L/pulse',
      'icon': Icons.tune,
      'color': Colors.orange
    },
    {
      'title': 'Logout Berhasil',
      'message': 'Anda berhasil logout dari akun Anda',
      'icon': Icons.logout,
      'color': Colors.redAccent
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FF),
      appBar: AppBar(
        title: const Text("Notifikasi"),
        backgroundColor: const Color(0xFF6B8BFF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: Container(
                decoration: BoxDecoration(
                  color: notif['color'].withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  notif['icon'],
                  color: notif['color'],
                  size: 28,
                ),
              ),
              title: Text(
                notif['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF344054),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  notif['message'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
