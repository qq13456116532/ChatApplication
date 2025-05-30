// lib/widgets/connection_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class ConnectionBar extends StatefulWidget {
  const ConnectionBar({Key? key}) : super(key: key);

  @override
  _ConnectionBarState createState() => _ConnectionBarState();
}

class _ConnectionBarState extends State<ConnectionBar> {
  late TextEditingController _urlController;
  late TextEditingController _userIdController;

  @override
  void initState() {
    super.initState();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _urlController = TextEditingController(text: chatProvider.serverUrl);
    _userIdController = TextEditingController(text: chatProvider.userId);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final theme = Theme.of(context);
    final bool isConnected = chatProvider.isConnected;
    final bool isLoading = chatProvider.isConnecting;
    final String? connectionError =
        chatProvider.connectionErrorMessage; // Get the error message

    return Container(
      padding: const EdgeInsets.all(12.0),
      color: theme.colorScheme.surface.withOpacity(0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _urlController,
                  enabled: !isConnected && !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'ws://localhost:8008/ws',
                    prefixIcon: Icon(Icons.link),
                  ),
                  onChanged: isLoading || isConnected
                      ? null
                      : (value) => chatProvider.setServerUrl(value),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _userIdController,
                  enabled: !isConnected && !isLoading,
                  decoration: InputDecoration(
                    labelText: 'Your User ID',
                    hintText: 'user123',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  onChanged: isLoading || isConnected
                      ? null
                      : (value) => chatProvider.setUserId(value),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton.icon(
                icon: Icon(
                  isLoading
                      ? Icons.hourglass_empty
                      : (isConnected ? Icons.cloud_off : Icons.cloud_queue),
                ),
                label: Text(
                  isLoading
                      ? 'Connecting...'
                      : (isConnected ? 'Disconnect' : 'Connect'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLoading
                      ? Colors.grey
                      : (isConnected
                            ? Colors.orangeAccent
                            : theme.colorScheme.primary),
                ),
                onPressed: isLoading
                    ? null
                    : () {
                        if (isConnected) {
                          chatProvider.disconnect();
                        } else {
                          chatProvider.connect();
                        }
                      },
              ),
            ],
          ),
          // Status messages
          if (isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Attempting to connect to server...',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!isLoading &&
              isConnected) // Only show if not loading AND connected [cite: 182]
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connected as "${chatProvider.userId}" to ${chatProvider.serverUrl}',
                      style: TextStyle(color: Colors.green[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          // New: Display connection error message
          if (!isLoading && !isConnected && connectionError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      connectionError,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        // fontWeight: FontWeight.bold, // Optional: make it bolder
                      ),
                      textAlign: TextAlign.center,
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
