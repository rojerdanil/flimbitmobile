import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/header_service.dart';
import '../utlity/DialogHelper.dart'; // 👈 your common dialog helper

class ApiService {
  // Base handler for API responses
  static dynamic _handleResponse(
    http.Response response, {
    BuildContext? context,
  }) {
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded['status'] == 'success') {
        return decoded['result']; // ✅ Return result normally
      } else {
        final message = decoded['message'] ?? 'Unknown API error';

        // 👇 Show dialog only if context is available (UI call)
        if (context != null) {
          DialogHelper.showErrorDialog(context, message);
        }

        // 👇 Still throw so the calling function can handle it if needed
        throw Exception(message);
      }
    } else {
      throw Exception('Request failed: ${response.statusCode}');
    }
  }

  // Generic GET
  static Future<dynamic> get(String url, {BuildContext? context}) async {
    try {
      print("GET → $url");
      final defaultHeaders = await HeaderService.getHeaders();
      final response = await http.get(Uri.parse(url), headers: defaultHeaders);
      return _handleResponse(response, context: context);
    } on http.ClientException catch (e) {
      debugPrint("GET $url → ClientException: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("GET $url → Unexpected error: $e");
      rethrow;
    }
  }

  // Generic POST
  static Future<dynamic> post(
    String url, {
    required Map<String, dynamic> body,
    BuildContext? context,
  }) async {
    try {
      print("POST → $url");
      final defaultHeaders = await HeaderService.getHeaders();

      final response = await http.post(
        Uri.parse(url),
        headers: defaultHeaders,
        body: jsonEncode(body),
      );

      return _handleResponse(response, context: context);
    } catch (e) {
      throw Exception('POST request error: $e');
    }
  }
}
