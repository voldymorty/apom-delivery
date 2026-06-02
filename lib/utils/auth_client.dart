import 'dart:convert';
import 'package:delivery/utils/token_storage.dart';
import 'package:http/http.dart' as http;

class AuthClient {

  static Future<http.Response> postWithAuth(
      String url, Map<String, dynamic> body) async {

    final accessToken = await TokenStorage.getToken();

    return await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> getWithAuth(String url) async {

    final accessToken = await TokenStorage.getToken();

    return await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
  }

  static Future<http.Response> putWithAuth(String url, String body) async {

    final accessToken = await TokenStorage.getToken();

    return await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );
  }

  static Future<http.Response> patchWithAuth(
      String url, Map<String, dynamic> body) async {
    final accessToken = await TokenStorage.getToken();

    return await http.patch(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> deleteWithAuth(
      String url,
      {Map<String, dynamic>? body}) async {

    final accessToken = await TokenStorage.getToken();

    return await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<String?> getAuthToken() async {
    return await TokenStorage.getToken();
  }
}
