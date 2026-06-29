import 'package:al_qari/widgets/gradient_background_widget.dart';
import 'package:flutter/material.dart';

class OnboardingBackground extends StatelessWidget {
  final Widget child;
  final List<Widget> decorations;

  const OnboardingBackground({
    super.key,
    required this.child,
    required this.decorations,
  });

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Container(
        decoration: const BoxDecoration(),
        child: Stack(
          children: [
            ...decorations,
            Align(alignment: Alignment.center, child: child),
          ],
        ),
      ),
    );
  }
}
