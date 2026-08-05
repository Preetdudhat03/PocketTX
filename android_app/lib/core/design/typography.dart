// ─────────────────────────────────────────────
// PocketTX Design System – Typography Tokens
// Uses Geist font (bundled) matching EdgeTX/RC transmitter aesthetic
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const String fontFamily = 'Geist';
  static const String fontFamilyMono = 'monospace'; // for channel values/logs

  // Scale
  static const double displayLg = 48.0;
  static const double display = 40.0;
  static const double h1 = 32.0;
  static const double h2 = 24.0;
  static const double h3 = 20.0;
  static const double h4 = 18.0;
  static const double h5 = 16.0;
  static const double bodyLg = 16.0;
  static const double body = 14.0;
  static const double bodySm = 13.0;
  static const double label = 12.0;
  static const double labelSm = 11.0;
  static const double caption = 10.0;

  // Line heights (factor)
  static const double lineHeightTight = 1.1;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;

  // Letter spacing
  static const double trackingTight = -0.5;
  static const double trackingNormal = 0.0;
  static const double trackingWide = 0.5;
  static const double trackingWidest = 1.5;

  // Font weights
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Pre-built TextStyles
  static TextStyle displayLgStyle({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: displayLg,
        fontWeight: bold,
        letterSpacing: trackingTight,
        height: lineHeightTight,
        color: color,
      );

  static TextStyle h1Style({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: h1,
        fontWeight: bold,
        letterSpacing: trackingTight,
        height: lineHeightTight,
        color: color,
      );

  static TextStyle h2Style({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: h2,
        fontWeight: semiBold,
        letterSpacing: trackingTight,
        color: color,
      );

  static TextStyle h3Style({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: h3,
        fontWeight: semiBold,
        color: color,
      );

  static TextStyle h4Style({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: h4,
        fontWeight: medium,
        color: color,
      );

  static TextStyle bodyLgStyle({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: bodyLg,
        fontWeight: regular,
        height: lineHeightRelaxed,
        color: color,
      );

  static TextStyle bodyStyle({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: body,
        fontWeight: regular,
        height: lineHeightNormal,
        color: color,
      );

  static TextStyle labelStyle({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: label,
        fontWeight: medium,
        letterSpacing: trackingWide,
        color: color,
      );

  static TextStyle captionStyle({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: caption,
        fontWeight: regular,
        letterSpacing: trackingWide,
        color: color,
      );

  /// Monospace style for channel values, PWM readings, and log entries
  static TextStyle monoStyle({
    double? fontSize,
    FontWeight? weight,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: fontFamilyMono,
        fontSize: fontSize ?? body,
        fontWeight: weight ?? regular,
        color: color,
      );

  /// All-caps label style for transmitter controls
  static TextStyle controlLabelStyle({Color? color}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: labelSm,
        fontWeight: bold,
        letterSpacing: trackingWidest,
        color: color,
      );
}
