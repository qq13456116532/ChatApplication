import 'dart:convert';

// 用于和服务器交互的原始消息结构
class ServerMessage {
  final String command;
  final String data;

  ServerMessage({required this.command, required this.data});

  factory ServerMessage.fromJson(Map<String, dynamic> json) {
    return ServerMessage(
      command: json['command'] as String,
      data: json['data'] as String,
    );
  }

  static ServerMessage fromRawJson(String rawJson) {
    return ServerMessage.fromJson(jsonDecode(rawJson));
  }

  Map<String, dynamic> toJson() {
    return {'command': command, 'data': data};
  }

  stringtoRawJson() => jsonEncode(toJson());
}

// 用于在 UI 中显示的聊天消息结构
class UIMessage {
  final String id; // 唯一ID，可以是消息内容+时间戳等组合
  final String text;
  final String senderId; // "SERVER_BROADCAST" 或 "USER_LIST_UPDATE" 或实际用户ID
  final bool isMe;
  final DateTime timestamp;

  UIMessage({
    required this.text,
    required this.senderId,
    this.isMe = false,
    DateTime? timestamp,
  }) : id =
           '${senderId}_${(timestamp ?? DateTime.now()).millisecondsSinceEpoch}',
       timestamp = timestamp ?? DateTime.now();
}
