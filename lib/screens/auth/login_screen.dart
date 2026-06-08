// ═══════════════════════════════════════════════════════
// SCREEN S-03: Login — WhatsApp OTP Authentication
// Mirrors app/login.tsx from Expo project
// ═══════════════════════════════════════════════════════

import 'dart:async'; // 🛠️ Added for Timer
import 'package:dio/dio.dart'; // 🛠️ Added for DioException
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../constants/colors.dart';
import '../../services/api_service.dart';
import '../../stores/auth_store.dart';
import '../../models/user.dart';

enum _LoginStep { phone, otp }

enum _Role { student, teacher }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _storage = const FlutterSecureStorage();
  final _phoneCtrl = TextEditingController();
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _otpFocuses = List.generate(6, (_) => FocusNode());

  _LoginStep _step = _LoginStep.phone;
  _Role _role = _Role.student;
  bool _loading = false;
  int _resendTimer = 0;
  Timer? _timer; // 🛠️ BUG-005 FIX: Added proper Timer variable

  // Countdown ticker
  void _startResendTimer() {
    _timer?.cancel(); // 🛠️ BUG-005 FIX: Cancel existing timer
    int countdown = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendTimer = countdown--);
      if (countdown < 0) timer.cancel();
    });
  }

  Future<void> _sendOTP() async {
    final phone = _phoneCtrl.text.trim();
    // 🛠️ BUG-006 FIX: Added strict number validation
    if (phone.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      _showError(
          'Invalid Number', 'Please enter a valid 10-digit mobile number.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthAPI.login('+91$phone', _role.name);
      setState(() => _step = _LoginStep.otp);
      _startResendTimer();
      Future.delayed(const Duration(milliseconds: 300),
          () => _otpFocuses[0].requestFocus());
    } catch (e) {
      // 🚨 ADD THESE TWO LINES 🚨
      print("=========================================");
      print("🚨 RAW API ERROR: $e");
      print("=========================================");

      _showError('Error', _extractMessage(e, 'Failed to send OTP. Try again.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Safety flag to ensure Google is only initialized once
  bool _isGoogleInitialized = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);

    try {
      // 1. Setup the new V7 Google Sign-In instance
      final googleSignIn = GoogleSignIn.instance;

      // 2. Initialize it (Strict requirement in Version 7+)
      if (!_isGoogleInitialized) {
        await googleSignIn.initialize();
        _isGoogleInitialized = true;
      }

      // 3. Open the Google popup and let the user pick an account
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      // 4. Get the Identity Token
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 5. Get the Access Token (They separated this in Version 7)
      final clientAuth = await googleUser.authorizationClient
          .authorizeScopes(['email', 'profile']);

      // 6. Connect to Firebase using both tokens
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: clientAuth.accessToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // 🎉 SUCCESS!
      print("=========================================");
      print("✅ GOOGLE LOGIN SUCCESS!");
      print("👤 Name: ${userCredential.user?.displayName}");
      print("📧 Email: ${userCredential.user?.email}");
      print("=========================================");
    } catch (e) {
      // If they just swipe the Google popup away, ignore it safely
      if (e.toString().toLowerCase().contains('canceled')) {
        print("User closed the Google popup.");
      } else {
        print("🚨 GOOGLE SIGN-IN ERROR: $e");
        _showError('Google Login Failed',
            'Could not sign in with Google. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOTP() async {
    final code = _otpCtrls.map((c) => c.text).join();
    if (code.length != 6) {
      _showError('Incomplete OTP', 'Please enter all 6 digits.');
      return;
    }
    setState(() => _loading = true);
    try {
      final phone = _phoneCtrl.text.trim();
      final res = await AuthAPI.verifyOTP('+91$phone', code, _role.name);
      final data = res.data as Map<String, dynamic>;
      await _storage.write(
          key: 'mitra_access_token', value: data['accessToken'] as String);
      await _storage.write(
          key: 'mitra_refresh_token', value: data['refreshToken'] as String);

      final user = MitraUser.fromJson(data['user'] as Map<String, dynamic>);
      ref.read(authProvider.notifier).setUser(user);

      if (!mounted) return;
      // 🛠️ BUG-007 FIX: Let the router handle redirect logic automatically based on state
      context.go('/');
    } catch (e) {
      _showError('Wrong OTP',
          _extractMessage(e, 'OTP is incorrect. Please try again.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MitraColors.bgCard,
        title:
            Text(title, style: const TextStyle(color: MitraColors.textPrimary)),
        content: Text(message,
            style: const TextStyle(color: MitraColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK',
                  style: TextStyle(color: MitraColors.saffron))),
        ],
      ),
    );
  }

  // 🛠️ BUG-002 FIX: Proper error extraction
  String _extractMessage(Object e, String fallback) {
    if (e is DioException) {
      if (e.response != null && e.response!.data is Map) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data.containsKey('message')) {
          return data['message'] as String? ?? fallback;
        }
        if (data.containsKey('error')) {
          return data['error'] as String? ?? fallback;
        }
      }
      return e.message ?? fallback;
    }
    return fallback;
  }

  @override
  void dispose() {
    _timer?.cancel(); // 🛠️ BUG-005 FIX: Clean up timer when screen closes
    _phoneCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocuses) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MitraColors.bgDeep,
      body: Column(
        children: [
          // ── Top hero art ────────────────────────────
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1a0a3e),
                  Color(0xFF2D1B69),
                  Color(0xFF0a2010)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: MitraColors.gradientSaffron),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🎓', style: TextStyle(fontSize: 36)),
                ),
                const SizedBox(height: 8),
                const Text('Welcome to MITRA',
                    style: TextStyle(
                        fontFamily: 'Baloo2',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: MitraColors.textPrimary)),
                const Text('Sign in to continue learning',
                    style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: 13,
                        color: MitraColors.textMuted)),
              ],
            ),
          ),

          // ── Form area ───────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MitraSpacing.lg),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role selector
                  Row(
                    children: _Role.values
                        .map((r) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    right: r == _Role.student ? 4 : 0,
                                    left: r == _Role.teacher ? 4 : 0),
                                child: GestureDetector(
                                  onTap: () => setState(() => _role = r),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _role == r
                                          ? MitraColors.saffron.withOpacity(0.1)
                                          : MitraColors.bgCard,
                                      borderRadius:
                                          BorderRadius.circular(MitraRadius.sm),
                                      border: Border.all(
                                        color: _role == r
                                            ? MitraColors.saffron
                                            : MitraColors.border,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                            r == _Role.student ? '🎒' : '👩‍🏫',
                                            style:
                                                const TextStyle(fontSize: 18)),
                                        const SizedBox(width: 6),
                                        Text(
                                          r == _Role.student
                                              ? 'Student'
                                              : 'Teacher',
                                          style: TextStyle(
                                            fontFamily: 'Mukta',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                            color: _role == r
                                                ? MitraColors.saffron
                                                : MitraColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: MitraSpacing.lg),

                  if (_step == _LoginStep.phone)
                    ..._buildPhoneStep()
                  else
                    ..._buildOTPStep(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPhoneStep() => [
        const Text('MOBILE NUMBER',
            style: TextStyle(
                fontFamily: 'Mukta',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: MitraColors.textMuted,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: MitraColors.bgCard,
            borderRadius: BorderRadius.circular(MitraRadius.sm),
            border: Border.all(color: MitraColors.border),
          ),
          child: Row(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Row(
                  children: [
                    const Text('🇮🇳', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    const Text('+91',
                        style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 14,
                            color: MitraColors.textPrimary)),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 20, color: MitraColors.border),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 16,
                      color: MitraColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: '10-digit number',
                    hintStyle: TextStyle(color: MitraColors.textMuted),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MitraSpacing.lg),
        _GradientButton(
          label: 'Send OTP →', // Generalized for future SMS integration
          loading: _loading,
          onTap: _sendOTP,
        ),

        const SizedBox(height: 24), // Spacing before the divider

        // --- VISUAL "OR" DIVIDER ---
        Row(
          children: [
            const Expanded(child: Divider(color: MitraColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: MitraColors.textMuted,
                  fontFamily: 'Mukta',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Expanded(child: Divider(color: MitraColors.border)),
          ],
        ),

        const SizedBox(height: 24), // Spacing after the divider

        // --- GOOGLE SIGN-IN BUTTON ---
        OutlinedButton.icon(
          onPressed: _loading ? null : _signInWithGoogle,
          icon: Image.network(
            'https://img.icons8.com/color/48/000000/google-logo.png',
            height: 24,
          ),
          label: const Text(
            'Continue with Google',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MitraColors.textPrimary),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            side: const BorderSide(color: MitraColors.border, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MitraRadius.sm),
            ),
          ),
        ),
      ];

  List<Widget> _buildOTPStep() => [
        Container(
          padding: const EdgeInsets.all(MitraSpacing.md),
          decoration: BoxDecoration(
            color: MitraColors.emerald.withOpacity(0.1),
            borderRadius: BorderRadius.circular(MitraRadius.sm),
            border: Border.all(color: MitraColors.emerald.withOpacity(0.3)),
          ),
          child: Text(
            '💬  OTP sent to +91 ${_phoneCtrl.text.substring(0, 3)}XXXXXXX',
            style: const TextStyle(
                fontFamily: 'Mukta', fontSize: 13, color: MitraColors.emerald),
          ),
        ),
        const SizedBox(height: MitraSpacing.lg),

        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              6,
              (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      width: 46,
                      height: 56,
                      child: TextField(
                        controller: _otpCtrls[i],
                        focusNode: _otpFocuses[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: MitraColors.textPrimary),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(MitraRadius.xs),
                            borderSide: const BorderSide(
                                color: MitraColors.border, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(MitraRadius.xs),
                            borderSide: const BorderSide(
                                color: MitraColors.saffron, width: 1.5),
                          ),
                          filled: true,
                          fillColor: MitraColors.bgCard,
                        ),
                        onChanged: (val) {
                          if (val.isNotEmpty && i < 5)
                            _otpFocuses[i + 1].requestFocus();
                          if (val.isEmpty && i > 0)
                            _otpFocuses[i - 1].requestFocus();
                        },
                      ),
                    ),
                  )),
        ),
        const SizedBox(height: MitraSpacing.lg),

        _GradientButton(
            label: 'Verify & Login →', loading: _loading, onTap: _verifyOTP),
        const SizedBox(height: MitraSpacing.sm),

        Center(
          child: _resendTimer > 0
              ? Text('Resend in ${_resendTimer}s',
                  style: const TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: 12,
                      color: MitraColors.textMuted))
              : TextButton(
                  onPressed: () {
                    setState(() {
                      _step = _LoginStep.phone;
                      for (final c in _otpCtrls) c.clear();
                    });
                  },
                  child: const Text('← Change Number / Resend OTP',
                      style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: 13,
                          color: MitraColors.sky)),
                ),
        ),
      ];
}

// ── Internal gradient button ───────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _GradientButton(
      {required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: MitraColors.gradientSaffron),
            borderRadius: BorderRadius.circular(MitraRadius.pill),
          ),
          alignment: Alignment.center,
          child: loading
              ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)
              : Text(label,
                  style: const TextStyle(
                      fontFamily: 'Baloo2',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white)),
        ),
      );
}
