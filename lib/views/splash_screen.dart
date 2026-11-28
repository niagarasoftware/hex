import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: SvgPicture.asset(
            'assets/svg_images/oro_logo.svg',
            width: 260,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}