import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/services/chat_service.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/features/help/screens/help_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.initialChatId, this.readOnly = false});

  final int? initialChatId;
  final bool readOnly;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  bool _sending = false;
  bool _loadingHistory = true;

  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _bootstrapChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapChat() async {
    setState(() {
      _loadingHistory = true;
    });

    try {
      final selectedChatId = widget.initialChatId;

      if (selectedChatId != null && selectedChatId > 0) {
        final historialMensajes = await _chatService.fetchMensajesChat(
          selectedChatId,
        );
        if (!mounted) return;
        setState(() {
          _messages
            ..clear()
            ..addAll(
              historialMensajes
                  .map((m) => ChatMessage(text: m.text, isUser: m.isUser))
                  .toList(),
            );
        });

        if (_messages.isEmpty) {
          await _pushAnimatedWelcome();
        }

        return;
      }

      final historial = await _chatService.fetchHistorialIA();
      final ChatSessionSummary? active = historial
          .cast<ChatSessionSummary?>()
          .firstWhere((h) => h != null && h.isActive, orElse: () => null);

      if (active != null && active.chatId > 0 && active.totalMensajes > 0) {
        final historialMensajes = await _chatService.fetchMensajesChat(
          active.chatId,
        );
        if (!mounted) return;
        setState(() {
          _messages
            ..clear()
            ..addAll(
              historialMensajes
                  .map((m) => ChatMessage(text: m.text, isUser: m.isUser))
                  .toList(),
            );
        });
      } else {
        await _pushAnimatedWelcome();
      }
    } catch (_) {
      await _pushAnimatedWelcome();
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingHistory = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _pushAnimatedWelcome() async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..add(
          ChatMessage(
            text:
                '¡Hola! Soy NOA. Me alegra hablar contigo. ¿Cómo te has sentido hoy?',
            isUser: false,
            animateOnBuild: true,
          ),
        );
    });
  }

  Future<void> _sendMessage() async {
    if (_sending || widget.readOnly) {
      return;
    }

    final texto = _messageController.text.trim();
    if (texto.isEmpty) {
      return;
    }

    setState(() {
      _sending = true;
      _messages.add(ChatMessage(text: texto, isUser: true));
      _messages.add(const ChatMessage(text: '', isUser: false, isTyping: true));
    });
    _messageController.clear();
    _scrollToBottom();

    final contexto = _buildConversationContext();

    try {
      final result = await _chatService.enviarMensajeNOA(
        mensaje: texto,
        contexto: contexto,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _removeTypingBubble();
        _messages.add(ChatMessage(text: result.respuesta, isUser: false));
      });

      _scrollToBottom();

      if (result.requiereSalvavidas) {
        final aviso =
            result.mensajeSistema ??
            'Detectamos una situacion delicada. Te conectaremos con Salvavidas.';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(aviso),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HelpScreen()),
          );
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _removeTypingBubble();
        _messages.add(
          ChatMessage(
            text:
                'No pude responder ahora mismo. Intenta otra vez en unos segundos.',
            isUser: false,
          ),
        );
      });
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  String _buildConversationContext() {
    final recientes = _messages
        .where((m) => !m.isTyping)
        .take(_messages.length)
        .toList();

    final ultimos = recientes.length > 6
        ? recientes.sublist(recientes.length - 6)
        : recientes;

    final historial = ultimos
        .map((m) => '${m.isUser ? 'Usuario' : 'NOA'}: ${m.text}')
        .join(' | ');

    return 'Usuario: ${UserSession.displayName}. Objetivo NOA: amigo virtual cercano, conversacion natural, apoyo emocional y cotidiano. Mantener continuidad con este historial: $historial';
  }

  void _removeTypingBubble() {
    _messages.removeWhere((m) => m.isTyping);
  }

  Future<void> _onStopChatPressed() async {
    // Registrar racha al completar chat con NOA
    await UserSession.registerDailyCompletion();
    try {
      final feedback = await _chatService.detenerSesionIA();
      if (!mounted) return;
      await _showFeedbackSheet(feedback);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo finalizar la sesion en este momento.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showFeedbackSheet(ChatStopFeedback feedback) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final sheetColorScheme = Theme.of(context).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: sheetColorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Retroalimentacion de NOA',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.bold,
                      fontSize: 22.sp,
                      color: sheetColorScheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  feedback.retroalimentacion,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 15.sp,
                    color: sheetColorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Consejos para ti',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w800,
                    color: sheetColorScheme.primary,
                  ),
                ),
                SizedBox(height: 8.h),
                ...feedback.consejos.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• $c',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        color: sheetColorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(this.context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Volver al inicio'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colorScheme),
            _buildChatArea(colorScheme),
            widget.readOnly
                ? _buildReadOnlyNotice(colorScheme)
                : _buildInputArea(colorScheme),
          ],
        ),
      ),
    );
  }

  // Header: antes usaba un Stack con avatar y titulo posicionados de forma
  // independiente (Align topLeft / Align topCenter), lo que podia hacer que
  // se solaparan en pantallas angostas. Ahora es un Row con Expanded, que
  // garantiza que el avatar y el titulo siempre respetan su espacio.
  Widget _buildHeader(ColorScheme colorScheme) {
    final avatarSize = 80.w;
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4ECDC4), width: 4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              image: const DecorationImage(
                image: AssetImage('assets/images/normalrest.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (Rect bounds) => const LinearGradient(
                    colors: [Color(0xFF7DFDFE), Color(0xFF2196F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    '¡Hablemos',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Fredoka',
                      height: 0.9,
                      color: Colors.white,
                    ),
                  ),
                ),
                ShaderMask(
                  shaderCallback: (Rect bounds) => const LinearGradient(
                    colors: [Color(0xFF7DFDFE), Color(0xFF2196F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'un Rato!',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 30.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Fredoka',
                      height: 0.9,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: avatarSize,
            child: widget.readOnly
                ? IconButton(
                    tooltip: 'Volver',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(ColorScheme colorScheme) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF153E75), width: 4),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 60,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: _loadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) =>
                          ChatBubble(message: _messages[index]),
                    ),
            ),
            if (!widget.readOnly)
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _onStopChatPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pause, color: Colors.black, size: 18),
                        SizedBox(width: 6.w),
                        Text(
                          'Detener',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Fredoka',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (widget.readOnly)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    'Historial',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A4C93), Color(0xFF153E75)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(27),
                  ),
                  child: TextField(
                    controller: _messageController,
                    enabled: !_sending,
                    decoration: InputDecoration(
                      hintText: 'Comparte tu mensaje aquí..',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                    style: TextStyle(fontFamily: 'Freeman', fontSize: 16.sp),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 55.w,
              height: 55.h,
              decoration: const BoxDecoration(
                color: Color(0xFF3B2C5E),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 38.w,
                  height: 38.h,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyNotice(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        'Esta sesión con NOA está finalizada y se muestra solo como historial.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isTyping;
  final bool animateOnBuild;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isTyping = false,
    this.animateOnBuild = false,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message.isTyping) {
      return const TypingBubble();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final bubbleBg = message.isUser
        ? colorScheme.primary
        : colorScheme.surfaceContainerHigh;
    final bubbleText = message.isUser
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

    final bubble = Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: bubbleText,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Freeman',
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!message.animateOnBuild) {
      return bubble;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 14),
            child: child,
          ),
        );
      },
      child: bubble,
    );
  }
}

class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key});

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SizedBox(
              width: 56.w,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(3, (index) {
                      final start = index * 0.2;
                      final t = ((_controller.value - start) % 1.0)
                          .clamp(0.0, 1.0)
                          .toDouble();
                      final scale = 0.72 + (0.5 * (1 - (2 * t - 1).abs()));
                      return Transform.scale(
                        scale: scale,
                        child: SizedBox(
                          width: 8.w,
                          height: 8.h,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFF2F9FE8),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
