import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/responsive.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const Color _darkBlue = Color(0xFF1F3A68);
  static const Color _primaryBlue = Color(0xFF4A8FCB);

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Phone: same image background as before.
            // Web/tablet: gradient, so the portrait image isn't cropped/zoomed
            // on a large landscape screen.
            if (wide)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: context.appColors.heroGradient,
                ),
              )
            else
              Image.asset(
                'assets/images/splash_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    gradient: context.appColors.heroGradient,
                  ),
                ),
              ),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                // FittedBox: however small the window is, the whole content
                // stays visible on one page (no scrolling, no clipping).
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _SplashContent(wide: wide),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({required this.wide});

  final bool wide;

  static const Color _darkBlue = SplashScreen._darkBlue;
  static const Color _primaryBlue = SplashScreen._primaryBlue;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: _primaryBlue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withAlpha(89),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.local_shipping_rounded,
            size: wide ? 72 : 64.w,
            color: Colors.white,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          'Delivery\nOperations\nCompanion',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: wide ? 40 : 32.sp,
            height: 1.2,
            color: _darkBlue,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          AppConstants.tagline,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: wide ? 16 : 13.sp,
            color: _darkBlue.withAlpha(191),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        const CircularProgressIndicator(color: _primaryBlue),
        SizedBox(height: AppSpacing.sm),
        Text(
          'Getting things ready...',
          style: GoogleFonts.inter(
            fontSize: wide ? 14 : 12.sp,
            color: _darkBlue.withAlpha(178),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );

    if (!wide) {
      return Padding(
        padding: EdgeInsets.only(bottom: 80.h),
        child: content,
      );
    }

    // Web/tablet: white card panel so the text stays readable on the gradient.
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: content,
    );
  }
}