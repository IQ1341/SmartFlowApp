import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../widgets/costum_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseReference _dbKalibrasi =
      FirebaseDatabase.instance.ref('kalibrasi');
  double? _calibrationValue;
  int? _tarifValue;
  String? uid;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
    _fetchCalibration();
    _fetchTarif();
  }

  Future<void> _fetchCalibration() async {
    final snapshot = await _dbKalibrasi.get();
    if (snapshot.exists) {
      setState(() {
        _calibrationValue = double.tryParse(snapshot.value.toString());
      });
    }
  }

  Future<void> _fetchTarif() async {
    if (uid == null) return;
    final snapshot =
        await FirebaseDatabase.instance.ref('tarif/$uid').get();
    if (snapshot.exists) {
      setState(() {
        _tarifValue = int.tryParse(snapshot.value.toString());
      });
    }
  }

  Future<void> _showCalibrationDialog() async {
    final controller = TextEditingController(
      text: _calibrationValue?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Edit Nilai Kalibrasi",
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B8BFF)),
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Masukkan nilai kalibrasi (misal: 4.5)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text);
              if (value == null) {
                Navigator.pop(context);
                _showMessage("Input tidak valid!", isError: true);
                return;
              }
              setState(() => _calibrationValue = value);
              await _dbKalibrasi.set(value);
              Navigator.pop(context);
              _showMessage("Kalibrasi berhasil disimpan!", isError: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B8BFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Future<void> _showTarifDialog() async {
    final controller = TextEditingController(
      text: _tarifValue?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Edit Tarif Air (Rp/liter)",
          style:
              TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B8BFF)),
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Masukkan tarif air (misal: 5)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = int.tryParse(controller.text);
              if (value == null || uid == null) {
                Navigator.pop(context);
                _showMessage("Input tidak valid!", isError: true);
                return;
              }
              setState(() => _tarifValue = value);
              await FirebaseDatabase.instance.ref('tarif/$uid').set(value);
              Navigator.pop(context);
              _showMessage("Tarif berhasil disimpan!", isError: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B8BFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showMessage(String message, {required bool isError}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        titlePadding: const EdgeInsets.only(top: 24),
        title: Column(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.redAccent : const Color(0xFF6B8BFF),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isError ? "Gagal" : "Berhasil",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isError ? Colors.redAccent : const Color(0xFF6B8BFF),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B8BFF),
              ),
            ),
          )
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
        notificationCount: 8,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Kalibrasi
            Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: const Text(
                  "Kalibrasi Sensor",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF6B8BFF),
                  ),
                ),
                subtitle: Text(
                  _calibrationValue != null
                      ? "${_calibrationValue!.toStringAsFixed(2)} (L/pulse)"
                      : "Belum ada data",
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: ElevatedButton.icon(
                  onPressed: _showCalibrationDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B8BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tarif
            Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: const Text(
                  "Tarif Air",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF6B8BFF),
                  ),
                ),
                subtitle: Text(
                  _tarifValue != null
                      ? "Rp$_tarifValue / liter"
                      : "Belum ada data",
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: ElevatedButton.icon(
                  onPressed: _showTarifDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B8BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Logout
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
