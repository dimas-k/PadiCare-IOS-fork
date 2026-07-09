import 'package:flutter/material.dart';

/// Parse inline markdown sederhana: **tebal** dan *miring*.
/// Mengembalikan daftar TextSpan yang siap dipakai di RichText/Text.rich.
List<InlineSpan> parseInlineMarkdown(String text, TextStyle baseStyle) {
  final spans = <InlineSpan>[];
  // Cocokkan **bold** (didahulukan) atau *italic*.
  final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
  int last = 0;
  for (final m in regex.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start), style: baseStyle));
    }
    if (m.group(1) != null) {
      spans.add(TextSpan(
        text: m.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      ));
    } else {
      spans.add(TextSpan(
        text: m.group(2),
        style: baseStyle.copyWith(fontStyle: FontStyle.italic),
      ));
    }
    last = m.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: baseStyle));
  }
  if (spans.isEmpty) spans.add(TextSpan(text: text, style: baseStyle));
  return spans;
}

/// Widget teks yang merender markdown ringan (tebal/miring, bullet, penomoran)
/// baris per baris. Dipakai untuk balasan chat.
class MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;

  const MarkdownText({
    Key? key,
    required this.text,
    required this.baseStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (final raw in lines) {
      final line = raw.trimRight();
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Bullet: "- ", "* ", "\u2022 "
      final bulletMatch = RegExp(r'^[-*\u2022]\s+(.*)$').firstMatch(trimmed);
      // Penomoran: "1. "
      final numberMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);

      if (bulletMatch != null || numberMatch != null) {
        final content =
            bulletMatch != null ? bulletMatch.group(1)! : numberMatch!.group(2)!;
        final marker = numberMatch != null ? '${numberMatch.group(1)}.' : '\u2022';
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 1),
                child: Text(marker, style: baseStyle),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(children: parseInlineMarkdown(content, baseStyle)),
                ),
              ),
            ],
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text.rich(
            TextSpan(children: parseInlineMarkdown(trimmed, baseStyle)),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
