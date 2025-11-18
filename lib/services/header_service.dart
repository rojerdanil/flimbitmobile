import 'package:shared_preferences/shared_preferences.dart';

class HeaderService {
  // For now hardcoded (later read from SharedPreferences)
  static Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();

    // Read dynamic values from local storage
    final token =
        prefs.getString('auth_token') ??
        'o0M/jsNngfJSeNMxoHJ7JtgCez+8Thv9imp3DL2oDNYusPGR3d8j92q71KZGVFM8610eHNecNCUa/EnJeUz6RzYThC8MWqhMGyMGRiboJO9aBV3usXD/eMSKgJVaW+FmBhN0YB6fZk9heIg7GnBzNDsVd/9meKjSM+BodePzBTpuW0xkLNvGVLZjN0GM8xxVmLKsX8etY3MgS40Q0wWhXcdAO67mm60oShRqVMWjYjQ=';
    final phoneNumber = prefs.getString('phoneNumber') ?? '';
    final deviceId = prefs.getString('deviceId') ?? '';
    final deviceType = prefs.getString('deviceType') ?? 'phone';

    /*final token =
        'o0M/jsNngfJSeNMxoHJ7JtgCez+8Thv9imp3DL2oDNYusPGR3d8j92q71KZGVFM8610eHNecNCUa/EnJeUz6RzYThC8MWqhMGyMGRiboJO9aBV3usXD/eMSKgJVaW+FmBhN0YB6fZk9heIg7GnBzNDsVd/9meKjSM+BodePzBTpuW0xkLNvGVLZjN0GM8xxVmLKsX8etY3MgS40Q0wWhXcdAO67mm60oShRqVMWjYjQ=';
    final phoneNumber = '9626814334';
    final deviceId = '12234';
    final deviceType = 'phone'; */

    return {
      'Content-Type': 'application/json',
      'phoneNumber': phoneNumber,
      'X-Device-ID': deviceId,
      'x-device-type': deviceType,
      'Authorization': 'Bearer $token',
    };
  }
}
