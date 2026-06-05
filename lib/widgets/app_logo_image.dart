import 'package:flutter/material.dart';
import 'package:ledgixerp/features/company/services/company_service.dart';

class AppLogoImage extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;

  const AppLogoImage({
    super.key,
    required this.width,
    required this.height,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Image.asset(
        'assets/ledgix_logo.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => SizedBox(
          width: width,
          height: height,
          child: const CustomPaint(painter: _LedGixLogoPainter()),
        ),
      ),
    );
  }
}

class CompanyLogoImage extends StatelessWidget {
  final String? logoUrl;
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const CompanyLogoImage({
    super.key,
    required this.logoUrl,
    required this.width,
    required this.height,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final value = logoUrl?.trim();
    if (value == null || value.isEmpty) return _fallbackLogo();

    return Padding(
      padding: padding,
      child: SizedBox(
        width: width,
        height: height,
        child: FutureBuilder<String?>(
          future: CompanyService().resolveLogoUrl(value),
          builder: (context, snapshot) {
            final resolvedUrl = snapshot.data;
            if (resolvedUrl == null || resolvedUrl.isEmpty) {
              return _fallbackLogoContents();
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image.network(
                resolvedUrl,
                width: width,
                height: height,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) =>
                    _fallbackLogoContents(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _fallbackLogo() {
    return Padding(
      padding: padding,
      child: SizedBox(
        width: width,
        height: height,
        child: _fallbackLogoContents(),
      ),
    );
  }

  Widget _fallbackLogoContents() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AppLogoImage(width: width, height: height),
    );
  }
}

class _LedGixLogoPainter extends CustomPainter {
  const _LedGixLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide;
    final dx = (size.width - unit) / 2;
    final dy = (size.height - unit) / 2;

    canvas.save();
    canvas.translate(dx, dy);

    final cyan = Paint()
      ..color = const Color(0xFF4FC3F7)
      ..style = PaintingStyle.fill;
    final blue = Paint()
      ..color = const Color(0xFF0D6EFD)
      ..style = PaintingStyle.fill;
    final cutout = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    Path parallelogram(List<Offset> points) {
      return Path()
        ..moveTo(points[0].dx * unit, points[0].dy * unit)
        ..lineTo(points[1].dx * unit, points[1].dy * unit)
        ..lineTo(points[2].dx * unit, points[2].dy * unit)
        ..lineTo(points[3].dx * unit, points[3].dy * unit)
        ..close();
    }

    canvas.drawPath(
      parallelogram([
        const Offset(0.70, 0.04),
        const Offset(0.18, 0.47),
        const Offset(0.36, 0.61),
        const Offset(0.88, 0.18),
      ]),
      cyan,
    );
    canvas.drawPath(
      parallelogram([
        const Offset(0.38, 0.63),
        const Offset(0.78, 0.98),
        const Offset(0.96, 0.82),
        const Offset(0.56, 0.47),
      ]),
      blue,
    );
    canvas.drawPath(
      parallelogram([
        const Offset(0.36, 0.62),
        const Offset(0.58, 0.81),
        const Offset(0.73, 0.68),
        const Offset(0.51, 0.49),
      ]),
      cutout,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
