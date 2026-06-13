// ═══════════════════════════════════════════════════════
// SCREEN S-04: Profile Setup — 3-step wizard
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/colors.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/mitra_glass_card.dart';
import '../../widgets/mitra_scaffold_backup.dart';
import '../../stores/auth_store.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

const _avatars = [
  '👨‍🎓',
  '👩‍🎓',
  '🦸‍♂️',
  '🦸‍♀️',
  '🕵️‍♂️',
  '🕵️‍♀️',
  '👨‍🚀',
  '👩‍🚀',
  '🥷',
  '🧙‍♀️',
  '👨‍🎤',
  '👩‍🎤'
];

const _classes = [
  'Class 1',
  'Class 2',
  'Class 3',
  'Class 4',
  'Class 5',
  'Class 6',
  'Class 7',
  'Class 8',
  'Class 9',
  'Class 10',
  'Class 11',
  'Class 12'
];
const _states = [
  'Rajasthan',
  'Uttar Pradesh',
  'Bihar',
  'Madhya Pradesh',
  'Maharashtra',
  'Gujarat',
  'Karnataka',
  'Tamil Nadu',
  'Andhra Pradesh',
  'Telangana',
  'West Bengal',
  'Odisha'
];
const _languages = [
  {'code': 'hi', 'label': 'हिंदी', 'name': 'Hindi'},
  {'code': 'en', 'label': 'English', 'name': 'English'},
  {'code': 'ta', 'label': 'தமிழ்', 'name': 'Tamil'},
  {'code': 'te', 'label': 'తెలుగు', 'name': 'Telugu'},
  {'code': 'kn', 'label': 'ಕನ್ನಡ', 'name': 'Kannada'},
  {'code': 'bn', 'label': 'বাংলা', 'name': 'Bengali'},
  {'code': 'mr', 'label': 'मराठी', 'name': 'Marathi'},
  {'code': 'gu', 'label': 'ગુજ.', 'name': 'Gujarati'},
];

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int _step = 0;
  String _lang = 'hi';
  String _avatar = '👨‍🎓';
  String _cls = '';
  String _state = '';
  bool _loading = false;
  bool _isDetectingLocation = false; // ✨ NEW: GPS Loading flag
  late TextEditingController _nameCtrl;

  // ✨ NEW: The Auto-Locator Function
  Future<void> _autoDetectLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty &&
          placemarks.first.administrativeArea != null) {
        // Match the detected state (e.g., "Gujarat") with your dropdown list
        String detected = placemarks.first.administrativeArea!;
        if (_states.contains(detected)) {
          setState(() => _state = detected);
        } else {
          _showAlert('Detected state ($detected) is not in our list yet!');
        }
      }
    } catch (e) {
      _showAlert('Could not detect location: $e');
    } finally {
      setState(() => _isDetectingLocation = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _cls.isEmpty || _state.isEmpty) {
      _showAlert('Please fill all fields');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider)!;

      await FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: '(default)',
      ).collection('users').doc(user.id).update({
        'language_preference': _lang,
        'avatar_emoji': _avatar,
        'full_name': _nameCtrl.text,
        'class_grade': _cls,
        'assigned_state': _state,
      });

      ref.read(authProvider.notifier).updateUser(
            user.copyWith(
              languagePreference: _lang,
              avatarEmoji: _avatar,
              fullName: _nameCtrl.text,
              classGrade: _cls,
              assignedState: _state,
            ),
          );

      // ✨ INJECTED CODE: Lock the onboarding door permanently
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboardingComplete', true);

      if (mounted) context.go('/student/home');
    } catch (e) {
      debugPrint("🚨 SETUP FIRESTORE ERROR: $e");
      _showAlert('Could not save profile. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAlert(String msg) => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: MitraColors.bgCard,
          content:
              Text(msg, style: const TextStyle(color: MitraColors.textPrimary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK',
                    style: TextStyle(color: MitraColors.saffron)))
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    const stepLabels = ['Language', 'Profile', 'School'];

    return Consumer(
      builder: (context, ref, child) {
        // ✨ RESTORED: Safely fetching the color!
        final activeTheme = ref.watch(themeProvider);
        final activeHighlight = ThemeHelper.getActiveHighlight(activeTheme);

        return MitraScaffold(
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(MitraSpacing.lg),
                child: Row(
                  children: List.generate(
                    stepLabels.length,
                    (i) => Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              if (i > 0)
                                Expanded(
                                    child: Container(
                                        height: 1,
                                        color: i <= _step
                                            ? MitraColors.saffron
                                            : Colors.white.withValues(
                                                alpha: 0.2))), // Updated alpha
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i < _step
                                      ? MitraColors.emerald
                                      : (i == _step
                                          ? MitraColors.saffron
                                          : Colors.white
                                              .withValues(alpha: 0.1)),
                                  border: Border.all(
                                      color: i <= _step
                                          ? Colors.transparent
                                          : Colors.white
                                              .withValues(alpha: 0.3)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  i < _step ? '✓' : '${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Baloo2',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                              ),
                              if (i < stepLabels.length - 1)
                                Expanded(
                                    child: Container(
                                        height: 1,
                                        color: i < _step
                                            ? MitraColors.saffron
                                            : Colors.white
                                                .withValues(alpha: 0.2))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(stepLabels[i],
                              style: TextStyle(
                                  fontFamily: 'Mukta',
                                  fontSize: 11,
                                  color: i == _step
                                      ? MitraColors.saffron
                                      : Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(MitraSpacing.lg),
                  child: [
                    _buildLanguageStep(activeHighlight),
                    _buildProfileStep(activeHighlight),
                    _buildSchoolStep(activeHighlight),
                  ][_step],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(MitraSpacing.lg),
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _step--),
                          child: Container(
                            height: 52,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(MitraRadius.pill),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            alignment: Alignment.center,
                            child: const Text('← Back',
                                style: TextStyle(
                                    fontFamily: 'Baloo2',
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                      ),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _loading
                            ? null
                            : (_step < 2
                                ? () => setState(() => _step++)
                                : _save),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                MitraColors.saffron,
                                MitraColors.saffron.withValues(alpha: 0.7)
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(MitraRadius.pill),
                            boxShadow: [
                              BoxShadow(
                                  color: MitraColors.saffron
                                      .withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)
                              : Text(
                                  _step < 2 ? 'Continue →' : 'Get Started! →',
                                  style: const TextStyle(
                                      fontFamily: 'Baloo2',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Colors.white),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageStep(Color activeHighlight) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Your Language',
              style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white)),
          const SizedBox(height: MitraSpacing.lg),
          Wrap(
            spacing: MitraSpacing.sm,
            runSpacing: MitraSpacing.sm,
            children: _languages.map((l) {
              final selected = _lang == l['code'];
              return MitraGlassCard(
                title: l['label']!,
                isSelected: selected,
                activeColor: MitraColors.saffron,
                onTap: () => setState(() => _lang = l['code']!),
              );
            }).toList(),
          ),
        ],
      );

  Widget _buildProfileStep(Color activeHighlight) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose Your Avatar',
              style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white)),
          const SizedBox(height: MitraSpacing.md),
          Wrap(
            spacing: MitraSpacing.sm,
            runSpacing: MitraSpacing.sm,
            children: _avatars
                .map((e) => GestureDetector(
                      onTap: () => setState(() => _avatar = e),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _avatar == e
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(MitraRadius.sm),
                          border: Border.all(
                              color: _avatar == e
                                  ? MitraColors.saffron
                                  : Colors.white.withValues(alpha: 0.15),
                              width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(e, style: const TextStyle(fontSize: 28)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: MitraSpacing.lg),
          const Text('Your Name',
              style: TextStyle(
                  fontFamily: 'Mukta',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.white70,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(fontFamily: 'Mukta', color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Full name',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MitraRadius.sm),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.2))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MitraRadius.sm),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.2))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MitraRadius.sm),
                  borderSide:
                      const BorderSide(color: MitraColors.saffron, width: 1.5)),
            ),
          ),
        ],
      );

  Widget _buildSchoolStep(Color activeHighlight) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Class',
              style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white)),
          const SizedBox(height: MitraSpacing.md),
          Wrap(
            spacing: MitraSpacing.sm,
            runSpacing: MitraSpacing.sm,
            children: _classes.map((c) {
              return MitraGlassCard(
                title: c,
                isSelected: _cls == c,
                activeColor: MitraColors.saffron,
                onTap: () => setState(() => _cls = c),
              );
            }).toList(),
          ),
          const SizedBox(height: MitraSpacing.lg),

          // ✨ NEW: Strict Auto-Detect Location Card (Dropdown Completely Removed)
          const Text('Your State',
              style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white)),
          const SizedBox(height: MitraSpacing.sm),

          GestureDetector(
            // Prevent tapping if it's already loading
            onTap: _isDetectingLocation ? null : _autoDetectLocation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                // Glows with your theme color when successfully detected
                color: _state.isNotEmpty
                    ? MitraColors.saffron.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(MitraRadius.md),
                border: Border.all(
                  color: _state.isNotEmpty
                      ? MitraColors.saffron
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _state.isNotEmpty ? Icons.check_circle : Icons.my_location,
                    color: _state.isNotEmpty
                        ? MitraColors.saffron
                        : Colors.white70,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _state.isNotEmpty
                              ? 'Location Verified'
                              : 'Location Required',
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: 12,
                            color: _state.isNotEmpty
                                ? MitraColors.saffron
                                : Colors.white54,
                          ),
                        ),
                        Text(
                          _state.isNotEmpty
                              ? _state
                              : 'Tap to auto-detect state',
                          style: const TextStyle(
                            fontFamily: 'Baloo2',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Show loading spinner OR the 'Update' text depending on state
                  if (_isDetectingLocation)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else if (_state.isNotEmpty)
                    TextButton(
                      onPressed: _autoDetectLocation,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('UPDATE',
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          )),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
}
