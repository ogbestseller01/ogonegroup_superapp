// lib/widgets/service_selector.dart
import 'package:flutter/material.dart';

import '../models/service.dart';
import 'register_shell.dart';

class ServiceSelector extends StatelessWidget {
  final List<Service> services;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;
  final String locale;
  final bool loading;
  final VoidCallback? onRetry;

  const ServiceSelector({
    super.key,
    required this.services,
    required this.selectedIds,
    required this.onToggle,
    required this.locale,
    this.loading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final p = RegPalette.of(context);

    if (loading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: p.field,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: p.field,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text('Could not load services', style: TextStyle(color: p.muted)),
            const SizedBox(height: 8),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Services you offer',
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15, color: p.text)),
        const SizedBox(height: 4),
        Text('Select at least one. Tap to toggle.',
            style: TextStyle(fontSize: 12.5, color: p.muted)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: services.map((s) {
            final sel = selectedIds.contains(s.id);
            return FilterChip(
              label: Text(s.localizedName(locale)),
              selected: sel,
              onSelected: (_) => onToggle(s.id),
              selectedColor: p.link.withOpacity(0.15),
              checkmarkColor: p.link,
              labelStyle: TextStyle(
                color: sel ? p.link : p.text,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                  color: sel
                      ? p.link
                      : Theme.of(context).dividerColor.withOpacity(0.5)),
            );
          }).toList(),
        ),
        if (selectedIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one service',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 12.5),
            ),
          ),
      ],
    );
  }
}