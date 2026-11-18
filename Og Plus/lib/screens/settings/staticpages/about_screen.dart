import 'package:flutter/material.dart';

import '../../../config/app_strings.dart';
import '../../../services/api_service.dart';
import '../../../widgets/page_skeletons.dart';
import 'static_page_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final title = context.t.about;
    return StaticPageScaffold(
      title: title,
      loader: ApiService.instance.getAbout,
      skeleton: const DocumentPageSkeleton(),
      builder: (context, data) => buildDocumentChildren(
        context,
        data,
        fallbackTitle: title,
        icon: Icons.info_outline_rounded,
      ),
    );
  }
}