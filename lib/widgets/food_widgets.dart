import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/food_db.dart';
import '../models/nutrition.dart';
import 'common.dart';

const kProteinColor = Color(0xFFEF5350);
const kCarbColor = Color(0xFFFFB74D);
const kFatColor = Color(0xFF4FC3F7);
const kWaterColor = Color(0xFF29B6F6);

/// Wikimedia meminta User-Agent yang jelas.
const _headers = {'User-Agent': 'MGCGymCoach/1.0 (Flutter; educational app)'};

/// Foto dari URL dengan placeholder & cadangan ikon.
class UrlPhoto extends StatelessWidget {
  const UrlPhoto(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.icon = Icons.restaurant,
    this.color = kAccent,
    this.padding = EdgeInsets.zero,
  });
  final String? url;
  final BoxFit fit;
  final IconData icon;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: .3), color.withValues(alpha: .08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Icon(icon, color: color, size: 28)),
    );
    if (url == null) return fallback();
    return CachedNetworkImage(
      imageUrl: url!,
      httpHeaders: _headers,
      fit: fit,
      imageBuilder: padding == EdgeInsets.zero
          ? null
          : (_, img) => Padding(
              padding: padding,
              child: Image(image: img, fit: fit),
            ),
      placeholder: (_, _) => Container(color: kSurface2),
      errorWidget: (_, _, _) => fallback(),
    );
  }
}

/// Gambar bahan makanan (PNG transparan TheMealDB → diberi latar terang lembut).
class FoodThumb extends StatelessWidget {
  const FoodThumb(this.food, {super.key, this.size = 48, this.radius = 12});
  final Food food;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cutout = food.photo == null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: cutout ? const Color(0xFFECEFF1) : kSurface2,
        child: UrlPhoto(
          foodImageUrl(food),
          fit: cutout ? BoxFit.contain : BoxFit.cover,
          icon: food.cat.icon,
          color: food.cat.color,
          padding: cutout ? EdgeInsets.all(size * .08) : EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// Banner foto dengan gradien gelap (berbasis URL).
class UrlBanner extends StatelessWidget {
  const UrlBanner({
    super.key,
    required this.url,
    required this.child,
    this.height = 180,
    this.radius = 20,
  });
  final String? url;
  final Widget child;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          UrlPhoto(url),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22000000), Color(0xF00E1013)],
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    ),
  );
}

/// Bar progres makro: "Protein 120 / 140 g".
class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    this.unit = 'g',
  });
  final String label;
  final double value;
  final double target;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final pct = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${value.round()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: '/${target.round()}$unit',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              color: color,
              backgroundColor: Colors.white10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Donat komposisi makro (persentase kalori).
class MacroDonut extends StatelessWidget {
  const MacroDonut({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.size = 120,
    this.center,
  });
  final double protein, carbs, fat;
  final double size;
  final Widget? center;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _DonutPainter([
        (protein * 4, kProteinColor),
        (carbs * 4, kCarbColor),
        (fat * 9, kFatColor),
      ]),
      child: Center(child: center),
    ),
  );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.parts);
  final List<(double, Color)> parts;

  @override
  void paint(Canvas canvas, Size size) {
    final total = parts.fold(0.0, (a, p) => a + p.$1);
    if (total <= 0) return;
    final stroke = size.width * .13;
    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    var start = -pi / 2;
    for (final (v, c) in parts) {
      final sweep = v / total * 2 * pi;
      canvas.drawArc(
        rect,
        start + .03,
        max(0, sweep - .06),
        false,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}

/// Ilustrasi "Isi Piringku" (Kemenkes RI).
class IsiPiringkuPlate extends StatelessWidget {
  const IsiPiringkuPlate({super.key, this.size = 200});
  final double size;

  static const sections = [
    ('Makanan Pokok', '⅓ piring', Color(0xFFFFB74D), Icons.rice_bowl),
    ('Lauk Pauk', '⅙ piring', Color(0xFFEF5350), Icons.set_meal),
    ('Buah', '⅙ piring', Color(0xFFFF8A65), Icons.apple),
    ('Sayuran', '⅓ piring', Color(0xFF66BB6A), Icons.grass),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _PlatePainter()),
  );
}

class _PlatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFE0E0E0));
    canvas.drawCircle(c, r * .9, Paint()..color = const Color(0xFFF5F5F5));
    final inner = Rect.fromCircle(center: c, radius: r * .86);
    // Urutan searah jarum jam mulai dari atas: pokok ⅓, lauk ⅙, buah ⅙, sayur ⅓.
    final fracs = [1 / 3, 1 / 6, 1 / 6, 1 / 3];
    var start = -pi / 2;
    for (var i = 0; i < 4; i++) {
      final sweep = fracs[i] * 2 * pi;
      final col = IsiPiringkuPlate.sections[i].$3;
      canvas.drawArc(
        inner,
        start,
        sweep,
        true,
        Paint()..color = col.withValues(alpha: .9),
      );
      canvas.drawArc(
        inner,
        start,
        sweep,
        true,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      // ikon di tengah irisan
      final mid = start + sweep / 2;
      final pos = c + Offset(cos(mid), sin(mid)) * r * .52;
      final icon = IsiPiringkuPlate.sections[i].$4;
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: r * .26,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Kotak kecil angka + label.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.color = Colors.white,
    this.highlight = false,
  });
  final String value;
  final String label;
  final IconData? icon;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight ? kAccent.withValues(alpha: .12) : kSurface,
        borderRadius: BorderRadius.circular(14),
        border: highlight ? Border.all(color: kAccent) : null,
      ),
      child: Column(
        children: [
          if (icon != null) Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    ),
  );
}
