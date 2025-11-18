import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/header_service.dart';
import '../utlity/DialogHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ✅ Centralized Response Handler
  static dynamic _handleResponse(
    http.Response response, {
    BuildContext? context,
    bool isFullBody = false,
  }) {
    try {
      final decoded = jsonDecode(response.body);

      // 🔹 Always return decoded response if isFullBody = true
      if (isFullBody) return decoded;

      if (response.statusCode == 200) {
        if (decoded['status'] == 'success') {
          return decoded['result'];
        } else {
          final message = decoded['message'] ?? 'Unknown API error';

          // 👇 Show error dialog if context available
          if (context != null) {
            DialogHelper.showErrorDialog(context, message);
          }

          // ⚠️ Instead of throwing, return a structured failure
          return null;
        }
      } else {
        return {
          "status": "failure",
          "message": "HTTP ${response.statusCode}",
          "result": null,
        };
      }
    } catch (e) {
      debugPrint("❌ Response parse error: $e");
      return {
        "status": "failure",
        "message": "Invalid server response",
        "result": null,
      };
    }
  }

  // ✅ GET Request
  static Future<dynamic> get(
    String url, {
    BuildContext? context,
    bool isFullBody = false,
  }) async {
    try {
      print("GET → $url");
      final defaultHeaders = await HeaderService.getHeaders();
      final response = await http.get(Uri.parse(url), headers: defaultHeaders);

      return _handleResponse(
        response,
        context: context,
        isFullBody: isFullBody,
      );
    } on http.ClientException catch (e) {
      debugPrint("GET $url → ClientException: ${e.message}");
      return {
        "status": "failure",
        "message": "Network error: ${e.message}",
        "result": null,
      };
    } catch (e) {
      debugPrint("GET $url → Unexpected error: $e");
      return {
        "status": "failure",
        "message": "Unexpected error: $e",
        "result": null,
      };
    }
  }

  static Future<void> setUserTokens(Map<String, dynamic> data) async {
    if (data != null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('auth_token', data['accessToken']);
      prefs.setString('refresh_Token', data['refreshToken']);

      ;
    }
  }

  static Future<bool> isUserDataAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber');
    final deviceId = prefs.getString('deviceId');

    // ✅ Return true only if both exist
    return phoneNumber != null && deviceId != null;
  }

  // ✅ POST Request
  static Future<dynamic> post(
    String url, {
    required Map<String, dynamic> body,
    BuildContext? context,
    bool isFullBody = false,
  }) async {
    try {
      print("POST → $url");
      final defaultHeaders = await HeaderService.getHeaders();

      final response = await http.post(
        Uri.parse(url),
        headers: defaultHeaders,
        body: jsonEncode(body),
      );

      return _handleResponse(
        response,
        context: context,
        isFullBody: isFullBody,
      );
    } catch (e) {
      debugPrint("POST $url → Unexpected error: $e");
      return {
        "status": "failure",
        "message": "Unexpected error: $e",
        "result": null,
      };
    }
  }

  static Future<Map<String, dynamic>?> uploadFile(
    String url,
    File file, {
    Map<String, String>? headers,
    String fieldName = "file", // the key expected by backend
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, file.path),
      );

      // Add headers if any
      if (headers != null) {
        request.headers.addAll(headers);
      }
      final defaultHeaders = await HeaderService.getHeaders();

      request.headers.addAll(defaultHeaders);

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return response.body.isNotEmpty
            ? Map<String, dynamic>.from(jsonDecode(response.body))
            : {};
      } else {
        throw Exception("Failed to upload file: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error uploading file: $e");
    }
  }

  static Future<Map<String, dynamic>?> uploadFileBytes(
    String url,
    Uint8List bytes, {
    String fileName = "file.png",
    String fieldName = "file",
    Map<String, String>? headers,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add the bytes as MultipartFile
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: fileName,
          contentType: null, // optional, backend may accept without it
        ),
      );

      // Add headers if provided
      if (headers != null) {
        request.headers.addAll(headers);
      }
      final defaultHeaders = await HeaderService.getHeaders();
      // Send request
      request.headers.addAll(defaultHeaders);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return response.body.isNotEmpty
            ? Map<String, dynamic>.from(jsonDecode(response.body))
            : {};
      } else {
        throw Exception("Failed to upload file: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error uploading file: $e");
    }
  }
}
