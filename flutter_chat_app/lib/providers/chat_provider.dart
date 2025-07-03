import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/websocket_service.dart';
import '../services/gpt_service.dart';
import 'dart:io';

class ChatProvider with ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();
  final String geminiUserId = 'gemini';
  GeminiService? _geminiService;
  final List<Map<String, String>> _geminiHistory = [];

  String _serverUrl = 'ws://localhost:8008/ws';
  String _userId = ''; // Initialize with empty or load from storage
  String? _selectedChatUserId;

  List<String> _onlineUsers = [];
  Map<String, List<UIMessage>> _chatHistories = {};
  List<String> _debugLog = [];

  bool _isConnecting = false; // New state
  String? _connectionErrorMessage;

  // Getters
  List<String> get onlineUsers => _onlineUsers;
  List<String> get availableUsers => [geminiUserId, ..._onlineUsers];
  String? get selectedChatUserId => _selectedChatUserId;
  List<UIMessage> get currentChatMessages =>
      _chatHistories[_selectedChatUserId] ?? [];
  bool get isConnected => _webSocketService.isConnected; // Delegate to service
  bool get isConnecting => _isConnecting; // Getter for new state
  String? get connectionErrorMessage => _connectionErrorMessage;
  String get serverUrl => _serverUrl;
  String get userId => _userId;
  List<String> get debugLog => _debugLog;

  late final String _geminiApiKey;

  ChatProvider() {
    // 启动初始化过程
    _initialize();
  }

  Future<void> _initialize() async {
    // 监听 WebSocket 消息
    _webSocketService.messages.listen(_handleServerMessage);

    try {
      final directory = Directory.current.path;
      final filePath = '$directory/文档/Gemini的api key.txt';

      final file = File(filePath);
      final String apiKey = await file.readAsString();

      _geminiApiKey = apiKey.trim();

      print('读取到的 API Key: $_geminiApiKey');

      // 在这里使用 _geminiApiKey 初始化你的 Gemini 客户端等
    } catch (e) {
      print('读取 API Key 时出错: $e');
    }
  }

  void _addDebugLog(String message) {
    final now = DateTime.now();
    final formattedTimestamp =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    _debugLog.insert(0, "$formattedTimestamp - $message");
    if (_debugLog.length > 100) {
      _debugLog.removeLast();
    }
    notifyListeners();
  }

  void setServerUrl(String url) {
    _serverUrl = url;
    notifyListeners();
  }

  void setUserId(String id) {
    _userId = id;
    notifyListeners();
  }

  void setGptApiKey(String key) {
    _geminiApiKey = key;
    _geminiService = GeminiService(apiKey: _geminiApiKey);
  }

  Future<void> connect() async {
    if (_userId.isEmpty) {
      _addDebugLog("User ID cannot be empty.");
      _connectionErrorMessage = "User ID cannot be empty.";
      notifyListeners();
      return;
    }
    if (_serverUrl.isEmpty) {
      _addDebugLog("Server URL cannot be empty.");
      _connectionErrorMessage = "Server URL cannot be empty."; // Show error
      notifyListeners();
      return;
    }
    if (_isConnecting || isConnected) {
      _addDebugLog("Already connecting or connected.");
      return;
    }

    _isConnecting = true;
    _connectionErrorMessage = null;
    _addDebugLog("Attempting to connect UserID: $_userId to $_serverUrl");
    notifyListeners();

    try {
      // Use the timeout from WebSocketService connect method (default 10s)
      await _webSocketService.connect(
        _serverUrl,
        _userId,
        onDebugMessage: _addDebugLog,
      );
      // If connect completes without error, _webSocketService.isConnected should be true.
      // Actual confirmation of connection often comes with the first message (e.g., welcome or userList).
      if (_webSocketService.isConnected) {
        _addDebugLog("Connection successful (according to WebSocketService).");
      } else {
        _addDebugLog(
          "WebSocketService connect call completed, but not connected. Check logs for errors (e.g. timeout).",
        );
      }
    } catch (e) {
      _addDebugLog("Connection attempt failed in Provider: ${e.toString()}");
      // The SYSTEM message from WebSocketService should have already updated state if error occurred there.
    } finally {
      _isConnecting = false;
      // The isConnected status is now directly from _webSocketService.isConnected
      // _handleServerMessage will also call notifyListeners when messages arrive (or connection status changes)
      notifyListeners();
    }
  }

  void _handleServerMessage(ServerMessage message) {
    _addDebugLog(
      "Provider received: Command: ${message.command}, Data: ${message.data}",
    );

    // If we receive any message, it implies the "connecting" phase is over.
    // However, _isConnecting is more robustly handled in connect() method's finally block.
    // _isConnecting = false; // This might be redundant if connect() handles it well

    switch (message.command) {
      case 'userList':
        _onlineUsers = message.data
            .split(',')
            .where((id) => id.isNotEmpty && id != _userId)
            .toList();
        _addDebugLog("User list updated: $_onlineUsers");
        _connectionErrorMessage = null;

        break;
      case 'brodcastMes':
        final broadcast = UIMessage(
          text: message.data,
          senderId: 'SERVER_BROADCAST',
        );
        _addDebugLog("Broadcast message received: ${message.data}.");
        // Add to current chat or a general system log
        if (_selectedChatUserId != null) {
          _addMessageToHistory(_selectedChatUserId!, broadcast);
        }
        if (!_chatHistories.containsKey('SERVER_BROADCAST')) {
          _chatHistories['SERVER_BROADCAST'] = [];
        }
        _chatHistories['SERVER_BROADCAST']!.add(broadcast);
        break;
      case 'SYSTEM':
        _addDebugLog("System message: ${message.data}");
        if (message.data.contains("Disconnected") ||
            message.data.contains("Connection Error") ||
            message.data.contains("Connection Timeout") ||
            message.data.contains("Connection Failed")) {
          _onlineUsers = [];
          _selectedChatUserId = null;
          // _isConnecting = false; // ensure connecting state is reset on failure
          if (!message.data.contains("Disconnected manually")) {
            _connectionErrorMessage = "Connection is error, Please Check";
            // message.data; // Set error from SYSTEM message
          }
        }
        break;
      case 'PARSE_ERROR':
        _addDebugLog("Message parsing error: ${message.data}");
        break;
      default:
        final senderId = message.command;
        if (senderId == _userId) return;

        final uiMessage = UIMessage(
          text: message.data,
          senderId: senderId,
          isMe: false,
        );
        _addMessageToHistory(senderId, uiMessage);
        _addDebugLog("Message from $senderId: ${message.data}");
        break;
    }
    notifyListeners();
  }

  void _addMessageToHistory(String partnerId, UIMessage message) {
    if (!_chatHistories.containsKey(partnerId)) {
      _chatHistories[partnerId] = [];
    }
    _chatHistories[partnerId]!.add(message);
    notifyListeners(); // Notify after adding message specifically for UI update
  }

  void selectChat(String? userId) {
    _selectedChatUserId = userId;
    _addDebugLog("Selected chat with: $userId");
    notifyListeners();
  }

  String _combineHistory(List<Map<String, String>> history) {
    return history.map((e) => "${e['role']}: ${e['content']}").join('\n');
  }

  Future<void> sendMessage(String text) async {
    if (_selectedChatUserId == null || text.trim().isEmpty) {
      _addDebugLog("Cannot send: No user selected or message empty.");
      return;
    }

    final target = _selectedChatUserId!;
    final trimmed = text.trim();

    final sentMessage = UIMessage(text: trimmed, senderId: _userId, isMe: true);
    _addMessageToHistory(target, sentMessage);
    _addDebugLog("Sent to $target: $trimmed");

    if (target == geminiUserId) {
      if (_geminiService == null) {
        _geminiService = GeminiService(apiKey: _geminiApiKey);
      }
      _geminiHistory.add({'role': 'user', 'content': trimmed});
      try {
        final prompt = _combineHistory(_geminiHistory);
        final reply = await _geminiService!.sendMessage(prompt);

        // final reply = await _geminiService!.sendMessage(_geminiHistory);
        _geminiHistory.add({'role': 'assistant', 'content': reply});
        final gptMsg = UIMessage(
          text: reply,
          senderId: geminiUserId,
          isMe: false,
        );
        _addMessageToHistory(geminiUserId, gptMsg);
      } catch (e) {
        final errMsg = UIMessage(
          text: 'Error: $e',
          senderId: geminiUserId,
          isMe: false,
        );
        _addMessageToHistory(geminiUserId, errMsg);
      }
      return;
    }

    if (!isConnected) {
      _addDebugLog("Cannot send: not connected to server.");
      return;
    }

    _webSocketService.sendMessage(target, trimmed);
  }

  Future<void> disconnect() async {
    _addDebugLog("Disconnecting from provider...");
    await _webSocketService.disconnect(); // now async
    _onlineUsers = [];
    _selectedChatUserId = null;
    _isConnecting = false; // Ensure this is reset
    _connectionErrorMessage = null; // Clear error on manual disconnect

    // _chatHistories.clear(); // Optional
    _addDebugLog("Disconnected from provider.");
    notifyListeners();
  }

  @override
  void dispose() {
    _addDebugLog("Disposing ChatProvider...");
    // _messageSubscription?.cancel(); // Listener in constructor now
    _webSocketService.dispose();
    super.dispose();
  }
}
