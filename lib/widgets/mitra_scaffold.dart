import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✨ Added Riverpod
// ✨ Adjust this import path if your theme_provider.dart is located elsewhere!
import '../theme/theme_provider.dart';

// 1. ✨ Upgraded to ConsumerWidget so it can listen to your theme engine
class MitraScaffold extends ConsumerWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const MitraScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  // 2. ✨ Added 'WidgetRef ref' to the build method
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 3. ✨ Fetch the active theme and its gradient colors!
    final activeTheme = ref.watch(themeProvider);
    final bgColors = ThemeHelper.getBackgroundGradient(activeTheme);

    return Container(
      decoration: BoxDecoration(
        // 4. ✨ The beautiful gradient is back!
        gradient: LinearGradient(
          colors: bgColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        // THE WATERMARK: Globally injected behind every screen
        image: const DecorationImage(
          image: AssetImage('assets/images/watermark_bg.png'),
          fit: BoxFit.cover, // Ensures it tiles/stretches beautifully
          opacity: 0.05, // adjust opacity 0.05 is 5% opacity
        ),
      ),
      child: Scaffold(
        // 🚨 CRITICAL: Makes the native scaffold invisible so the gradient & watermark shine through
        backgroundColor: Colors.transparent,

        // Passes all your standard UI elements through
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
