// lib/screens/jobs/job_review_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/job.dart';
import '../../providers/job_provider.dart';

/// Opens the review bottom sheet. Returns true when a review was submitted.
Future<bool?> showJobReviewSheet(BuildContext context, Job job) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => JobReviewSheet(job: job),
  );
}

/// Read-only star row.
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 18});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final value = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < value;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled ? Colors.amber : Colors.grey.shade400,
        );
      }),
    );
  }
}

/// Card that shows the submitted review (rating + remark).
class JobReviewCard extends StatelessWidget {
  const JobReviewCard({super.key, required this.review});

  final JobReview review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your review',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: c.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            RatingStars(rating: review.rating, size: 22),
            const SizedBox(width: 8),
            Text(
              review.rating.toStringAsFixed(1),
              style: TextStyle(fontWeight: FontWeight.w700, color: c),
            ),
          ],
        ),
        if (review.comment != null && review.comment!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            review.comment!,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: c.withValues(alpha: 0.85),
            ),
          ),
        ],
      ],
    );
  }
}

class JobReviewSheet extends StatefulWidget {
  const JobReviewSheet({super.key, required this.job});

  final Job job;

  @override
  State<JobReviewSheet> createState() => _JobReviewSheetState();
}

class _JobReviewSheetState extends State<JobReviewSheet> {
  static const List<String> _labels = [
    'Tap a star to rate',
    'Poor',
    'Fair',
    'Good',
    'Very good',
    'Excellent',
  ];

  final TextEditingController _remark = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _remark.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Please select a star rating.');
      return;
    }

    final provider = context.read<JobProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _submitting = true;
      _error = null;
    });

    final ok = await provider.submitReview(
      widget.job.id,
      rating: _rating,
      comment: _remark.text,
    );

    if (!mounted) return;

    if (ok) {
      navigator.pop(true);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Thank you for your review!'),
          backgroundColor: AppTheme.success,
        ));
    } else {
      setState(() {
        _submitting = false;
        _error = provider.error ?? 'Failed to submit review.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_submitting) ...[
                LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: colors.primary,
                  minHeight: 3,
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rate ${widget.job.technicianName}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed:
                    _submitting ? null : () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                [
                  widget.job.serviceName,
                  if (widget.job.jobNumber.isNotEmpty) widget.job.jobNumber,
                ].join(' • '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < _rating;
                  return IconButton(
                    iconSize: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    constraints: const BoxConstraints(),
                    onPressed: _submitting
                        ? null
                        : () => setState(() {
                      _rating = i + 1;
                      _error = null;
                    }),
                    icon: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: filled ? Colors.amber : Colors.grey.shade400,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  _labels[_rating],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _rating == 0
                        ? colors.onSurfaceVariant
                        : colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _remark,
                enabled: !_submitting,
                maxLines: 4,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Remark (optional)',
                  hintText: 'Tell us how the job went…',
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.outline),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: TextStyle(color: colors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.onPrimary,
                  ),
                )
                    : const Text(
                  'Submit review',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _submitting ? null : () => Navigator.pop(context, false),
                child: const Text('Maybe later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}