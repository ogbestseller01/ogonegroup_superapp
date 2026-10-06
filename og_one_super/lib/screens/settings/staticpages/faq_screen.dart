import 'package:flutter/material.dart';

import '../../../config/app_strings.dart';
import '../../../config/app_theme.dart';
import '../../../services/api_service.dart';
import 'static_page_scaffold.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return StaticPageScaffold(
      title: t.faqs,
      loader: ApiService.instance.getFaqs,
      builder: (context, data) => [_FaqList(data: data)],
    );
  }
}

class _Faq {
  final String question;
  final String answer;
  const _Faq(this.question, this.answer);
}

List<_Faq> _parseFaqs(dynamic data) {
  dynamic list = data;
  if (list is Map) {
    list = list.values.firstWhere((v) => v is List, orElse: () => const []);
  }
  if (list is! List) return const [];

  final out = <_Faq>[];
  for (final item in list) {
    if (item is! Map) continue;
    final q = (item['question'] ?? item['title'] ?? '').toString();
    final a = (item['answer'] ?? item['content'] ?? item['body'] ?? '')
        .toString();
    if (q.trim().isEmpty) continue;
    out.add(_Faq(htmlToText(q), htmlToText(a)));
  }
  return out;
}

class _FaqList extends StatefulWidget {
  final dynamic data;
  const _FaqList({required this.data});

  @override
  State<_FaqList> createState() => _FaqListState();
}

class _FaqListState extends State<_FaqList> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = context.t;
    final all = _parseFaqs(widget.data);
    final q = _q.trim().toLowerCase();
    final faqs = q.isEmpty
        ? all
        : all
        .where((f) =>
    f.question.toLowerCase().contains(q) ||
        f.answer.toLowerCase().contains(q))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: cardDecoration(isDark),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            cursorColor: isDark ? AppTheme.secondary : AppTheme.primary,
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: t.searchFaqs,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark ? Colors.white70 : AppTheme.primary,
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (faqs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                all.isEmpty ? t.noFaqs : t.noResults,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ),
          )
        else
          for (final f in faqs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: cardDecoration(isDark),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  type: MaterialType.transparency,
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 4,
                      ),
                      childrenPadding:
                      const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      expandedAlignment: Alignment.centerLeft,
                      shape: const Border(),
                      collapsedShape: const Border(),
                      iconColor:
                      isDark ? AppTheme.secondary : AppTheme.primary,
                      collapsedIconColor:
                      isDark ? Colors.white54 : Colors.grey.shade500,
                      title: Text(
                        f.question,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: isDark ? Colors.white : AppTheme.primary,
                        ),
                      ),
                      children: [
                        Text(
                          f.answer,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.55,
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}