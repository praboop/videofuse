import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/selected_video.dart';

class TimeInputFormatter extends TextInputFormatter {
  const TimeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 6 ? digits.substring(0, 6) : digits;
    final formatted = limited.length <= 2
        ? limited
        : limited.length <= 4
        ? '${limited.substring(0, 2)}:${limited.substring(2)}'
        : '${limited.substring(0, 2)}:${limited.substring(2, 4)}:${limited.substring(4)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class FramePair {
  const FramePair(this.first, this.last);
  final String first;
  final String last;
}

class ClipPreviewTile extends StatelessWidget {
  const ClipPreviewTile({
    required this.file,
    required this.icon,
    required this.onRemove,
    required this.frames,
    required this.onSave,
    this.showCustom = false,
    this.onCustom,
    this.cacheProgress,
    super.key,
  });

  final SelectedVideo file;
  final IconData icon;
  final VoidCallback onRemove;
  final FramePair? frames;
  final Future<void> Function(String path, String name) onSave;
  final bool showCustom;
  final VoidCallback? onCustom;
  final int? cacheProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (cacheProgress != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: cacheProgress! < 0
                        ? Tooltip(
                            message: 'Preview cache failed',
                            child: Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.error,
                              size: 22,
                            ),
                          )
                        : Tooltip(
                            message: 'Building preview cache',
                            child: SizedBox.square(
                              dimension: 34,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: cacheProgress! >= 100 ? 1 : null,
                                    strokeWidth: 3,
                                    color: theme.colorScheme.primary,
                                    backgroundColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                  ),
                                  Text(
                                    '${cacheProgress!}%',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close),
                  onPressed: onRemove,
                ),
                const Icon(Icons.drag_handle),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: PreviewBox(
                    label: 'First frame',
                    icon: icon,
                    path: frames?.first,
                    onSave: onSave,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PreviewBox(
                    label: 'Last frame',
                    icon: icon,
                    path: frames?.last,
                    onSave: onSave,
                  ),
                ),
                if (showCustom) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: PreviewBox(
                      label: 'Custom',
                      icon: icon,
                      onTap: onCustom,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PreviewBox extends StatelessWidget {
  const PreviewBox({
    required this.label,
    required this.icon,
    this.path,
    this.onSave,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final String? path;
  final Future<void> Function(String path, String name)? onSave;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 1.25,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 3),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: path == null
                    ? Icon(icon, color: theme.colorScheme.primary, size: 27)
                    : GestureDetector(
                        onTap: () => onSave!(
                          path!,
                          'videofuse_${label.toLowerCase().replaceAll(' ', '_')}.png',
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(path!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
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
