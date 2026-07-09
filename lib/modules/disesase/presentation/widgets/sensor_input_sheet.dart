import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Form input sensor manual (semua field OPSIONAL, boleh dikosongkan).
/// Dikembalikan sebagai Map {key_llm: nilai} hanya untuk field yang diisi.
/// Key sesuai format yang dipahami backend/LLM.
class SensorInputSheet extends StatefulWidget {
  const SensorInputSheet({Key? key}) : super(key: key);

  /// Tampilkan sebagai bottom sheet. Mengembalikan:
  /// - Map berisi data (bisa kosong) bila pengguna menekan tombol.
  /// - null bila sheet ditutup tanpa aksi.
  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SensorInputSheet(),
    );
  }

  @override
  State<SensorInputSheet> createState() => _SensorInputSheetState();
}

class _SensorInputSheetState extends State<SensorInputSheet> {
  // [key_llm, label, satuan]
  static const List<List<String>> _fields = [
    ['suhu_udara', 'Suhu Udara', '°C'],
    ['kelembaban_udara', 'Kelembaban Udara', '%'],
    ['suhu_tanah', 'Suhu Tanah', '°C'],
    ['kelembaban_tanah', 'Kelembaban Tanah', '%'],
    ['ph_tanah', 'pH Tanah', 'pH'],
    ['nitrogen', 'Nitrogen (N)', 'mg/kg'],
    ['fosfor', 'Fosfor (P)', 'mg/kg'],
    ['kalium', 'Kalium (K)', 'mg/kg'],
    ['intensitas_cahaya', 'Intensitas Cahaya', 'lux'],
    ['curah_hujan', 'Curah Hujan', 'mm'],
  ];

  late final Map<String, TextEditingController> _controllers = {
    for (final f in _fields) f[0]: TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final Map<String, dynamic> data = {};
    _controllers.forEach((key, c) {
      final txt = c.text.trim().replaceAll(',', '.');
      if (txt.isNotEmpty) {
        final val = double.tryParse(txt);
        if (val != null) data[key] = val;
      }
    });
    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    final green = Colors.green.shade700;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Tambah Data Sensor Sekarang',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Semua kolom opsional — kosongkan jika tidak ada datanya.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final f in _fields)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TextField(
                          controller: _controllers[f[0]],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: f[1],
                            suffixText: f[2],
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(<String, dynamic>{}),
                    child: const Text('Lewati'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _submit,
                    child: const Text('Gunakan Data Ini'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
