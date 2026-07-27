import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class GlbCacheManager extends CacheManager {
  static const key = 'mitra_glb_cache';
  static final GlbCacheManager instance = GlbCacheManager._();
  GlbCacheManager._()
      : super(Config(
          key,
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects:
              50, // N+5 window — adjust via Remote Config later
        ));
}
