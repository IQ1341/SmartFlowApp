import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  String selectedMonth =
      DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final tagihanRef = FirebaseFirestore.instance
        .collection('tagihan')
        .where('uid', isEqualTo: user?.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      appBar: AppBar(
        title: const Text("Tagihan Air Bulanan"),
        backgroundColor: const Color(0xFF6B8BFF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: tagihanRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return const Center(child: Text("Belum ada data tagihan"));

          final tagihanList = snapshot.data!.docs;

          // Ambil list bulan unik
          final uniqueMonths = tagihanList
              .map((doc) =>
                  (doc.data() as Map<String, dynamic>)['bulan'] as String)
              .toSet()
              .toList()
            ..sort((a, b) => DateFormat('MMMM yyyy', 'id_ID')
                .parse(a)
                .compareTo(DateFormat('MMMM yyyy', 'id_ID').parse(b)));

          // Pastikan selectedMonth valid
          if (!uniqueMonths.contains(selectedMonth)) {
            selectedMonth = uniqueMonths.first;
          }

          final selectedDoc = tagihanList
              .where((e) =>
                  (e.data() as Map<String, dynamic>)['bulan'] == selectedMonth)
              .toList();

          Map<String, dynamic>? selectedData = selectedDoc.isNotEmpty
              ? selectedDoc.first.data() as Map<String, dynamic>
              : null;

          return Column(
            children: [
              // Header Total Tagihan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B8BFF),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Tagihan Bulan Ini",
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(
                      selectedData != null
                          ? "Rp ${NumberFormat("#,##0", "id_ID").format(selectedData['tagihan'])}"
                          : "-",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedData != null
                          ? "Pemakaian: ${selectedData['pemakaian']} m³"
                          : "",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Filter Bulan
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  value: selectedMonth,
                  items: uniqueMonths.map((month) {
                    return DropdownMenuItem<String>(
                      value: month,
                      child: Text(month),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedMonth = value!);
                  },
                  decoration: InputDecoration(
                    labelText: 'Pilih Bulan',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.calendar_month_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Riwayat Tagihan
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tagihanList.length,
                  itemBuilder: (context, index) {
                    final data =
                        tagihanList[index].data() as Map<String, dynamic>;
                    final isPaid = data['status'] == 'Lunas';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isPaid
                              ? Colors.green.withOpacity(0.3)
                              : Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isPaid
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            child: Icon(
                              isPaid
                                  ? Icons.check_circle
                                  : Icons.warning_amber_rounded,
                              color: isPaid ? Colors.green : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['bulan'],
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text("Pemakaian: ${data['pemakaian']} m³"),
                                Text(
                                  "Tagihan: Rp ${NumberFormat("#,##0", "id_ID").format(data['tagihan'])}",
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Chip(
                                label: Text(
                                  data['status'],
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                                backgroundColor:
                                    isPaid ? Colors.green : Colors.orange,
                              ),
                              IconButton(
                                icon: const Icon(Icons.download_rounded),
                                tooltip: "Unduh PDF",
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Unduh tagihan ${data['bulan']}")),
                                  );
                                },
                                color: const Color(0xFF6B8BFF),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
