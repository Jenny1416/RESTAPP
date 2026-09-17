import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:rest/core/services/chat_service.dart';
import 'package:rest/features/emotion/screens/chat_screen.dart';
import 'gradient_text.dart';

class ConversacionesScreen extends StatefulWidget {
  const ConversacionesScreen({super.key});

  @override
  State<ConversacionesScreen> createState() => _ConversacionesScreenState();
}

class _ConversacionesScreenState extends State<ConversacionesScreen> {
  final ChatService _chatService = ChatService();

  bool _loading = true;
  String? _error;
  List<ChatSessionSummary> _historial = const [];

  @override
  void initState() {
    super.initState();
    _loadHistorial();
  }

  Future<void> _loadHistorial() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _chatService.fetchHistorialIA();
      if (!mounted) return;
      setState(() {
        _historial = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leadingWidth: 70,
        leading: Center(
          child: Container(
            margin: const EdgeInsets.only(left: 20),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              customBorder: CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(0xFF08B1DD),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back, color: Colors.white, size: 25),
              ),
            ),
          ),
        ),
        title: Container(
          margin: const EdgeInsets.only(left: 10),
          child: GradientText(
            'Conversaciones',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 30.sp),
            gradient: LinearGradient(
              colors: [Color(0xFF0AF3FF), Color(0xFF0419FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: false,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _errorState()
            : _historial.isEmpty
            ? SizedBox.expand(child: Center(child: _emptyState()))
            : ListView(
                children: _historial
                    .map(
                      (h) => _buildConversacionItem(h, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              initialChatId: h.chatId,
                              readOnly: !h.isActive,
                            ),
                          ),
                        );
                      }),
                    )
                    .toList(),
              ),
      ),
    );
  }

  Widget _errorState() {
    return Column(
      children: [
        Text(
          'No se pudo cargar conversaciones',
          style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8.h),
        Text(_error ?? '', textAlign: TextAlign.center),
        SizedBox(height: 12.h),
        ElevatedButton(
          onPressed: _loadHistorial,
          child: const Text('Reintentar'),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Column(
      children: [
        const Icon(Icons.forum_rounded, size: 72, color: Color(0xFF90A4AE)),
        SizedBox(height: 10.h),
        Text(
          'Aun no tienes sesiones con NOA',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontWeight: FontWeight.w700,
            color: Color(0xFF546E7A),
          ),
        ),
      ],
    );
  }

  Widget _buildConversacionItem(ChatSessionSummary item, VoidCallback onTap) {
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(item.ultimaActividad);
    final titulo = item.isActive
        ? 'Sesion activa con NOA'
        : 'Sesion finalizada';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF08B1DD), width: 2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.forum_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '$fecha • ${item.totalMensajes} mensajes\n${item.preview}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
