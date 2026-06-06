// Shared gradient button widget used across screens
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  final List<Color> gradient;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.loading = false,
    this.onTap,
    this.gradient = MitraColors.gradientSaffron,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(MitraRadius.pill),
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
