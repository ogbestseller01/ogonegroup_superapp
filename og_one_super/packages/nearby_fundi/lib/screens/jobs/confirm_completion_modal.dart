// lib/screens/jobs/confirm_completion_modal.dart
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class ConfirmCompletionModal extends StatefulWidget {
  const ConfirmCompletionModal({super.key, required this.jobId});

  final int jobId;

  static Future<bool?> show(BuildContext context, int jobId) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfirmCompletionModal(jobId: jobId),
    );
  }

  @override
  State<ConfirmCompletionModal> createState() => _ConfirmCompletionModalState();
}

class _ConfirmCompletionModalState extends State<ConfirmCompletionModal> {
  // Add your OTP input and verification logic here
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter Verification Code',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // OTP input fields & verify button
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verify & Complete'),
          ),
        ],
      ),
    );
  }
}