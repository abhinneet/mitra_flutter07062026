import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ArCacheService {
  static Future<File?> getCached(String topicId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ar_models/$topicId.glb');
    return file.existsSync() ? file : null;
  }

  static Future<File> save(String topicId, List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/ar_models');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    return File('${folder.path}/$topicId.glb').writeAsBytes(bytes);
  }

  static Future<void> evict(String topicId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ar_models/$topicId.glb');
    if (file.existsSync()) file.deleteSync();
  }
}
