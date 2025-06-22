import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String deviceName;

  const CustomHeader({
    super.key,
    required this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    final String today =
        DateFormat("d MMMM yyyy", 'id_ID').format(DateTime.now());

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return AppBar(
      backgroundColor: const Color(0xFF6B8BFF),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
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
          const SizedBox(height: 2),
          Text(
            today,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      actions: [
        if (uid != null)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("notifikasi")
                .doc(uid)
                .collection("data")
                .snapshots(),
            builder: (context, snapshot) {
              final notifCount = snapshot.data?.docs.length ?? 0;

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/notifications');
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
                      if (notifCount > 0)
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
                                notifCount > 99 ? '99+' : '$notifCount',
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
              );
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);
}
