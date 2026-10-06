import 'package:flutter/material.dart';

import '../../../config/app_strings.dart';
import '../../../services/api_service.dart';
import 'static_page_scaffold.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final title = context.t.termsConditions;
    return StaticPageScaffold(
      title: title,
      loader: ApiService.instance.getTerms,
      builder: (context, data) => buildDocumentChildren(
        context,
        data,
        fallbackTitle: title,
        icon: Icons.description_outlined,
      ),
    );
  }
}