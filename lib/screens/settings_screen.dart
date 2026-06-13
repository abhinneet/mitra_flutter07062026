import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/theme_provider.dart';
import '../widgets/mitra_glass_card.dart';
import '../widgets/mitra_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTheme = ref.watch(themeProvider);
    final activeHighlight = ThemeHelper.getActiveHighlight(activeTheme);

    return MitraScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'App Settings',
          style: TextStyle(
              fontFamily: 'Baloo2',
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance',
              style: TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose your preferred visual theme. This will apply to all screens instantly.',
              style: TextStyle(fontFamily: 'Mukta', color: Colors.white70),
            ),
            const SizedBox(height: 24),

            // List out all 5 themes using your existing Glass Card
            Expanded(
              child: ListView.separated(
                itemCount: MitraTheme.values.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final themeOption = MitraTheme.values[index];

                  return MitraGlassCard(
                    title: ThemeHelper.getThemeName(themeOption),
                    isSelected: activeTheme == themeOption,
                    activeColor: activeHighlight,
                    onTap: () {
                      // ✨ THIS LINE CHANGES THE GLOBAL THEME INSTANTLY ✨
                      ref.read(themeProvider.notifier).setTheme(themeOption);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
