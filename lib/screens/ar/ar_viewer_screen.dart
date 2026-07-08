// ═══════════════════════════════════════════════════════
// SCREEN: AR Viewer — mirrors app/ar/[topicId].tsx
// Uses camera + overlays AR placeholder UI.
// Real AR integration: swap for model_viewer_plus or unity_widget
// ═══════════════════════════════════════════════════════
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../constants/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/telemetry_provider.dart';

class ArViewerScreen extends ConsumerStatefulWidget {
  final String topicId;
  const ArViewerScreen({super.key, required this.topicId});
  @override
  ConsumerState<ArViewerScreen> createState() => _ArViewerScreenState();
}

class _ArViewerScreenState extends ConsumerState<ArViewerScreen>
    with SingleTickerProviderStateMixin {
  final DateTime _arOpenedAt = DateTime.now();
  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;
  bool _arStarted = true; // ✨ Auto-starts the session immediately
  bool _arCompleted = false;
  bool _show3DViewer =
      true; // ✨ Defaults strictly to the 3D Model Viewer on screen
  // Cached in didChangeDependencies so dispose() can use it safely
  // (ref must not be read after the widget is unmounted)
  dynamic _cachedTelemetry;

  @override
  void initState() {
    super.initState();
    _scanCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(_scanCtrl);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedTelemetry = ref.read(telemetryServiceProvider);
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    final durationSeconds = DateTime.now().difference(_arOpenedAt).inSeconds;
    final telemetry = _cachedTelemetry;
    if (telemetry != null) {
      telemetry.logArEnd(
        arId: widget.topicId,
        topicId: widget.topicId,
        moduleTitle: _topicName(widget.topicId),
        durationSeconds: durationSeconds,
        completed: _arStarted || _arCompleted, // ✨ Updated to check completion
        isReplay: false,
        preModuleScore: 0.0,
        postModuleScore: 0.0,
      );
    }
    super.dispose();
  }

  // ✨ THE MAGIC: Forces the OS to bypass webviews and open the AR Camera immediately
  Future<void> _launchDirectAR() async {
    setState(() {
      _arStarted = true;
      _show3DViewer = false; // Close 3D viewer if it was open
    });

    // TODO: Swap this for your Cloudflare R2 URL later: 'https://cdn.mitra.in/models/${widget.topicId}.glb'
    const String glbUrl =
        'https://modelviewer.dev/shared-assets/models/Astronaut.glb';

    if (Platform.isAndroid) {
      // ✨ CRITICAL FIX: The 3D model URL *must* be properly URL-encoded!
      final String encodedUrl = Uri.encodeComponent(glbUrl);
      final String title = Uri.encodeComponent('MITRA 3D Lesson');

      final String arUrl =
          'https://arvr.google.com/scene-viewer/1.0?file=$encodedUrl&mode=ar_only&title=$title';

      try {
        final launched = await launchUrl(Uri.parse(arUrl),
            mode: LaunchMode.externalApplication);
        if (!launched) throw Exception("Intent rejected by OS");
      } catch (e) {
        debugPrint("ARCore failed to launch: $e");

        // ✨ GRACEFUL FALLBACK: Switch to 3D Viewer if AR fails or isn't installed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'AR Camera not supported. Opening 3D model instead.',
                  style: TextStyle(
                      fontFamily: 'Mukta', fontWeight: FontWeight.w600)),
              backgroundColor: MitraColors.crimson,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
          setState(() => _show3DViewer = true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✨ Conditionally show the 3D viewer if the secondary option is chosen
          if (_show3DViewer)
            const ModelViewer(
              backgroundColor: Color(0xFF0a0a0a),
              src: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
              alt: 'A 3D educational model',
              autoRotate: true,
              cameraControls: true,
              disableZoom: false,
            )
          else
            Container(color: const Color(0xFF0a0a0a)),

          // AR Frame corners (Hide if 3D viewer is active)
          if (!_show3DViewer)
            Positioned.fill(
              child: CustomPaint(painter: _ArCornersPainter()),
            ),

          // Scanning line
          if (!_arStarted)
            AnimatedBuilder(
              animation: _scanAnim,
              builder: (ctx, _) => Positioned(
                top: MediaQuery.of(context).size.height * 0.15 +
                    (MediaQuery.of(context).size.height *
                        0.55 *
                        _scanAnim.value),
                left: 40,
                right: 40,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      MitraColors.saffron.withValues(alpha: 0.8),
                      Colors.transparent
                    ]),
                  ),
                ),
              ),
            ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(MitraSpacing.lg),
              child: Row(children: [
                GestureDetector(
                  onTap: () => context.go('/student/ar'),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: MitraColors.bgCard.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: MitraColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: MitraColors.bgCard.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(MitraRadius.pill),
                    border: Border.all(
                        color: MitraColors.saffron.withValues(alpha: 0.5)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.fiber_manual_record,
                        color: MitraColors.saffron, size: 8),
                    SizedBox(width: 6),
                    Text('AR Mode',
                        style: TextStyle(
                            fontFamily: 'Mukta',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: MitraColors.textPrimary)),
                  ]),
                ),
              ]),
            ),
          ),

          // Bottom instruction card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(MitraSpacing.xl),
              decoration: BoxDecoration(
                color: MitraColors.bgCard.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(MitraRadius.lg)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _arCompleted
                        ? 'AR Session Complete! 🎉'
                        : _topicName(widget.topicId),
                    style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: MitraColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _arCompleted
                        ? 'Are you ready to test your knowledge?'
                        : 'Point your camera at your textbook page to see the 3D model appear',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: 13,
                        color: MitraColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  if (!_arCompleted) ...[
                    // 1. PRIMARY: Jump straight to AR Camera
                    GestureDetector(
                      onTap: _launchDirectAR,
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: MitraColors.gradientSaffron),
                          borderRadius: BorderRadius.circular(MitraRadius.pill),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '▶ Launch AR Camera',
                          style: TextStyle(
                              fontFamily: 'Baloo2',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. SECONDARY: View 3D Model on Screen
                    if (!_show3DViewer)
                      GestureDetector(
                        onTap: () => setState(() {
                          _arStarted = true;
                          _show3DViewer = true;
                        }),
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius:
                                BorderRadius.circular(MitraRadius.pill),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '👀 View 3D Model on Screen',
                            style: TextStyle(
                                fontFamily: 'Baloo2',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.white),
                          ),
                        ),
                      ),

                    // 3. FINISH SESSION (Appears once either mode is started)
                    if (_arStarted) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => setState(() {
                          _arStarted = false;
                          _show3DViewer = false;
                          _arCompleted = true;
                        }),
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: MitraColors.emerald.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(MitraRadius.pill),
                            border: Border.all(
                                color:
                                    MitraColors.emerald.withValues(alpha: 0.5)),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '✅ Finish Lesson',
                            style: TextStyle(
                                fontFamily: 'Baloo2',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: MitraColors.emerald),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // COMPLETED STATE: Replay or Quiz
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _arCompleted = false;
                                _show3DViewer = false;
                              });
                              _launchDirectAR(); // Replay jumps straight to AR!
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(MitraRadius.pill),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '🔄 Replay AR',
                                style: TextStyle(
                                    fontFamily: 'Baloo2',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                context.push('/quiz/${widget.topicId}'),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: MitraColors.gradientSaffron),
                                borderRadius:
                                    BorderRadius.circular(MitraRadius.pill),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Take Quiz →',
                                style: TextStyle(
                                    fontFamily: 'Baloo2',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _topicName(String id) {
    const map = {
      'cell-division': 'Cell Division',
      'solar-system': 'Solar System 3D',
      'atom-structure': 'Atom Structure',
      'ancient-rome': 'Ancient Rome',
      'ocean-layers': 'Ocean Layers',
    };
    return map[id] ?? id;
  }
}

class _ArCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MitraColors.saffron
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const margin = 40.0;
    const cornerLen = 24.0;
    const top = 80.0;
    final bottom = size.height * 0.75;

    // Top-left
    canvas.drawLine(const Offset(margin, top + cornerLen),
        const Offset(margin, top), paint);
    canvas.drawLine(const Offset(margin, top),
        const Offset(margin + cornerLen, top), paint);
    // Top-right
    canvas.drawLine(Offset(size.width - margin - cornerLen, top),
        Offset(size.width - margin, top), paint);
    canvas.drawLine(Offset(size.width - margin, top),
        Offset(size.width - margin, top + cornerLen), paint);
    // Bottom-left
    canvas.drawLine(
        Offset(margin, bottom - cornerLen), Offset(margin, bottom), paint);
    canvas.drawLine(
        Offset(margin, bottom), Offset(margin + cornerLen, bottom), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width - margin - cornerLen, bottom),
        Offset(size.width - margin, bottom), paint);
    canvas.drawLine(Offset(size.width - margin, bottom),
        Offset(size.width - margin, bottom - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
