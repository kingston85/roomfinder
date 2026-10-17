import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config.dart';

/// Picks photos (already shrunk by image_picker) and uploads them to
/// Cloudinary with an unsigned preset. Works on Android and web.
class PhotoService {
  PhotoService._();
  static final PhotoService instance = PhotoService._();

  final _picker = ImagePicker();

  /// About 1280 px wide at 70% quality keeps most photos under ~200 KB.
  Future<List<XFile>> pickPhotos() =>
      _picker.pickMultiImage(maxWidth: 1280, maxHeight: 1280, imageQuality: 70);

  Future<XFile?> takePhoto() => _picker.pickImage(
      source: ImageSource.camera, maxWidth: 1280, maxHeight: 1280, imageQuality: 70);

  Future<String> upload(XFile file) async {
    if (AppConfig.cloudinaryCloud.isEmpty || AppConfig.cloudinaryPreset.isEmpty) {
      throw Exception('Photo upload is not set up (Cloudinary settings missing).');
    }
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloud}/image/upload');
    final bytes = await file.readAsBytes();
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppConfig.cloudinaryPreset
      ..fields['folder'] = 'listings'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name.isEmpty ? 'photo.jpg' : file.name,
      ));
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 200) {
      throw Exception('Photo upload failed (${response.statusCode}). Check your connection.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['secure_url'] as String;
  }
}
