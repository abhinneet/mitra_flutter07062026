// ═══════════════════════════════════════════════════════
// SCREEN S-04: Profile Setup — 3-step wizard
// Mirrors app/setup.tsx from Expo project
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/colors.dart';
import '../../services/api_service.dart';
import '../../stores/auth_store.dart';

const _avatars  = ['🎒', '🌟', '🔬', '📚', '🏆', '🌍', '🎯', '⚡', '🌱', '🎨'];
const _classes  = ['Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10', 'Class 11'];
const _states   = ['Rajasthan', 'Uttar Pradesh', 'Bihar', 'Madhya Pradesh', 'Maharashtra',
                   'Gujarat', 'Karnataka', 'Tamil Nadu', 'Andhra Pradesh', 'Telangana',
                   'West Bengal', 'Odisha'];
const _languages = [
  {'code': 'hi', 'label': 'हिंदी',    'name': 'Hindi'},
  {'code': 'en', 'label': 'English',  'name': 'English'},
  {'code': 'ta', 'label': 'தமிழ்',   'name': 'Tamil'},
  {'code': 'te', 'label': 'తెలుగు',  'name': 'Telugu'},
  {'code': 'kn', 'label': 'ಕನ್ನಡ',   'name': 'Kannada'},
  {'code': 'bn', 'label': 'বাংলা',   'name': 'Bengali'},
  {'code': 'mr', 'label': 'मराठी',   'name': 'Marathi'},
  {'code': 'gu', 'label': 'ગુજ.',     'name': 'Gujarati'},
];

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int    _step    = 0;
  String _lang    = 'hi';
  String _avatar  = '🎒';
  String _cls     = '';
  String _state   = '';
  bool   _loading = false;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl  = TextEditingController(text: user?.fullName ?? '');
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _cls.isEmpty || _state.isEmpty) {
      _showAlert('Please fill all fields');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider)!;
      await UsersAPI.update(user.id, {
        'language_preference': _lang,
        'avatar_emoji':        _avatar,
        'full_name':           _nameCtrl.text,
        'class_grade':         _cls,
        'assigned_state':      _state,
      });
      ref.read(authProvider.notifier).updateUser(
        user.copyWith(
          languagePreference: _lang,
          avatarEmoji:        _avatar,
          fullName:           _nameCtrl.text,
          classGrade:         _cls,
          assignedState:      _state,
        ),
      );
      if (mounted) context.go('/student/home');
    } catch (_) {
      _showAlert('Could not save profile. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAlert(String msg) => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: MitraColors.bgCard,
      content: Text(msg, style: const TextStyle(color: MitraColors.textPrimary)),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK', style: TextStyle(color: MitraColors.saffron)))],
    ),
  );

  @override
  Widget build(BuildContext context) {
    const stepLabels = ['Language', 'Profile', 'School'];
    return Scaffold(
      backgroundColor: MitraColors.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            // Step bar
            Padding(
              padding: const EdgeInsets.all(MitraSpacing.lg),
              child: Row(
                children: List.generate(stepLabels.length, (i) => Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (i > 0) Expanded(child: Container(height: 1, color: i <= _step ? MitraColors.saffron : MitraColors.border)),
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < _step ? MitraColors.emerald : i == _step ? MitraColors.saffron : MitraColors.bgSurface,
                              border: Border.all(color: i <= _step ? Colors.transparent : MitraColors.border),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              i < _step ? '✓' : '${i + 1}',
                              style: const TextStyle(color: Colors.white, fontFamily: 'Baloo2', fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          if (i < stepLabels.length - 1) Expanded(child: Container(height: 1, color: i < _step ? MitraColors.saffron : MitraColors.border)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(stepLabels[i], style: TextStyle(fontFamily: 'Mukta', fontSize: 11, color: i == _step ? MitraColors.saffron : MitraColors.textMuted)),
                    ],
                  ),
                )),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(MitraSpacing.lg),
                child: [
                  _buildLanguageStep(),
                  _buildProfileStep(),
                  _buildSchoolStep(),
                ][_step],
              ),
            ),

            // Bottom nav
            Padding(
              padding: const EdgeInsets.all(MitraSpacing.lg),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _step--),
                        child: Container(
                          height: 52, margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(MitraRadius.pill),
                            border: Border.all(color: MitraColors.border),
                          ),
                          alignment: Alignment.center,
                          child: const Text('← Back', style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, color: MitraColors.textSecondary)),
                        ),
                      ),
                    ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _loading ? null : (_step < 2 ? () => setState(() => _step++) : _save),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: MitraColors.gradientSaffron),
                          borderRadius: BorderRadius.circular(MitraRadius.pill),
                        ),
                        alignment: Alignment.center,
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : Text(
                                _step < 2 ? 'Continue →' : 'Get Started! →',
                                style: const TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Select Your Language', style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, fontSize: 20, color: MitraColors.textPrimary)),
      const SizedBox(height: MitraSpacing.lg),
      Wrap(
        spacing: MitraSpacing.sm,
        runSpacing: MitraSpacing.sm,
        children: _languages.map((l) {
          final selected = _lang == l['code'];
          return GestureDetector(
            onTap: () => setState(() => _lang = l['code']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? MitraColors.saffron.withOpacity(0.15) : MitraColors.bgCard,
                borderRadius: BorderRadius.circular(MitraRadius.pill),
                border: Border.all(color: selected ? MitraColors.saffron : MitraColors.border, width: 1.5),
              ),
              child: Text(l['label']!, style: TextStyle(fontFamily: 'Mukta', fontWeight: FontWeight.w500, color: selected ? MitraColors.saffron : MitraColors.textSecondary)),
            ),
          );
        }).toList(),
      ),
    ],
  );

  Widget _buildProfileStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Choose Your Avatar', style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, fontSize: 20, color: MitraColors.textPrimary)),
      const SizedBox(height: MitraSpacing.md),
      Wrap(
        spacing: MitraSpacing.sm,
        runSpacing: MitraSpacing.sm,
        children: _avatars.map((e) => GestureDetector(
          onTap: () => setState(() => _avatar = e),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _avatar == e ? MitraColors.saffron.withOpacity(0.15) : MitraColors.bgCard,
              borderRadius: BorderRadius.circular(MitraRadius.sm),
              border: Border.all(color: _avatar == e ? MitraColors.saffron : MitraColors.border, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(e, style: const TextStyle(fontSize: 28)),
          ),
        )).toList(),
      ),
      const SizedBox(height: MitraSpacing.lg),
      const Text('Your Name', style: TextStyle(fontFamily: 'Mukta', fontWeight: FontWeight.w600, fontSize: 12, color: MitraColors.textMuted, letterSpacing: 1)),
      const SizedBox(height: 8),
      TextField(
        controller: _nameCtrl,
        style: const TextStyle(fontFamily: 'Mukta', color: MitraColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Full name',
          hintStyle: const TextStyle(color: MitraColors.textMuted),
          filled: true,
          fillColor: MitraColors.bgCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(MitraRadius.sm), borderSide: const BorderSide(color: MitraColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(MitraRadius.sm), borderSide: const BorderSide(color: MitraColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(MitraRadius.sm), borderSide: const BorderSide(color: MitraColors.saffron, width: 1.5)),
        ),
      ),
    ],
  );

  Widget _buildSchoolStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Your Class', style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, fontSize: 20, color: MitraColors.textPrimary)),
      const SizedBox(height: MitraSpacing.md),
      Wrap(
        spacing: MitraSpacing.sm,
        runSpacing: MitraSpacing.sm,
        children: _classes.map((c) => GestureDetector(
          onTap: () => setState(() => _cls = c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _cls == c ? MitraColors.saffron.withOpacity(0.15) : MitraColors.bgCard,
              borderRadius: BorderRadius.circular(MitraRadius.pill),
              border: Border.all(color: _cls == c ? MitraColors.saffron : MitraColors.border, width: 1.5),
            ),
            child: Text(c, style: TextStyle(fontFamily: 'Mukta', fontWeight: FontWeight.w500, color: _cls == c ? MitraColors.saffron : MitraColors.textSecondary)),
          ),
        )).toList(),
      ),
      const SizedBox(height: MitraSpacing.lg),
      const Text('Your State', style: TextStyle(fontFamily: 'Baloo2', fontWeight: FontWeight.w700, fontSize: 16, color: MitraColors.textPrimary)),
      const SizedBox(height: MitraSpacing.sm),
      Container(
        decoration: BoxDecoration(
          color: MitraColors.bgCard,
          borderRadius: BorderRadius.circular(MitraRadius.sm),
          border: Border.all(color: MitraColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _state.isEmpty ? null : _state,
            isExpanded: true,
            hint: const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Select state', style: TextStyle(color: MitraColors.textMuted))),
            dropdownColor: MitraColors.bgCard,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            style: const TextStyle(color: MitraColors.textPrimary, fontFamily: 'Mukta'),
            items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) { if (v != null) setState(() => _state = v); },
          ),
        ),
      ),
    ],
  );
}
