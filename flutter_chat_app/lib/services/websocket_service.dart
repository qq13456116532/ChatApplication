import 'dart:async';
import 'dart:convert';
import 'dart:io' show WebSocket;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

import '../models/message_model.dart';

class WebSocketService {
  IOWebSocketChannel? _channel;
  final StreamController<ServerMessage> _messagesController =
      StreamController<ServerMessage>.broadcast();
  Function(String)? _onDebugMessage;

  StreamSubscription? _streamSubscription;
  Completer<void>? _connectionCompleter;

  bool _isConnected = false;
  bool _handshakeCompleted = false;

  Stream<ServerMessage> get messages => _messagesController.stream;
  bool get isConnected => _isConnected;

  void _debugPrint(String message) {
    _onDebugMessage?.call("[WebSocketService] $message");
  }

  Future<void> connect(
    String url,
    String userId, {
    Duration timeout = const Duration(seconds: 5),
    Function(String)? onDebugMessage,
  }) async {
    _onDebugMessage = onDebugMessage;
    _debugPrint('Attempting to connect to $url?id=$userId');

    _isConnected = false;
    _handshakeCompleted = false;
    _connectionCompleter = Completer<void>();

    try {
      // 1. 建立 TCP ➜ WebSocket 连接，并自行设置超时。
      final rawSocket = await WebSocket.connect(
        '$url?id=$userId',
      ).timeout(timeout);
      _channel = IOWebSocketChannel(rawSocket);

      // 2. 监听数据流；首次收到任何数据 ➜ 握手成功。
      _streamSubscription = _channel!.stream.listen(
        _handleData,
        onDone: _handleDone,
        onError: _handleError,
      );

      // 3. 等待握手完成或异常。
      await _connectionCompleter!.future;
    } on TimeoutException catch (_) {
      _debugPrint('Connection timed out after ${timeout.inSeconds}s');
      _messagesController.add(
        ServerMessage(command: 'SYSTEM', data: 'Connection Timeout'),
      );
      rethrow;
    } catch (e) {
      _debugPrint('Connection failed: $e');
      _messagesController.add(
        ServerMessage(command: 'SYSTEM', data: 'Connection Failed: $e'),
      );
      rethrow;
    }
  }

  void _handleData(dynamic data) {
    if (!_handshakeCompleted) {
      _handshakeCompleted = true;
      _isConnected = true;
      _debugPrint('Handshake complete.');
      if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
        _connectionCompleter?.complete();
      }
    }

    _debugPrint('Received raw: $data');
    try {
      final serverMessage = ServerMessage.fromRawJson(data as String);
      _messagesController.add(serverMessage);
    } catch (e) {
      _debugPrint('Error parsing message: $e. Raw data: $data');
      _messagesController.add(
        ServerMessage(command: 'PARSE_ERROR', data: 'Error parsing: $data'),
      );
    }
  }

  void _handleDone() {
    _isConnected = false;
    _handshakeCompleted = false;
    _debugPrint('Connection closed by server.');
    _messagesController.add(
      ServerMessage(command: 'SYSTEM', data: 'Disconnected from server'),
    );
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter?.completeError(
        Exception(
          'Connection closed before handshake completed or during operation',
        ),
      );
    }
  }

  void _handleError(error) {
    _isConnected = false;
    _handshakeCompleted = false;
    _debugPrint('Connection error: $error');
    _messagesController.add(
      ServerMessage(command: 'SYSTEM', data: 'Connection Error: $error'),
    );
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter?.completeError(error);
    }
  }

  void sendMessage(String command, String data) {
    if (_channel != null && _isConnected) {
      final message = ServerMessage(command: command, data: data);
      _channel!.sink.add(jsonEncode(message.toJson()));
      _debugPrint('Sent: ${message.toJson()}');
    } else {
      _debugPrint('Cannot send message, not connected or channel is null.');
    }
  }

  Future<void> disconnect() async {
    _debugPrint('Disconnecting manually...');
    await _streamSubscription?.cancel();
    await _channel?.sink.close();

    _streamSubscription = null;
    _channel = null;

    _isConnected = false;
    _handshakeCompleted = false;

    // _connectionCompleter?.completeError(Exception('Disconnected manually'));

    _messagesController.add(
      ServerMessage(command: 'SYSTEM', data: 'Disconnected manually'),
    );
    _debugPrint('Disconnected manually.');
  }

  void dispose() {
    _debugPrint('Disposing WebSocketService...');
    disconnect();
    _messagesController.close();
  }
}
