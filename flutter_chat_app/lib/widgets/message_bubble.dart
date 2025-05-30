import 'package:flutter/material.dart';
import '../models/message_model.dart';
import 'package:intl/intl.dart'; // 需要添加 intl 包: flutter pub add intl

class MessageBubble extends StatelessWidget {
  final UIMessage message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final isServerBroadcast = message.senderId == 'SERVER_BROADCAST';
    final theme = Theme.of(context);

    if (isServerBroadcast) {
      return Center(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 8.0),
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.blueGrey[100],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: Colors.blueGrey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        elevation: 1.5,
        color: isMe
            ? theme.colorScheme.primary.withOpacity(0.9)
            : theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
            bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
          ),
        ),
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMe)
                Text(
                  message.senderId,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isMe ? Colors.white70 : theme.colorScheme.primary,
                  ),
                ),
              SizedBox(height: !isMe ? 4 : 0),
              Text(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 5),
              Text(
                DateFormat('HH:mm').format(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withOpacity(0.7)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
