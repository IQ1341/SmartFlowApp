import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomHeader extends StatelessWidget {
  final String deviceName;
  final int notificationCount;

  const CustomHeader({
    super.key,
    required this.deviceName,
    required this.notificationCount,
  });

  @override
  Widget build(BuildContext context) {
    final String today = DateFormat("d MMMM yyyy", 'id_ID').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nama alat dan tanggal
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deviceName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                today,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),

          // Ikon lonceng dengan badge
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, size: 28, color: Colors.black87),
                onPressed: () {
                  // Arahkan ke halaman notifikasi
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
    );
  }
}
