import 'package:flutter/material.dart';
import 'custom_button.dart';
import 'loading_overlay.dart';

/// Shared layout for every registration step: progress bar, title, button.
class RegisterStepScaffold extends StatelessWidget {
  final int step;
  final int total;
  final String title;
  final String subtitle;
  final Widget child;
  final String buttonText;
  final VoidCallback? onNext; // null => button disabled
  final VoidCallback? onBack;
  final bool isLoading;

  const RegisterStepScaffold({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onNext,
    this.onBack,
    this.buttonText = 'Continue',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isLoading) onBack?.call();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Step $step of $total'),
          centerTitle: true,
          elevation: 0,
          leading: onBack == null
              ? null
              : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: isLoading ? null : onBack,
          ),
        ),
        body: LoadingOverlay(
          isLoading: isLoading,
          child: Column(
            children: [
              LinearProgressIndicator(
                value: step / total,
                minHeight: 4,
                backgroundColor: theme.dividerColor.withOpacity(0.3),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      child,
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: CustomButton(
                    text: buttonText,
                    onPressed: onNext ?? () {},
                    isLoading: isLoading,
                    isDisabled: onNext == null || isLoading,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}