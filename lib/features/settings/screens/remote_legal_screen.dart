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
  late Future<String> _future;
  @override
  void initState() {
    super.initState();
    _future = SettingsService().document(widget.path);
  }

  void _retry() =>
      setState(() => _future = SettingsService().document(widget.path));

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
      body: FutureBuilder<String>(
        future: _future,
        builder: (context, state) {
          if (state.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No fue posible cargar la versión del servidor.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Reintentar'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: widget.fallbackBuilder),
                      ),
                      child: const Text('Ver versión incluida en la app'),
                    ),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(
              state.data ?? '',
              style: GoogleFonts.fredoka(
                fontSize: 15,
                height: 1.45,
                color: colorScheme.onSurface,
              ),
            ),
          );
        },
      ),
    );
  }
}
