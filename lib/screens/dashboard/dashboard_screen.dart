import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/costum_header.dart';

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
  List<FlSpot> _chartData = [];

  @override
  void initState() {
    super.initState();
    _listenToRealtimeData();
    _loadChartDataFromFirestore();
  }

  void _listenToRealtimeData() {
    _ref.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          _debit = (data['debit'] ?? 0).toDouble();
          _volume = (data['volume'] ?? 0).toDouble();

          final pumpRaw = data['pump'];
          if (pumpRaw is bool) {
            _isPumpOn = pumpRaw;
          } else if (pumpRaw is int) {
            _isPumpOn = pumpRaw == 1;
          } else {
            _isPumpOn = false;
          }
        });

        // Kirim volume saat ini ke fungsi tagihan
        generateMonthlyBillIfNeeded(_volume);
      }
    });
  }

  Future<void> generateMonthlyBillIfNeeded(double currentVolume) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final email = user.email ?? '';
    final now = DateTime.now();
    final monthName = "${_getMonthName(now.month)} ${now.year}";
    final docId = "$uid-$monthName";

    final tagihanRef =
        FirebaseFirestore.instance.collection('tagihan').doc(docId);
    final tagihanSnap = await tagihanRef.get();

    if (tagihanSnap.exists) {
      print("ℹ️ Tagihan bulan $monthName sudah ada, tidak dibuat ulang.");
      return;
    }

    // Ambil tarif dari Realtime Database
    final tarifRef = FirebaseDatabase.instance.ref("tarif/$uid");
    final tarifSnap = await tarifRef.get();
    if (!tarifSnap.exists) {
      print("❌ Tarif belum diatur untuk user $uid");
      return;
    }
    final rate = int.tryParse(tarifSnap.value.toString()) ?? 0;

    // Ambil volume bulan lalu dari Firestore
    final lastVolRef =
        FirebaseFirestore.instance.collection('last_volume').doc(uid);
    final lastVolSnap = await lastVolRef.get();
    final lastVolume = (lastVolSnap.data()?['volume'] ?? 0).toDouble();

    // Hitung pemakaian dan tagihan
    final pemakaianBulanIni = currentVolume - lastVolume;
    final tagihan = (pemakaianBulanIni * rate).toInt();

    await tagihanRef.set({
      'bulan': monthName,
      'email': email,
      'pemakaian': pemakaianBulanIni,
      'status': 'Belum Lunas',
      'tagihan': tagihan,
      'uid': uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await lastVolRef.set({'volume': currentVolume});
    print("✅ Tagihan bulan $monthName berhasil dibuat");
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

Future<void> _loadChartDataFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    late DateTime startDate;
    late DateTime endDate;

    if (_selectedRange == 'day') {
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(Duration(days: 1));
    } else if (_selectedRange == 'week') {
      startDate = now.subtract(Duration(days: 6));
      endDate = now.add(Duration(days: 1));
    } else {
      startDate = now.subtract(Duration(days: 29));
      endDate = now.add(Duration(days: 1));
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('history')
        .doc(uid)
        .collection('data')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThan: Timestamp.fromDate(endDate))
        .orderBy('timestamp')
        .get();

    final List<FlSpot> spots = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final timestampRaw = data['timestamp'];
      final debit = (data['debit'] ?? 0).toDouble();

      try {
        final timestamp = (timestampRaw as Timestamp).toDate();
        double x;
        if (_selectedRange == 'day') {
          x = timestamp.hour.toDouble();
        } else if (_selectedRange == 'week') {
          x = timestamp.weekday.toDouble(); // 1 = Monday
        } else {
          x = timestamp.day.toDouble();
        }

        spots.add(FlSpot(x, debit));
      } catch (e) {
        continue;
      }
    }

    setState(() {
      _chartData = spots;
    });
  }


void _onRangeChanged(String range) {
    setState(() {
      _selectedRange = range;
    });
    _loadChartDataFromFirestore();
}


void _togglePump(bool value) {
    setState(() {
      _isPumpOn = value;
    });

    _ref.update({
      'pump': value, // langsung boolean
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
        // notificationCount: 3,
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
                                  interval: 20,
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
                                spots: _chartData,
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
