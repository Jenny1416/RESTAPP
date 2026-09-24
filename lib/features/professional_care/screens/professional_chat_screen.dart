import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/core/utils/app_toast.dart';
import 'package:rest/features/professional_care/models/professional_care_models.dart';
import 'package:rest/features/professional_care/services/chat_socket_service.dart';
import 'package:rest/features/professional_care/services/professional_care_service.dart';
import 'package:rest/features/professional_care/widgets/professional_widgets.dart';

class ProfessionalChatScreen extends StatefulWidget {
  const ProfessionalChatScreen({
    super.key,
    required this.psychologist,
    required this.assignmentApproved,
    this.initialChat,
    this.readOnly = false,
  });

  final Psychologist psychologist;
  final bool assignmentApproved;
  final ProfessionalChat? initialChat;
  final bool readOnly;

  @override
  State<ProfessionalChatScreen> createState() => _ProfessionalChatScreenState();
}

class _ProfessionalChatScreenState extends State<ProfessionalChatScreen> {
  final _service = ProfessionalCareService();
  final _socketService = ChatSocketService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  ProfessionalChat? _chat;
  List<ProfessionalMessage> _messages = const [];
  Timer? _poller;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  bool get _canWrite =>
      !widget.readOnly &&
      widget.assignmentApproved &&
      (_chat?.isActive ?? true);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _poller?.cancel();
    _socketService.disconnect();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!widget.assignmentApproved && widget.initialChat == null) {
      setState(() {
        _loading = false;
        _error =
            'La conversación se habilitará cuando tu solicitud sea aprobada.';
      });
      return;
    }

    try {
      final chat =
          widget.initialChat ??
          await _service.getOrCreateActiveChat(widget.psychologist.id);
      final messages = await _service.getMessages(chat.id);
      if (!mounted) return;
      setState(() {
        _chat = chat;
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom();
      if (_canWrite) {
        _connectSocket(chat.id);
        _poller = Timer.periodic(
          const Duration(seconds: 20),
          (_) => _refreshMessages(silent: true),
        );
      }
    } on ProfessionalCareException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _refreshMessages({bool silent = false}) async {
    final chat = _chat;
    if (chat == null) return;
    try {
      final messages = await _service.getMessages(chat.id);
      if (!mounted) return;
      final changed =
          messages.length != _messages.length ||
          (messages.isNotEmpty &&
              _messages.isNotEmpty &&
              messages.last.id != _messages.last.id);
      if (changed) {
        setState(() => _messages = messages);
        _scrollToBottom();
      }
    } catch (_) {
      if (!silent && mounted) {
        AppToast.error(context, 'No se pudieron actualizar los mensajes.');
      }
    }
  }

  void _connectSocket(int chatId) {
    _socketService.connect(
      chatId: chatId,
      onNewMessage: _onSocketMessage,
      onJoined: () => _refreshMessages(silent: true),
      onError: (message) {
        if (!mounted) return;
        AppToast.error(context, message);
      },
    );
  }

  void _onSocketMessage(Map<String, dynamic> payload) {
    if (!mounted) return;
    final message = ProfessionalMessage.fromJson({
      'id': payload['id'],
      'usuario_id': payload['userId'],
      'mensaje': payload['mensaje'],
      'enviado_en': payload['enviado_en'],
    });
    if (message.id <= 0 || _messages.any((m) => m.id == message.id)) return;
    setState(() => _messages = [..._messages, message]);
    _scrollToBottom();
  }

  Future<void> _send() async {
    final chat = _chat;
    final text = _controller.text.trim();
    if (!_canWrite || chat == null || text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _controller.clear();

    final sentViaSocket =
        _socketService.sendMessage(chatId: chat.id, mensaje: text);
    if (!sentViaSocket) {
      try {
        final message = await _service.sendMessage(chat.id, text);
        if (!mounted) return;
        setState(() => _messages = [..._messages, message]);
        _scrollToBottom();
      } on ProfessionalCareException catch (error) {
        if (!mounted) return;
        _controller.text = text;
        AppToast.error(context, error.message);
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            CarePageHeader(
              title: widget.psychologist.fullName,
              subtitle: widget.readOnly
                  ? 'Conversación finalizada'
                  : 'Atención profesional',
              action: PsychologistAvatar(
                psychologist: widget.psychologist,
                size: 42,
              ),
            ),
            Expanded(child: _buildBody(colors)),
            if (!_loading && _error == null) _buildComposer(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme colors) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return CareEmptyState(
        icon: Icons.lock_clock_rounded,
        title: 'Conversación no disponible',
        message: _error!,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshMessages,
      child: _messages.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 100),
                CareEmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Inicia la conversación',
                  message:
                      'Escribe un mensaje cuando estés listo. Tu conversación queda guardada en el historial.',
                ),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 22.h),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final mine = message.userId == UserSession.userId;
                return _MessageBubble(message: message, mine: mine);
              },
            ),
    );
  }

  Widget _buildComposer(ColorScheme colors) {
    if (!_canWrite) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 18.h),
        padding: EdgeInsets.all(13.w),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: const Text(
          'Esta conversación está disponible solo para consulta.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_sending,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje',
                filled: true,
                fillColor: colors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          IconButton.filled(
            onPressed: _sending ? null : _send,
            style: IconButton.styleFrom(
              backgroundColor: careAccent(context),
              foregroundColor: context.appColors.overlayOnGradient,
              disabledBackgroundColor: careAccent(context).withValues(alpha: 0.5),
            ),
            icon: _sending
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.appColors.overlayOnGradient,
                    ),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final ProfessionalMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 290.w),
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 7.h),
        decoration: BoxDecoration(
          color: mine ? careAccent(context) : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
            bottomLeft: Radius.circular(mine ? 18.r : 4.r),
            bottomRight: Radius.circular(mine ? 4.r : 18.r),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 15.sp,
                height: 1.35,
                color: mine ? appColors.overlayOnGradient : colors.onSurface,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              DateFormat('HH:mm').format(message.sentAt.toLocal()),
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 10.sp,
                color: mine
                    ? appColors.overlayOnGradient.withValues(alpha: 0.7)
                    : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
