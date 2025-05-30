import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final tagihanRef = FirebaseFirestore.instance.collection('tagihan');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Admin"),
        backgroundColor: const Color(0xFF6B8BFF),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.blue[50],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: tagihanRef.where('bulan', isEqualTo: _selectedMonth).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

            final data = snapshot.data?.docs ?? [];

            final totalUser = data.map((e) => e['uid']).toSet().length;
            final totalPemakaian = data.fold<double>(0, (sum, e) => sum + (e['pemakaian'] ?? 0));
            final totalTagihan = data.fold<double>(0, (sum, e) => sum + (e['tagihan'] ?? 0));
            final lunasCount = data.where((e) => e['status'] == 'Lunas').length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthFilter(),
                const SizedBox(height: 16),
                _buildStats(totalUser, totalPemakaian, totalTagihan, lunasCount),
                const SizedBox(height: 24),
                const Text(
                  "Daftar Tagihan Bulan Ini",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6B8BFF)),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: data.isEmpty
                      ? const Center(child: Text("Tidak ada data tagihan."))
                      : ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final doc = data[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: const Icon(Icons.person, color: Color(0xFF6B8BFF)),
                                title: Text(doc['email'] ?? '-'),
                                subtitle: Text(
                                  'Pemakaian: ${doc['pemakaian'] ?? 0} m³\nTagihan: Rp${(doc['tagihan'] ?? 0).toStringAsFixed(0)}',
                                ),
                                trailing: DropdownButton<String>(
                                  value: doc['status'],
                                  onChanged: (value) {
                                    if (value != null) {
                                      doc.reference.update({'status': value});
                                    }
                                  },
                                  items: ['Lunas', 'Belum Lunas']
                                      .map((status) => DropdownMenuItem(
                                            value: status,
                                            child: Text(status),
                                          ))
                                      .toList(),
                                ),
                              ),
                            );
                          },
                        ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthFilter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Filter Bulan:",
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final selected = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2023),
              lastDate: DateTime.now(),
              helpText: 'Pilih bulan dan tahun',
            );

            if (selected != null) {
              setState(() {
                _selectedMonth = DateFormat('MMMM yyyy').format(selected);
              });
            }
          },
          icon: const Icon(Icons.calendar_month),
          label: Text(_selectedMonth),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B8BFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(int totalUser, double totalPemakaian, double totalTagihan, int lunasCount) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 100,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      children: [
        _buildStatCard("Pengguna", totalUser.toString(), Icons.people, Colors.blue),
        _buildStatCard("Pemakaian", "${totalPemakaian.toStringAsFixed(1)} m³", Icons.water_drop, Colors.indigo),
        _buildStatCard("Total Tagihan", "Rp${totalTagihan.toStringAsFixed(0)}", Icons.attach_money, Colors.green),
        _buildStatCard("Lunas", lunasCount.toString(), Icons.check_circle, Colors.teal),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
