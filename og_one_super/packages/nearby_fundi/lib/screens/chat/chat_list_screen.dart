// lib/screens/chat/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../models/chat_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import 'tabs/conversations_tab.dart';
import 'tabs/updates_tab.dart';

class ChatListScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ChatListScreen({super.key, this.onBack});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _init();
    });
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    final user = auth.user, token = auth.token;
    if (user == null || token == null) return;
    chat.initialize(
      token: token,
      currentUser: ChatUser(id: user.id, name: user.name, email: user.email, phone: user.phone, avatar: user.profilePhoto),
    );
    await chat.refreshConversations();
  }

  void _goHome() {
    if (widget.onBack != null) return widget.onBack!();
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final chat = context.watch<ChatProvider>();
    const titles = ['Chats', 'Archives', 'Updates'];

    return Scaffold(
      backgroundColor: dark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: dark ? const Color(0xFF1F2C34) : AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          // Refined white arrow back
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: _goHome,
        ),
        title: Text(titles[_tab], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: chat.refreshConversations),
        ],
      ),
      body: IndexedStack(index: _tab, children: [
        ConversationsTab(onFindTechnicians: _goHome),
        ConversationsTab(archived: true, onFindTechnicians: _goHome),
        const UpdatesTab(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        height: 64,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: chat.totalUnread > 0,
              label: Text(chat.totalUnread > 99 ? '99+' : '${chat.totalUnread}'),
              backgroundColor: const Color(0xFF25D366),
              child: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            selectedIcon: const Icon(Icons.chat_bubble_rounded),
            label: 'Chats',
          ),
          const NavigationDestination(
            icon: Icon(Icons.archive_outlined),
            selectedIcon: Icon(Icons.archive_rounded),
            label: 'Archives',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: chat.hasNewUpdates,
              smallSize: 9,
              backgroundColor: AppTheme.secondary,
              child: const Icon(Icons.auto_awesome_outlined),
            ),
            selectedIcon: const Icon(Icons.auto_awesome_rounded),
            label: 'Updates',
          ),
        ],
      ),
    );
  }
}