import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'screens/chat_screen.dart';
import 'utils/theme.dart'; // Import your theme

void main() {
  // 确保 Windows 桌面支持已初始化 (如果你的 Flutter 版本需要)
  // WidgetsFlutterBinding.ensureInitialized();
  // if (Platform.isWindows) {
  //   // Windows specific setup if any
  // }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatProvider(),
      child: MaterialApp(
        title: 'Flutter Go Chat',
        theme: AppTheme.lightTheme, // 使用自定义主题
        // darkTheme: AppTheme.darkTheme, // (可选) 如果你定义了暗黑主题
        // themeMode: ThemeMode.system, // (可选) 跟随系统设置
        debugShowCheckedModeBanner: false,
        home: ChatScreen(),
      ),
    );
  }
}
