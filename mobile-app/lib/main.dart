import 'package:flutter/material.dart';

void main() {
  runApp(const VideoFuseApp());
}

class VideoFuseApp extends StatelessWidget {
  const VideoFuseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VideoFuse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0E7C7B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8F8),
        useMaterial3: true,
      ),
      routes: {
        ExtractLastFrameScreen.routeName: (_) => const ExtractLastFrameScreen(),
        StitchVideosScreen.routeName: (_) => const StitchVideosScreen(),
        ProcessingProgressScreen.routeName: (_) =>
            const ProcessingProgressScreen(),
        ExportResultScreen.routeName: (_) => const ExportResultScreen(),
      },
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('VideoFuse'), centerTitle: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Video utilities',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            UtilityActionTile(
              icon: Icons.image_outlined,
              title: 'Extract Last Frame',
              onTap: () {
                Navigator.of(
                  context,
                ).pushNamed(ExtractLastFrameScreen.routeName);
              },
            ),
            const SizedBox(height: 12),
            UtilityActionTile(
              icon: Icons.video_collection_outlined,
              title: 'Stitch Videos',
              onTap: () {
                Navigator.of(context).pushNamed(StitchVideosScreen.routeName);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class UtilityActionTile extends StatelessWidget {
  const UtilityActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class ExtractLastFrameScreen extends StatelessWidget {
  const ExtractLastFrameScreen({super.key});

  static const routeName = '/extract-last-frame';

  @override
  Widget build(BuildContext context) {
    return const UtilityScreenScaffold(
      title: 'Extract Last Frame',
      actionLabel: 'Select Video',
      icon: Icons.image_outlined,
    );
  }
}

class StitchVideosScreen extends StatelessWidget {
  const StitchVideosScreen({super.key});

  static const routeName = '/stitch-videos';

  @override
  Widget build(BuildContext context) {
    return const UtilityScreenScaffold(
      title: 'Stitch Videos',
      actionLabel: 'Select Clips',
      icon: Icons.video_collection_outlined,
    );
  }
}

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
