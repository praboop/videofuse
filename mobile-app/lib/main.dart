import 'package:flutter/material.dart';

import 'frame_selection_screen.dart';
import 'merge_videos_screen.dart';
import 'screens/processing_screens.dart';

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
        MergeVideosScreen.routeName: (_) => const MergeVideosScreen(),
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
      appBar: AppBar(
        toolbarHeight: 72,
        title: Text(
          'VideoFuse',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.78),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VideoFuse',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Simple tools for everyday video work.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(
                        alpha: 0.88,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Video utilities',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            UtilityActionTile(
              icon: Icons.image_outlined,
              title: 'Extract a frame',
              subtitle: 'Choose and save a frame from any video',
              onTap: () {
                Navigator.of(
                  context,
                ).pushNamed(ExtractLastFrameScreen.routeName);
              },
            ),
            const SizedBox(height: 12),
            UtilityActionTile(
              icon: Icons.video_collection_outlined,
              title: 'Merge videos',
              subtitle: 'Join multiple clips into one video',
              onTap: () {
                Navigator.of(context).pushNamed(MergeVideosScreen.routeName);
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
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 27),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: theme.colorScheme.outline,
              ),
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
    return const MediaSelectionScreen(
      title: 'Extract Frame',
      icon: Icons.image_outlined,
      minimumFiles: 1,
    );
  }
}
