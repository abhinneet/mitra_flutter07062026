import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

class BackgroundDictionaryLoader {
  static final BackgroundDictionaryLoader _instance =
      BackgroundDictionaryLoader._internal();
  final dio = Dio();
  bool _isDownloading = false;

  BackgroundDictionaryLoader._internal();
  factory BackgroundDictionaryLoader() => _instance;

  Future<String> getDictionaryPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/dictionary.json';
  }

  Future<bool> isDictionaryDownloaded() async {
    final path = await getDictionaryPath();
    return File(path).existsSync();
  }

  /// Silent background download - no UI feedback
  Future<void> downloadInBackground() async {
    // Prevent multiple concurrent downloads
    if (_isDownloading) return;
    _isDownloading = true;

    try {
      final exists = await isDictionaryDownloaded();

      if (exists) {
        debugPrint('✅ Dictionary already cached locally');
        _isDownloading = false;
        return;
      }

      debugPrint('📥 Starting silent dictionary download...');

      final path = await getDictionaryPath();
      final url =
          'https://raw.githubusercontent.com/abhinneet/project_essentials/4e8631d680f40f8a1fe2647bc08908ddb1fe4313/dictionary.json';

      // Download with timeout
      await dio.download(
        url,
        path,
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 10),
        ),
      );

      final fileSize = await File(path).length();
      debugPrint(
          '✅ Dictionary cached (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB)');
    } catch (e) {
      debugPrint(
          'ℹ️ Background download issue (will retry on next app start): $e');
    } finally {
      _isDownloading = false;
    }
  }

  Future<String?> loadDictionary() async {
    try {
      final path = await getDictionaryPath();
      final file = File(path);

      if (file.existsSync()) {
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint('❌ Load error: $e');
    }
    return null;
  }

  Future<void> deleteDictionary() async {
    try {
      final path = await getDictionaryPath();
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
        debugPrint('🗑️ Dictionary deleted');
      }
    } catch (e) {
      debugPrint('❌ Delete error: $e');
    }
  }
}
