import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_provider.dart';

class MitraScaffold extends ConsumerWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool useSafeArea;

  const MitraScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Automatically fetches the active theme for whatever screen uses this
    final activeTheme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Let the gradient show
      extendBodyBehindAppBar: true,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: ThemeHelper.getBackgroundGradient(activeTheme),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: useSafeArea ? SafeArea(child: body) : body,
      ),
    );
  }
}
