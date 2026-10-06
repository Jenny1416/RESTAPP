import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rest/core/services/settings_service.dart';

class RemoteLegalScreen extends StatefulWidget {
  const RemoteLegalScreen({
    super.key,
    required this.title,
    required this.path,
    required this.fallbackBuilder,
  });

  final String title;
  final String path;
  final WidgetBuilder fallbackBuilder;

  @override
  State<RemoteLegalScreen> createState() => _RemoteLegalScreenState();
}

class _RemoteLegalScreenState extends State<RemoteLegalScreen> {
  late final Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = SettingsService()
        .document(widget.path)
        .timeout(const Duration(seconds: 5));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<String>(
      future: _future,
      builder: (context, state) {
        final remoteContent = state.data?.trim() ?? '';

        // Ante error, timeout o contenido vacío se muestra directamente la
        // versión incluida en la app, sin pedir otra acción al usuario.
        if (state.connectionState == ConnectionState.done &&
            (state.hasError || remoteContent.isEmpty)) {
          return widget.fallbackBuilder(context);
        }

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            title: Text(
              widget.title,
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          body: state.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    remoteContent,
                    style: GoogleFonts.fredoka(
                      fontSize: 15,
                      height: 1.45,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
        );
      },
    );
  }
}
