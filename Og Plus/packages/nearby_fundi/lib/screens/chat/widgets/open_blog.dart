// lib/screens/chat/widgets/open_blog.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_routes.dart';
import '../../../providers/chat_provider.dart';

/// Opens the technician's blog/status, marks it as seen (removes the ring), refreshes on return.
Future<void> openTechnicianBlog(BuildContext context, int technicianId) async {
  final chat = context.read<ChatProvider>();
  unawaited(chat.markStatusSeen(technicianId)); // optimistic: ring disappears immediately

  // Navigate to the BlogsScreen filtered by this technician
  await Navigator.pushNamed(
    context,
    AppRoutes.blogs,
    arguments: {'technicianId': technicianId},
  );

  unawaited(chat.refreshConversations());
}