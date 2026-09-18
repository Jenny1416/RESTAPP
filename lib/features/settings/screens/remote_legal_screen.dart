import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rest/core/services/settings_service.dart';

class RemoteLegalScreen extends StatefulWidget {
  const RemoteLegalScreen({super.key, required this.title, required this.path});
  final String title;
  final String path;

  @override
  State<RemoteLegalScreen> createState() => _RemoteLegalScreenState();
}

class _RemoteLegalScreenState extends State<RemoteLegalScreen> {
  late Future<String> _future;
  @override
  void initState() { super.initState(); _future = SettingsService().document(widget.path); }
  void _retry() => setState(() => _future = SettingsService().document(widget.path));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.surface,
    appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(widget.title, style: GoogleFonts.fredoka(fontWeight: FontWeight.w600)),
    ),
    body: FutureBuilder<String>(
      future: _future,
      builder: (context, state) {
        if (state.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (state.hasError) return Center(child: FilledButton(onPressed: _retry, child: const Text('Reintentar')));
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(state.data ?? '', style: GoogleFonts.fredoka(fontSize: 15, height: 1.45)),
        );
      },
    ),
  );
}
