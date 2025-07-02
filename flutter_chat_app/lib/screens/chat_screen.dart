import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/user_list_tile.dart';
import '../widgets/message_bubble.dart';
import '../widgets/connection_bar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // For chat messages

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      context.read<ChatProvider>().sendMessage(_messageController.text);
      _messageController.clear();
      // Scroll to bottom after sending
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Scroll to bottom when messages are updated
    final chatProvider = context.watch<ChatProvider>();
    if (chatProvider.currentChatMessages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 100), // Quicker for incoming
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Go Chat Client'),
        actions: [
          // Optional: Button to show debug log
          IconButton(
            icon: Icon(Icons.bug_report_outlined),
            tooltip: "Show Debug Log",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Debug Log"),
                  content: Container(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: chatProvider.debugLog.length,
                      itemBuilder: (context, index) {
                        return Text(
                          chatProvider.debugLog[index],
                          style: TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Close"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ConnectionBar(),
          Expanded(
            child: Row(
              children: <Widget>[
                // Left Panel: User List
                Container(
                  width: 250, // Fixed width for user list
                  decoration: BoxDecoration(
                    color: theme.canvasColor, // Slightly different background
                    border: Border(
                      right: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Contacts (${chatProvider.availableUsers.length})',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: chatProvider.availableUsers.length,
                          itemBuilder: (context, index) {
                            final userId = chatProvider.availableUsers[index];
                            return UserListTile(userId: userId);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Panel: Chat Area
                Expanded(
                  child: Column(
                    children: <Widget>[
                      // Chat messages area
                      Expanded(
                        child: chatProvider.selectedChatUserId == null
                            ? Center(
                                child: Text(
                                  'Select a user to start chatting.',
                                  style: theme.textTheme.titleMedium,
                                ),
                              )
                            : Container(
                                color: theme
                                    .scaffoldBackgroundColor, // Chat background
                                padding: const EdgeInsets.all(8.0),
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount:
                                      chatProvider.currentChatMessages.length,
                                  itemBuilder: (context, index) {
                                    final message =
                                        chatProvider.currentChatMessages[index];
                                    return MessageBubble(message: message);
                                  },
                                ),
                              ),
                      ),
                      // Message input area
                      if (chatProvider.selectedChatUserId != null &&
                          (chatProvider.isConnected ||
                              chatProvider.selectedChatUserId ==
                                  chatProvider.chatGptUserId))
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Type a message to ${chatProvider.selectedChatUserId}...',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _sendMessage,
                                child: Icon(Icons.send),
                                style: ElevatedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(14),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
