import 'package:flutter/material.dart';
import 'theme.dart';

/// Fond dégradé doux (rose pâle vers blanc) utilisé sur les écrans d'accueil.
class KGradientBg extends StatelessWidget {
  const KGradientBg({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3DDF5), KColors.fond, Colors.white],
        ),
      ),
      child: child,
    );
  }
}

/// Logo : silhouette au turban + nom de l'application.
class KLogo extends StatelessWidget {
  const KLogo({super.key, this.hauteur = 64});
  final double hauteur;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/silhouette.png', height: hauteur),
        const SizedBox(width: 12),
        ShaderMask(
          shaderCallback: (r) =>
              const LinearGradient(colors: [KColors.violet, KColors.rose]).createShader(r),
          child: const Text('Kôrôba',
              style: TextStyle(fontSize: 46, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ],
    );
  }
}
