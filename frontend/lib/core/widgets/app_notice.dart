import 'dart:async';

import 'package:flutter/material.dart';

final _activeNotices = Expando<_NoticeHandle>();

/// Brief feedback that never takes focus or intercepts touches.
/// A new notice replaces the previous one instead of building a queue.
void showAppNotice(BuildContext context, String message) {
  if (!context.mounted || message.trim().isEmpty) return;
  final overlay = Overlay.of(context, rootOverlay: true);
  _activeNotices[overlay]?.dismiss();

  final theme = Theme.of(context);
  late final _NoticeHandle handle;
  final entry = OverlayEntry(
    builder: (context) => _NoticeLifetime(
      onDispose: () => handle.clear(),
      child: Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Semantics(
                    liveRegion: true,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.inverseSurface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onInverseSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  handle = _NoticeHandle(overlay, entry);
  _activeNotices[overlay] = handle;
  overlay.insert(entry);
  handle.timer = Timer(const Duration(seconds: 4), handle.dismiss);
}

class _NoticeHandle {
  _NoticeHandle(this.overlay, this.entry);

  final OverlayState overlay;
  final OverlayEntry entry;
  Timer? timer;
  bool _dismissed = false;

  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    clear();
    entry.remove();
    entry.dispose();
  }

  void clear() {
    timer?.cancel();
    if (identical(_activeNotices[overlay], this)) {
      _activeNotices[overlay] = null;
    }
  }
}

class _NoticeLifetime extends StatefulWidget {
  const _NoticeLifetime({required this.onDispose, required this.child});

  final VoidCallback onDispose;
  final Widget child;

  @override
  State<_NoticeLifetime> createState() => _NoticeLifetimeState();
}

class _NoticeLifetimeState extends State<_NoticeLifetime> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
