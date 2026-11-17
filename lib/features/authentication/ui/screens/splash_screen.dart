
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const Color _darkBlue = Color(0xFF1F3A68);
  static const Color _primaryBlue = Color(0xFF4A8FCB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
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
              child: Align(
                alignment: const Alignment(0, -0.25),
                child: Column(
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
                        size: 64.w,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: AppSpacing.lg),

                    Text(
                      'Delivery\nOperations\nCompanion',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 32.sp,
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
                        fontSize: 13.sp,
                        color: _darkBlue.withAlpha(191),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),

                    SizedBox(height: AppSpacing.xl),

                    const CircularProgressIndicator(
                      color: _primaryBlue,
                    ),

                    SizedBox(height: AppSpacing.sm),

                    Text(
                      'Getting things ready...',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: _darkBlue.withAlpha(178),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
