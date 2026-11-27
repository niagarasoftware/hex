import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../widgets/password_input_field.dart';
import '../widgets/phone_input_field.dart';
import '../widgets/continue_button.dart';

import '../../../../utils/constants.dart';
import '../../../../view_models/login_view_model.dart';

class WideLayout extends StatelessWidget {
  final bool isOro, isATel;
  final LoginViewModel viewModel;

  const WideLayout({
    super.key,
    required this.isOro,
    required this.viewModel,
    required this.isATel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildBrandingSection(context),
        _buildAuthenticationFormPanel(context),
      ],
    );
  }

  Widget _buildBrandingSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.85),
              colorScheme.surfaceContainerHighest,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Logo
            if (isOro)
              Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SvgPicture.asset(
                  'assets/svg_images/oro_logo.svg',
                  fit: BoxFit.contain,
                ),
              )
            else
              const SizedBox(height: 50),
            // Center IoT Highlights
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Irrigation ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  AppConstants.appShortContent,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildFeatureChip(
                      icon: Icons.water_drop_outlined,
                      label: 'Smart Water Management',
                    ),
                    _buildFeatureChip(
                      icon: Icons.sensors_outlined,
                      label: 'Real-time Field Telemetry',
                    ),
                    _buildFeatureChip(
                      icon: Icons.science_outlined,
                      label: 'Automated Fertigation Control',
                    ),
                  ],
                ),
              ],
            ),

            // Bottom Footer
            const Row(
              children: [
                Icon(Icons.verified_user_outlined,
                    size: 16, color: Colors.white60),
                SizedBox(width: 8),
                Text(
                  'Enterprise Grade Security & Encryption',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticationFormPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 480,
      height: double.infinity,
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isOro) ...[
                Container(
                  constraints: const BoxConstraints(maxWidth: 240),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    'assets/svg_images/oro_logo.svg',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (isATel) ...[
                const Image(
                  image: AssetImage('assets/png/agritel_logo.png'),
                  height: 52,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to access your smart irrigation controller.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              const PhoneInputField(isWeb: true),
              const SizedBox(height: 18),
              const PasswordInputField(isWeb: true),
              const SizedBox(height: 12),
              if (viewModel.errorMessage.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 18, color: colorScheme.onErrorContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          viewModel.errorMessage,
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              const SizedBox(height: 10),
              const ContinueButton(),
            ],
          ),
        ),
      ),
    );
  }
}
