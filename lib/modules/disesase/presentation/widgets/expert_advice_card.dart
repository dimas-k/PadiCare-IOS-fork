import 'package:flutter/material.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/utils/disease_label.dart';
import 'markdown_text.dart';

class ExpertAdviceCard extends StatelessWidget {
  final String advice;
  final Color primaryColor;
  final Color accentColor;

  const ExpertAdviceCard({
    Key? key,
    required this.advice,
    required this.primaryColor,
    required this.accentColor,
  }) : super(key: key);

  Widget _buildFormattedExpertAdvice(String rawAdvice) {
    // Rapikan nama kelas mentah (mis. neck_blast -> Blas Leher Malai)
    final advice = beautifyDiseaseText(rawAdvice);

    final List<Widget> widgets = [];
    final List<String> lines = advice.split('\n');

    final bodyStyle = TextStyle(
      color: Colors.grey[800],
      fontSize: 13,
      height: 1.45,
    );
    final bulletStyle = TextStyle(
      color: Colors.grey[700],
      fontSize: 13,
      height: 1.45,
    );

    bool isHeadingLine(String t) {
      // Baris judul: diapit ** atau diawali ** dan diakhiri **/**:
      if (t.startsWith('**')) {
        final withoutColon = t.endsWith(':') ? t.substring(0, t.length - 1) : t;
        return withoutColon.endsWith('**');
      }
      // Baris judul lama berbasis emoji
      return RegExp(r'^[\u{1F9A0}\u{1F3E0}\u{1F4A1}\u{1F441}\u26A0\u{1F527}\u{1F48A}\u{1F6E1}\u{1F33E}\u{1F6A8}].*:$', unicode: true)
          .hasMatch(t);
    }

    String stripHeading(String t) {
      var s = t.trim();
      if (s.endsWith(':')) s = s.substring(0, s.length - 1);
      s = s.replaceAll('**', '').trim();
      return s;
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      if (isHeadingLine(line)) {
        widgets.add(Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(width: 4, color: primaryColor)),
          ),
          child: Text(
            stripHeading(line),
            style: TextStyle(
              color: primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        ));
        continue;
      }

      final bulletMatch = RegExp(r'^[-*\u2022]\s+(.*)$').firstMatch(line);
      final numberMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(line);

      if (bulletMatch != null || numberMatch != null) {
        final content =
            bulletMatch != null ? bulletMatch.group(1)! : numberMatch!.group(2)!;
        widgets.add(Container(
          padding: const EdgeInsets.only(left: 16, right: 8, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 7, right: 8),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(children: parseInlineMarkdown(content, bulletStyle)),
                ),
              ),
            ],
          ),
        ));
        continue;
      }

      // Paragraf biasa (dengan dukungan **tebal** di tengah kalimat)
      widgets.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text.rich(
          TextSpan(children: parseInlineMarkdown(line, bodyStyle)),
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Saran Ahli Penyuluhan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFormattedExpertAdvice(advice),
        ],
      ),
    );
  }
}
