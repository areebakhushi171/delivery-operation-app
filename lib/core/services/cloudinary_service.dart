import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../utils/app_exception.dart';

class CloudinaryService {
  CloudinaryService._();

  static const String cloudName = 'zcpwtn3m';
  static const String uploadPreset = 'delivery_app_unsigned';

  static String get uploadUrl => 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Uploads an image file to Cloudinary under the specified folder path.
  /// Returns the secure_url string upon successful upload.
  static Future<String> uploadImage({
    required File file,
    required String folder,
  }) async {
    try {
      if (!await file.exists()) {
        throw const AppException('Image file does not exist.');
      }

      final length = await file.length();
      if (length > 15 * 1024 * 1024) {
        throw const AppException('Image file is too large (max 15MB).');
      }

      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          return secureUrl;
        } else {
          throw const AppException('Cloudinary response missing secure_url.');
        }
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final message = errorData?['error']?['message'] ??
            'Failed to upload image to Cloudinary (Code ${response.statusCode})';
        throw AppException(message);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Cloudinary upload error: $e');
    }
  }
}
