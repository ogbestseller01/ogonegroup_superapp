// lib/screens/auth/register_flow/register_services_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_routes.dart';
import '../../../providers/service_provider.dart';
import '../../../widgets/register_shell.dart';
import '../../../widgets/service_selector.dart';

class RegisterServicesScreen extends StatefulWidget {
  /// Account data forwarded from step 1 (name / phone / email / photo / etc).
  final Map<String, dynamic> args;

  const RegisterServicesScreen({super.key, required this.args});

  @override
  State<RegisterServicesScreen> createState() => _RegisterServicesScreenState();
}

class _RegisterServicesScreenState extends State<RegisterServicesScreen> {
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _restoreFromArgs();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadServices());
  }

  void _restoreFromArgs() {
    final ids = widget.args['service_ids'];
    if (ids is List) {
      _selected.addAll(ids.whereType<int>());
    }
  }

  Future<void> _loadServices() async {
    if (!mounted) return;
    final sp = context.read<ServiceProvider>();
    if (sp.services.isEmpty) {
      await sp.fetchServices();
    }
  }

  bool get _isValid => _selected.isNotEmpty;

  void _next() {
    if (!_isValid) return;
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.registerLocation,
      arguments: <String, dynamic>{
        ...widget.args,
        'service_ids': _selected.toList(),
      },
    );
  }

  void _back() {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.registerStep1,
      arguments: widget.args,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<ServiceProvider>();
    final p = RegPalette.of(context);

    // Badge label: "Continue · 3" when services are selected
    final nextLabel = _selected.isEmpty
        ? 'Continue'
        : 'Continue · ${_selected.length}';

    return RegisterShell(
      step: 2,
      total: 8,
      title: 'Choose your services',
      subtitle: 'Which services will you offer as a fundi?',
      isLoading: sp.isLoading && sp.services.isEmpty,
      onNext: _isValid ? _next : null,
      nextLabel: nextLabel,
      onBack: _back,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Account summary card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.field,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline_rounded, color: p.link),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.args['name']?.toString() ?? 'Your account',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: p.text,
                        ),
                      ),
                      if ((widget.args['email']?.toString() ?? '').isNotEmpty)
                        Text(
                          widget.args['email'].toString(),
                          style: TextStyle(fontSize: 12, color: p.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: Colors.green.shade600,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          ServiceSelector(
            services: sp.services,
            selectedIds: _selected,
            locale: Localizations.localeOf(context).languageCode,
            loading: sp.isLoading && sp.services.isEmpty,
            onToggle: (id) {
              setState(() {
                _selected.contains(id)
                    ? _selected.remove(id)
                    : _selected.add(id);
              });
            },
            onRetry: _loadServices,
          ),

          // Bottom padding so the last chip isn't glued to the footer
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}