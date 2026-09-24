import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rest/core/theme/app_colors.dart';

enum ToastType { success, error, warning, info }

class AppToast {
  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _current?.remove();
    _current = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );

    _current = entry;
    overlay.insert(entry);
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: ToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: ToastType.error);

  static void warning(BuildContext context, String message) =>
      show(context, message, type: ToastType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message, type: ToastType.info);
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -1.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();

    Future.delayed(widget.duration, () {
      if (mounted) _dismiss();
    });
  }

  Future<void> _dismiss() async {
    await _ctrl.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  _ToastConfig _configFor(AppColors appColors) {
    switch (widget.type) {
      case ToastType.success:
        return _ToastConfig(
          gradient: LinearGradient(
            colors: [appColors.successFg, appColors.accentTeal],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          icon: Icons.check_circle_rounded,
          label: 'Éxito',
        );
      case ToastType.error:
        return _ToastConfig(
          gradient: LinearGradient(
            colors: [appColors.dangerFg, appColors.warmBadgeFg],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          icon: Icons.error_rounded,
          label: 'Error',
        );
      case ToastType.warning:
        return _ToastConfig(
          gradient: LinearGradient(
            colors: [appColors.goldEnd, appColors.goldStart],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          icon: Icons.warning_rounded,
          label: 'Atención',
        );
      case ToastType.info:
        return _ToastConfig(
          gradient: LinearGradient(
            colors: [appColors.accentBlue, appColors.accentPurple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          icon: Icons.info_rounded,
          label: 'Info',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final cfg = _configFor(appColors);
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: GestureDetector(
              onTap: _dismiss,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: cfg.gradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: appColors.overlayOnGradient.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cfg.icon, color: appColors.overlayOnGradient, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cfg.label,
                              style: GoogleFonts.fredoka(
                                color: appColors.overlayOnGradient.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message,
                              style: GoogleFonts.fredoka(
                                color: appColors.overlayOnGradient,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(
                          Icons.close_rounded,
                          color: appColors.overlayOnGradient.withValues(alpha: 0.7),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastConfig {
  final LinearGradient gradient;
  final IconData icon;
  final String label;
  const _ToastConfig({
    required this.gradient,
    required this.icon,
    required this.label,
  });
}
