import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final double textSize;
  final Color? backgroundColor;
  final Color? textColor;

  const AppLogo({
    super.key,
    this.size = 50,
    this.showText = true,
    this.textSize = 32,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFF00C7BE),
            borderRadius: BorderRadius.circular(size * 0.3),
            boxShadow: [
              BoxShadow(
                color: (backgroundColor ?? const Color(0xFF00C7BE)).withOpacity(0.3),
                blurRadius: size * 0.2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.3),
            child: Image.asset(
              'assets/images/logos/Dino_logo.png',
              width: size * 0.8,
              height: size * 0.8,
              fit: BoxFit.contain,
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.3),
          Text(
            'Connect',
            style: GoogleFonts.inter(
              fontSize: textSize,
              fontWeight: FontWeight.w900,
              color: textColor ?? Colors.black,
            ),
          ),
        ],
      ],
    );
  }
}

// Small logo variant for headers - Professional version
class AppLogoSmall extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogoSmall({
    super.key,
    this.size = 40,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Professional Logo Container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF00C7BE),
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C7BE).withOpacity(0.3),
                blurRadius: size * 0.15,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.link, // Professional link icon
            size: size * 0.6,
            color: Colors.white,
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.3),
          Text(
            'Connect',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ],
    );
  }
}

// Professional App Icon Widget (Alternative to SVG)
class ProfessionalAppIcon extends StatelessWidget {
  final double size;
  final Color? backgroundColor;

  const ProfessionalAppIcon({
    super.key,
    this.size = 1024, // Standard app icon size
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF00C7BE),
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: size * 0.05,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.handshake, // Professional handshake icon for task marketplace
          size: size * 0.6,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Large logo variant for intro screens
class AppLogoLarge extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;

  const AppLogoLarge({
    super.key,
    this.size = 60,
    this.showText = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppLogo(
      size: size,
      showText: showText,
      textSize: 48,
      textColor: textColor,
    );
  }
} 