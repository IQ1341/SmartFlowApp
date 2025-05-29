import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String deviceName;
  final int notificationCount;

  const CustomHeader({
    super.key,
    required this.deviceName,
    required this.notificationCount,
  });

  @override
  Widget build(BuildContext context) {
    final String today =
        DateFormat("d MMMM yyyy", 'id_ID').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.only(top: 25, left: 16, right: 16, bottom: 12),
      color: const Color.fromARGB(255, 107, 139, 255),
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                today,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),

          // Notifikasi dengan badge
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/notifications');
              // Jika kamu tidak pakai named route, bisa ganti:
              // Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen()));
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white24,
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 20, minHeight: 20),
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
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(68);
}
