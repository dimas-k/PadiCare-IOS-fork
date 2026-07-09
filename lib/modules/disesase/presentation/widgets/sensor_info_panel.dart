import 'package:flutter/material.dart';

/// Panel data sensor yang tampil DI BAWAH penjelasan hasil analisa.
///
/// - Bila memakai data ThingsBoard (historis): menampilkan nilai sensor +
///   peringatan bahwa data TIDAK realtime beserta periode datanya, lalu
///   menawarkan opsi menambahkan data realtime (manual).
/// - Bila pengguna sudah mengisi data manual: menampilkan data manual tersebut
///   dengan label "realtime" dan tanpa peringatan / opsi.
class SensorInfoPanel extends StatelessWidget {
  final Map<String, dynamic>? sensorInfo; // respons /sensor (ThingsBoard)
  final Map<String, dynamic>? manualData; // data yang diisi manual pengguna
  final bool usedManual;
  final bool showOption;
  final bool isBusy;
  final VoidCallback onAddRealtime;
  final VoidCallback onDismissOption;
  final Color primaryColor;

  const SensorInfoPanel({
    Key? key,
    required this.sensorInfo,
    required this.manualData,
    required this.usedManual,
    required this.showOption,
    required this.isBusy,
    required this.onAddRealtime,
    required this.onDismissOption,
    required this.primaryColor,
  }) : super(key: key);

  // Label + satuan untuk key data manual
  static const Map<String, List<String>> _labels = {
    'suhu_udara': ['Suhu Udara', '\u00b0C'],
    'kelembaban_udara': ['Kelembaban Udara', '%'],
    'suhu_tanah': ['Suhu Tanah', '\u00b0C'],
    'kelembaban_tanah': ['Kelembaban Tanah', '%'],
    'ph_tanah': ['pH Tanah', 'pH'],
    'nitrogen': ['Nitrogen (N)', 'mg/kg'],
    'fosfor': ['Fosfor (P)', 'mg/kg'],
    'kalium': ['Kalium (K)', 'mg/kg'],
    'intensitas_cahaya': ['Intensitas Cahaya', 'lux'],
    'curah_hujan': ['Curah Hujan', 'mm'],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Judul ──
          Row(
            children: [
              Icon(Icons.sensors, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Data Sensor',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.grey[850],
                ),
              ),
              const Spacer(),
              _sourceBadge(),
            ],
          ),
          const SizedBox(height: 12),

          // ── Peringatan data historis (hanya bila belum pakai manual) ──
          if (!usedManual) _buildWarning(),

          // ── Daftar nilai sensor ──
          _buildSensorValues(),

          // ── Opsi tambah data realtime ──
          if (showOption && !usedManual) ...[
            const SizedBox(height: 14),
            _buildOption(context),
          ],
        ],
      ),
    );
  }

  Widget _sourceBadge() {
    final bool realtime = usedManual;
    final Color c = realtime ? Colors.green : Colors.orange;
    final String txt = realtime ? 'Realtime (input manual)' : 'Historis';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(realtime ? Icons.check_circle : Icons.history,
              size: 13, color: c),
          const SizedBox(width: 4),
          Text(txt,
              style: TextStyle(
                  fontSize: 11, color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildWarning() {
    final periode = sensorInfo?['periode_data'];
    final String msg = (periode != null && periode.toString().isNotEmpty)
        ? 'Penjelasan ini memakai data sensor yang TIDAK realtime. '
            'Data diambil dari periode $periode.'
        : 'Penjelasan ini memakai data sensor yang TIDAK realtime '
            '(data historis stasiun).';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.amber.shade800, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: TextStyle(fontSize: 12, color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorValues() {
    final List<Widget> rows = [];

    if (usedManual) {
      // Tampilkan data manual yang diisi pengguna
      final data = manualData ?? {};
      if (data.isEmpty) {
        rows.add(_emptyText('Tidak ada data manual yang diisi.'));
      } else {
        // Tampilkan dalam urutan label yang sama dengan mode ThingsBoard.
        _labels.forEach((key, label) {
          if (data.containsKey(key) && data[key] != null) {
            rows.add(_valueRow(label[0], '${data[key]} ${label[1]}'.trim()));
          }
        });
      }
    } else {
      // Tampilkan data ThingsBoard memakai LABEL & URUTAN yang SAMA dengan
      // input manual agar tampilan konsisten sebelum & sesudah input.
      final dataLlm = sensorInfo?['data_llm'];
      if (dataLlm is Map && dataLlm.isNotEmpty) {
        _labels.forEach((key, label) {
          if (dataLlm.containsKey(key) && dataLlm[key] != null) {
            rows.add(_valueRow(label[0], '${dataLlm[key]} ${label[1]}'.trim()));
          }
        });
      } else {
        // Fallback lama: detail_status dari /sensor
        final detail = sensorInfo?['detail_status'];
        if (detail is List && detail.isNotEmpty) {
          for (final d in detail) {
            if (d is Map) {
              final name = (d['parameter'] ?? '').toString();
              final nilai = (d['nilai'] ?? '').toString();
              final satuan = (d['satuan'] ?? '').toString();
              rows.add(_valueRow(name, '$nilai $satuan'.trim()));
            }
          }
        } else {
          rows.add(_emptyText('Data sensor tidak tersedia.'));
        }
      }
    }

    return Column(children: rows);
  }

  Widget _valueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyText(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(t,
            style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600])),
      );

  Widget _buildOption(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingin menambahkan data sensor realtime agar penjelasan lebih akurat?',
            style: TextStyle(fontSize: 13, color: Colors.grey[800]),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: isBusy ? null : onDismissOption,
                child: const Text('Tidak'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: isBusy ? null : onAddRealtime,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: isBusy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add, size: 18),
                label: Text(isBusy ? 'Memproses...' : 'Ya, isi data'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
