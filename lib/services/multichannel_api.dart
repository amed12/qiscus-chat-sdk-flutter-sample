import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qiscus_chat_flutter_sample/services/qiscus_service.dart';

class MultichannelAPI {
  static const String baseUrl = 'https://multichannel.qiscus.com/api/v2/qiscus';
  static const String qismoUrl = 'https://qismo.qiscus.com';

  /// Initiate chat or restore existing room using Qiscus Multichannel API.
  static Future<Map<String, dynamic>> initiateChat({
    required String appId,
    required int channelId,
    required String userId,
    required String name,
    String? avatar,
    Map<String, dynamic>? userProperties,
  }) async {
    final qiscus = QiscusService.instance;
    final nonce = await qiscus.getNonce();

    final response = await http.post(
      Uri.parse('$baseUrl/initiate_chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'app_id': appId,
        'user_id': userId,
        'name': name,
        'avatar': avatar,
        'user_properties': userProperties,
        'channel_id': channelId,
        'nonce': nonce,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['data'] as Map).cast<String, dynamic>();
    } else {
      throw Exception('Failed to initiate chat (${response.statusCode})');
    }
  }

  /// Check whether app is sessional (resolved room creates new room).
  static Future<bool> checkSessional(String appId) async {
    final response = await http.get(
      Uri.parse('$qismoUrl/$appId/get_session'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data']?['is_sessional'] == true;
    }
    return false;
  }
}
