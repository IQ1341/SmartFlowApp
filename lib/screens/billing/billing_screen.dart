import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final List<Map<String, dynamic>> billingHistory = [
    {
      'month': 'Mei 2025',
      'usage': 14.2,
      'amount': 49700,
      'status': 'Lunas',
    },
    {
      'month': 'April 2025',
      'usage': 10.5,
      'amount': 36750,
      'status': 'Belum Lunas',
    },
    {
      'month': 'Maret 2025',
      'usage': 12.0,
      'amount': 42000,
      'status': 'Lunas',
    },
  ];

  final int tariff = 3500;
  String selectedMonth = 'Mei 2025';

  @override
  Widget build(BuildContext context) {
    final current =
        billingHistory.firstWhere((e) => e['month'] == selectedMonth);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      appBar: AppBar(
        title: const Text("Tagihan Air Bulanan"),
        backgroundColor: const Color(0xFF6B8BFF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
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
                    color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Total Tagihan Bulan Ini",
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 6),
                Text(
                  "Rp ${NumberFormat("#,##0", "id_ID").format(current['amount'])}",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Pemakaian: ${current['usage']} m³",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Filter Bulan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              value: selectedMonth,
              items: billingHistory.map((item) {
                return DropdownMenuItem<String>(
                  value: item['month'],
                  child: Text(item['month']),
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
              itemCount: billingHistory.length,
              itemBuilder: (context, index) {
                final item = billingHistory[index];
                final isPaid = item['status'] == 'Lunas';

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
                              item['month'],
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text("Pemakaian: ${item['usage']} m³"),
                            Text(
                              "Tagihan: Rp ${NumberFormat("#,##0", "id_ID").format(item['amount'])}",
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
                              item['status'],
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
                                    content:
                                        Text("Unduh tagihan ${item['month']}")),
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
      ),
    );
  }
}
