import 'package:flutter/foundation.dart';
import 'package:rest/core/config/api_config.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

typedef ChatMessageHandler = void Function(Map<String, dynamic> payload);
typedef TypingHandler = void Function(Map<String, dynamic> payload);
typedef SocketStatusHandler = void Function(SocketConnectionStatus status);
typedef SocketErrorHandler = void Function(String message);

enum SocketConnectionStatus { connecting, connected, disconnected, error }

class ChatSocketService {
  io.Socket? _socket;

  void connect({
    required int chatId,
    ChatMessageHandler? onNewMessage,
    TypingHandler? onTyping,
    SocketStatusHandler? onStatusChange,
    SocketErrorHandler? onError,
    VoidCallback? onJoined,
  }) {
    disconnect();

    final token = UserSession.authToken;
    if (token == null || token.isEmpty) {
      onStatusChange?.call(SocketConnectionStatus.error);
      return;
    }

    onStatusChange?.call(SocketConnectionStatus.connecting);

    final socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) {
      // El transporte ya conecto; el backend emite 'authenticated' tras verificar el JWT.
    });

    socket.on('authenticated', (_) {
      onStatusChange?.call(SocketConnectionStatus.connected);
      socket.emit('join_chat', chatId);
    });

    socket.on('joined_chat', (_) {
      onStatusChange?.call(SocketConnectionStatus.connected);
      onJoined?.call();
    });

    socket.on('new_message', (data) {
      if (data is Map) onNewMessage?.call(Map<String, dynamic>.from(data));
    });

    socket.on('user_typing', (data) {
      if (data is Map) onTyping?.call(Map<String, dynamic>.from(data));
    });

    socket.on('error', (data) {
      final message = data is Map
          ? (data['message'] ?? 'Error en la conversación.').toString()
          : 'Error en la conversación.';
      onError?.call(message);
    });

    socket.onDisconnect((_) {
      onStatusChange?.call(SocketConnectionStatus.disconnected);
    });

    socket.onConnectError((_) {
      onStatusChange?.call(SocketConnectionStatus.error);
    });

    socket.onError((_) {
      onStatusChange?.call(SocketConnectionStatus.error);
    });
  }

  bool sendMessage({required int chatId, required String mensaje}) {
    if (_socket?.connected != true) return false;
    _socket?.emit('chat_message', {'chatId': chatId, 'mensaje': mensaje});
    return true;
  }

  void emitTyping({required int chatId, required bool isTyping}) {
    if (_socket?.connected != true) return;
    _socket?.emit('typing', {'chatId': chatId, 'isTyping': isTyping});
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}