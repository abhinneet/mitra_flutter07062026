// ═══════════════════════════════════════════════════════
// SCREEN: AR Viewer — mirrors app/ar/[topicId].tsx
// Uses camera + overlays AR placeholder UI.
// Real AR integration: swap for model_viewer_plus or unity_widget
// ═══════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';

class ArViewerScreen extends StatefulWidget {
  final String topicId;
  const ArViewerScreen({super.key, required this.topicId});
  @override
  State<ArViewerScreen> createState() => _ArViewerScreenState();
}

class _ArViewerScreenState extends State<ArViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;
  bool _arStarted = false;

  @override
  void initState() {
    super.initState();
    _scanCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(_scanCtrl);
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera feed placeholder (replace with camera_preview in production)
          Container(color: const Color(0xFF0a0a0a)),

          // AR Frame corners
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
                  onTap: () {
                    // 🚨 The Safe Pop Mechanism
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(
                          '/'); // Failsafe: Teleport them back to the main router
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: MitraColors.bgCard.withValues(alpha: 0.8),
                      shape:
                          BoxShape.circle, // Assuming this is what was cut off!
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
                    _topicName(widget.topicId),
                    style: const TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: MitraColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Point your camera at your textbook page to see the 3D model appear',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: 13,
                        color: MitraColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => _arStarted = !_arStarted),
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: MitraColors.gradientSaffron),
                        borderRadius: BorderRadius.circular(MitraRadius.pill),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _arStarted ? '⏸ Pause AR' : '▶ Start AR Scanning',
                        style: const TextStyle(
                            fontFamily: 'Baloo2',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white),
                      ),
                    ),
                  ),
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
