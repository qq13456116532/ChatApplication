import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class UserListTile extends StatelessWidget {
  final String userId;

  const UserListTile({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final selectedUserId = context
        .watch<ChatProvider>()
        .selectedChatUserId; // Watch for changes

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
        child: Text(
          userId.isNotEmpty ? userId[0].toUpperCase() : '?',
          style: TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        userId,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      selected: userId == selectedUserId,
      onTap: () {
        chatProvider.selectChat(userId);
      },
      // trailing: Badge( //  (需要 material 3 enabled 或 custom badge)
      //   label: Text('3'), // 未读消息数量
      //   isLabelVisible: true,
      // ),
    );
  }
}
