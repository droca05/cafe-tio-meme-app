import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display / Títulos — Playfair Display
  static TextStyle displayLarge = GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.espresso,
  );

  static TextStyle displayMedium = GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.espresso,
  );

  // Cuerpo / UI — Inter
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.espresso,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.espresso,
  );

  static TextStyle bodyLight = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: AppColors.espresso,
  );

  static TextStyle bodyMedium500 = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.espresso,
  );

  static TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.foam,
  );

  // Labels y chips — Inter 600, uppercase, letter-spacing 0.08em
  static TextStyle label = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.08 * 12,
    color: AppColors.espresso,
  );
}
