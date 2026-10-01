import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/technician_provider.dart';
import '../../providers/request_provider.dart';

class FundiHomeScreen extends StatefulWidget {
  const FundiHomeScreen({super.key});

  @override
  State<FundiHomeScreen> createState() => _FundiHomeScreenState();
}

class _FundiHomeScreenState extends State<FundiHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TechnicianProvider>().fetchMyProfile();
      context.read<RequestProvider>().loadMyRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final tech = context.watch<TechnicianProvider>().technician;
    final online = tech?.isOnline ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fundi Dashboard', style: TextStyle(color: Colors.white)),
        elevation: 0,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'F',
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Fundi', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(user?.email ?? '', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: online ? AppTheme.success : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    online ? 'Online' : 'Offline',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildTile(
                    icon: Icons.article_rounded,
                    label: 'My Posts',
                    color: AppTheme.primary,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.posts),
                  ),
                  _buildTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Portfolio',
                    color: AppTheme.salat,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.portfolio),
                  ),
                  _buildTile(
                    icon: Icons.list_alt_rounded,
                    label: 'Requests',
                    color: AppTheme.secondaryColor,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.requests),
                  ),
                  _buildTile(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    color: Colors.purple.shade400,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 1,
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}