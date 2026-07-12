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
  // Label khusus untuk hasil gate OOD (gambar bukan tanaman padi)
  'bukan_padi': 'Bukan Tanaman Padi',
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
/// Ubah nama kelas mentah (mis. "neck_blast") menjadi istilah asing yang rapi
/// (mis. "Neck Blast") — underscore jadi spasi + tiap kata huruf awal kapital.
String _englishTermFromRaw(String raw) {
  return raw
      .split('_')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

String beautifyDiseaseText(String text) {
  var result = text;
  // Token mentah diubah ke istilah Inggris (bukan diterjemahkan lagi ke
  // Indonesia) supaya teks dalam kurung berisi nama bahasa lain.
  // Contoh: "Blas Leher Malai (neck_blast)" -> "Blas Leher Malai (Neck Blast)".
  for (final raw in kDiseaseLabels.keys) {
    final english = _englishTermFromRaw(raw);
    final re = RegExp('\\b' + RegExp.escape(raw) + '\\b', caseSensitive: false);
    result = result.replaceAll(re, english);
  }
  return result;
}
