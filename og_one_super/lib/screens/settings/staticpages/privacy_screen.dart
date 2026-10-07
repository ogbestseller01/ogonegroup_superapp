import 'package:flutter/material.dart';

import '../../../config/app_strings.dart';
import '../../../services/api_service.dart';
import '../../../widgets/page_skeletons.dart';
import 'static_page_scaffold.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final title = context.t.privacyPolicy;
    return StaticPageScaffold(
      title: title,
      loader: ApiService.instance.getPrivacyPolicy,
      skeleton: const DocumentPageSkeleton(),
      builder: (context, data) => buildDocumentChildren(
        context,
        data,
        fallbackTitle: title,
        icon: Icons.privacy_tip_outlined,
      ),
    );
  }
}