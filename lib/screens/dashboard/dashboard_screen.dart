import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/costum_header.dart';
import 'dart:math';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DatabaseReference get _ref {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseDatabase.instance.ref('monitoring/$uid');
  }


  double _debit = 0.0;
  double _volume = 0.0;
  bool _isPumpOn = false;
  String _selectedRange = 'day';

  List<double> _dummyData = [];

  @override
  void initState() {
    super.initState();
    _listenToRealtimeData();
    _loadDummyChartData();
  }

  void _listenToRealtimeData() {
    _ref.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          _debit = (data['debit'] ?? 0).toDouble();
          _volume = (data['volume'] ?? 0).toDouble();

          final pumpRaw = data['pump'];
          if (pumpRaw is int) {
            _isPumpOn = pumpRaw == 1;
          } else if (pumpRaw is bool) {
            _isPumpOn = pumpRaw;
          } else {
            _isPumpOn = false;
          }
        });

        generateMonthlyBillIfNeeded();
      }
    });
  }

  Future<void> generateMonthlyBillIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final email = user.email ?? '';
    final now = DateTime.now();
    final monthName = "${_getMonthName(now.month)} ${now.year}";
    final rate = 5; // tarif per liter
    final tagihan = (_volume * rate).toInt();

    final docId = "$uid-$monthName";
    final docRef = FirebaseFirestore.instance.collection('tagihan').doc(docId);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      await docRef.set({
        'bulan': monthName,
        'email': email,
        'pemakaian': _volume,
        'status': 'Belum Lunas',
        'tagihan': tagihan,
        'uid': uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("✅ Tagihan bulan $monthName berhasil dibuat");
    } else {
      print("ℹ️ Tagihan bulan $monthName sudah ada, tidak dibuat ulang.");
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  void _loadDummyChartData() {
    setState(() {
      _dummyData = List.generate(
        _selectedRange == 'day'
            ? 24
            : _selectedRange == 'week'
                ? 7
                : 30,
        (_) => 5 + Random().nextDouble() * 10,
      );
    });
  }

  void _onRangeChanged(String range) {
    setState(() {
      _selectedRange = range;
      _loadDummyChartData();
    });
  }

  void _togglePump(bool value) {
    setState(() {
      _isPumpOn = value;
    });

    _ref.update({
      'pump': value ? 1 : 0,
});
  }

  void _goToBillingPage() {
    Navigator.pushNamed(context, '/billing');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: const CustomHeader(
        deviceName: 'SmartFlow',
        notificationCount: 3,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Sensor Cards
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.speed,
                              size: 28,
                              color: Color.fromARGB(255, 107, 139, 255)),
                          SizedBox(width: 6),
                          Text(
                            "Debit Air",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color.fromARGB(255, 107, 139, 255)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSensorCard(
                        value: _debit,
                        unit: "L/min",
                        cardColor: Color.fromARGB(255, 107, 139, 255),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.water,
                              size: 28,
                              color: Color.fromARGB(255, 107, 139, 255)),
                          SizedBox(width: 6),
                          Text(
                            "Volume Air",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color.fromARGB(255, 107, 139, 255),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSensorCard(
                        value: _volume,
                        unit: "Liter",
                        cardColor: Color.fromARGB(255, 107, 139, 255),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pompa dan Tombol Tagihan
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Switch(
                              value: _isPumpOn,
                              onChanged: _togglePump,
                              activeColor:
                                  const Color.fromARGB(255, 107, 139, 255),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Control Pompa",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color.fromARGB(255, 107, 139, 255),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _goToBillingPage,
                        icon:
                            const Icon(Icons.receipt_long, color: Colors.white),
                        label: const Text("Tagihan"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 107, 139, 255),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tombol Range Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRangeButton('day', 'Per Hari'),
                _buildRangeButton('week', 'Per Minggu'),
                _buildRangeButton('month', 'Per Bulan'),
              ],
            ),
            const SizedBox(height: 16),

            // Grafik Debit Air
            SizedBox(
              height: 280,
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Grafik Debit Air",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 107, 139, 255))),
                      const SizedBox(height: 12),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey[300],
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 2,
                                  reservedSize: 32,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: _selectedRange == 'day' ? 4 : 1,
                                  getTitlesWidget: (value, meta) => Text(
                                    _selectedRange == 'day'
                                        ? '${value.toInt()}h'
                                        : '${value.toInt() + 1}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                                ),
                              ),
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: const Border(
                                left: BorderSide(color: Colors.black12),
                                bottom: BorderSide(color: Colors.black12),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _dummyData
                                    .asMap()
                                    .entries
                                    .map((e) =>
                                        FlSpot(e.key.toDouble(), e.value))
                                    .toList(),
                                isCurved: true,
                                color: const Color.fromARGB(255, 107, 139, 255),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color.fromARGB(255, 107, 139, 255)
                                          .withOpacity(0.4),
                                      const Color.fromARGB(255, 107, 139, 255)
                                          .withOpacity(0.1),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                                barWidth: 3,
                                dotData: FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeButton(String key, String label) {
    final isSelected = _selectedRange == key;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: OutlinedButton(
        onPressed: () => _onRangeChanged(key),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color.fromARGB(255, 107, 139, 255)
              : Colors.white,
          foregroundColor: isSelected
              ? Colors.white
              : const Color.fromARGB(255, 107, 139, 255),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildSensorCard({
    required double value,
    required String unit,
    required Color cardColor,
  }) {
    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardColor,
              border: Border.all(color: Colors.white, width: 7),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
