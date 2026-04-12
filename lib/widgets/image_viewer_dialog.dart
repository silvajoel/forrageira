import 'package:flutter/material.dart';

Future<void> showImageViewerDialog({
  required BuildContext context,
  required Widget child,
  String? title,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final theme = Theme.of(context);

      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 960,
            maxHeight: 760,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title ?? 'Visualizacao da imagem',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  padding: const EdgeInsets.all(12),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5,
                    child: Center(child: child),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.zoom_in,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Use pinca ou scroll para ampliar a imagem.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
