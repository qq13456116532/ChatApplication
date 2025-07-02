import 'dart:convert';
import 'package:http/http.dart' as http;

class GptService {
  final String apiKey;
  final String apiUrl;

  const GptService({required this.apiKey, this.apiUrl = 'https://api.openai.com/v1/chat/completions'});

  Future<String> sendMessage(List<Map<String, String>> messages) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('GPT request failed: ${response.body}');
    }
  }
}
