// Utilitas untuk menampilkan nama penyakit yang rapi (tanpa underscore)
// dan mengganti token nama kelas mentah di dalam teks (saran/chat).

const Map<String, String> kDiseaseLabels = {
  'bacterial_leaf_blight': 'Hawar Daun Bakteri',
  'bacterial_leaf_streak': 'Garis Daun Bakteri',
  'bacterial_panicle_blight': 'Hawar Malai Bakteri',
  'brown_spot': 'Bercak Coklat',
  'dead_heart': 'Sundep (Dead Heart)',
  'downy_mildew': 'Bulai (Downy Mildew)',
  'healthy': 'Sehat',
  'hispa': 'Hispa',
  'leaf_blast': 'Blas Daun',
  'leaf_smut': 'Api-api Daun (Leaf Smut)',
  'neck_blast': 'Blas Leher Malai',
  'sheath_blight': 'Hawar Pelepah',
  'tungro': 'Tungro',
  'harvest_stage': 'Siap Panen',
};

/// Ubah nama kelas mentah (mis. "neck_blast") menjadi label rapi.
/// Jika tidak ada di peta, underscore diganti spasi + huruf awal kapital.
String formatDiseaseName(String raw) {
  final key = raw.trim().toLowerCase();
  if (kDiseaseLabels.containsKey(key)) return kDiseaseLabels[key]!;
  final cleaned = key.replaceAll('_', ' ').trim();
  if (cleaned.isEmpty) return raw;
  return cleaned
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// Ganti semua token nama kelas mentah yang muncul di dalam teks
/// (mis. "...(neck_blast)") dengan label rapi, tanpa merusak kata lain.
String beautifyDiseaseText(String text) {
  var result = text;
  kDiseaseLabels.forEach((raw, label) {
    final re = RegExp('\\b' + RegExp.escape(raw) + '\\b', caseSensitive: false);
    result = result.replaceAll(re, label);
  });
  return result;
}
