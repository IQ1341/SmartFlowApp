import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../widgets/costum_header.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  List<String> _selectedDocIds = [];

  final user = FirebaseAuth.instance.currentUser;

  Future<void> _selectDate({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart ? (_startDate ?? now) : (_endDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getFilteredHistory() {
    final uid = user?.uid;
    if (uid == null) return const Stream.empty();

    final collection =
        FirebaseFirestore.instance.collection('history').doc(uid).collection('data');

    if (_startDate != null && _endDate != null) {
      return collection
          .where('timestamp', isGreaterThanOrEqualTo: _startDate)
          .where('timestamp',
              isLessThanOrEqualTo: _endDate!.add(const Duration(days: 1)))
          .orderBy('timestamp', descending: true)
          .snapshots();
    }

    return collection.orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> _downloadSelected(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Text("Laporan Riwayat Penggunaan Air",
                style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ["Tanggal", "Debit (L/min)", "Volume (L)"],
              data: docs.map((doc) {
                final data = doc.data();
                final rawTimestamp = data['timestamp'];
                DateTime? dateTime;

                if (rawTimestamp is Timestamp) {
                  dateTime = rawTimestamp.toDate();
                } else if (rawTimestamp is String) {
                  dateTime = DateTime.tryParse(rawTimestamp);
                }

                final dateStr = dateTime != null
                    ? DateFormat('dd MMM yyyy, HH:mm').format(dateTime)
                    : '-';

                return [
                  dateStr,
                  "${data['debit']?.toStringAsFixed(1) ?? '-'}",
                  "${data['volume']?.toStringAsFixed(1) ?? '-'}",
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _showCustomAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          "Pilih Data Dulu",
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B8BFF)),
        ),
        content: const Text(
          "Silakan pilih minimal satu data untuk diunduh.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B8BFF),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: const CustomHeader(
        deviceName: "SmartFlow",
        notificationCount: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter tanggal & tombol download
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(isStart: true),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _startDate == null
                          ? "Mulai"
                          : DateFormat('dd MMM yyyy').format(_startDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(isStart: false),
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      _endDate == null
                          ? "Akhir"
                          : DateFormat('dd MMM yyyy').format(_endDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_selectedDocIds.isEmpty) {
                      _showCustomAlert();
                      return;
                    }

                    final uid = user?.uid;
                    if (uid == null) return;

                    final snapshot = await FirebaseFirestore.instance
                        .collection('history')
                        .doc(uid)
                        .collection('data')
                        .where(FieldPath.documentId, whereIn: _selectedDocIds)
                        .get();

                    await _downloadSelected(snapshot.docs);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text("Download"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B8BFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tabel data
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _getFilteredHistory(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text("Tidak ada data."));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 32,
                        headingRowColor:
                            MaterialStateProperty.all(const Color(0xFF6B8BFF)),
                        headingTextStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        columns: const [
                          DataColumn(
                              label:
                                  SizedBox(width: 140, child: Text('Tanggal'))),
                          DataColumn(
                              label:
                                  SizedBox(width: 50, child: Text('Debit'))),
                          DataColumn(
                              label:
                                  SizedBox(width: 50, child: Text('Volume'))),
                        ],
                        rows: docs.map((doc) {
                          final data = doc.data();
                          final id = doc.id;

                          final rawTimestamp = data['timestamp'];
                          DateTime? dateTime;

                          if (rawTimestamp is Timestamp) {
                            dateTime = rawTimestamp.toDate();
                          } else if (rawTimestamp is String) {
                            dateTime = DateTime.tryParse(rawTimestamp);
                          }

                          final dateStr = dateTime != null
                              ? DateFormat('dd MMM yyyy, HH:mm')
                                  .format(dateTime)
                              : '-';

                          final debit =
                              "${data['debit']?.toStringAsFixed(1) ?? '-'}";
                          final volume =
                              "${data['volume']?.toStringAsFixed(1) ?? '-'}";

                          final selected = _selectedDocIds.contains(id);

                          return DataRow(
                            selected: selected,
                            onSelectChanged: (_) {
                              setState(() {
                                if (selected) {
                                  _selectedDocIds.remove(id);
                                } else {
                                  _selectedDocIds.add(id);
                                }
                              });
                            },
                            cells: [
                              DataCell(
                                  SizedBox(width: 140, child: Text(dateStr))),
                              DataCell(
                                  SizedBox(width: 50, child: Text(debit))),
                              DataCell(
                                  SizedBox(width: 50, child: Text(volume))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
