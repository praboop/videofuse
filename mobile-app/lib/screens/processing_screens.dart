import 'package:flutter/material.dart';

class ProcessingProgressScreen extends StatelessWidget {
  const ProcessingProgressScreen({super.key});

  static const routeName = '/processing-progress';

  @override
  Widget build(BuildContext context) {
    return const UtilityScreenScaffold(
      title: 'Processing',
      actionLabel: 'Cancel',
      icon: Icons.hourglass_empty,
      showProgress: true,
    );
  }
}

class ExportResultScreen extends StatelessWidget {
  const ExportResultScreen({super.key});

  static const routeName = '/export-result';

  @override
  Widget build(BuildContext context) {
    return const UtilityScreenScaffold(
      title: 'Export Ready',
      actionLabel: 'Share',
      icon: Icons.ios_share_outlined,
    );
  }
}

class UtilityScreenScaffold extends StatelessWidget {
  const UtilityScreenScaffold({
    required this.title,
    required this.actionLabel,
    required this.icon,
    this.showProgress = false,
    super.key,
  });

  final String title;
  final String actionLabel;
  final IconData icon;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Center(
                    child: showProgress
                        ? const SizedBox.square(
                            dimension: 40,
                            child: CircularProgressIndicator(),
                          )
                        : Icon(
                            icon,
                            size: 52,
                            color: theme.colorScheme.primary,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: null,
                icon: Icon(icon),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
