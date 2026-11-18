import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/exercise.dart';

const kAccent = Color(0xFFC6FF00);
const kBg = Color(0xFF0E1013);
const kSurface = Color(0xFF181B20);
const kSurface2 = Color(0xFF22262D);

/// Gambar gerakan. Jika [animate] true, bergantian antara posisi awal & akhir
/// sehingga terlihat seperti animasi gerakan.
class ExerciseImage extends StatefulWidget {
  const ExerciseImage({
    super.key,
    required this.exercise,
    this.animate = false,
    this.fit = BoxFit.cover,
    this.borderRadius = 12,
    this.width,
    this.height,
  });

  final Exercise exercise;
  final bool animate;
  final BoxFit fit;
  final double borderRadius;
  final double? width;
  final double? height;

  @override
  State<ExerciseImage> createState() => _ExerciseImageState();
}

class _ExerciseImageState extends State<ExerciseImage> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.animate && widget.exercise.imageCount > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
        if (mounted) {
          setState(() => _index = (_index + 1) % widget.exercise.imageCount);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.exercise.imageUrls;
    final fallback = _Fallback(group: widget.exercise.group);
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: urls.isEmpty
            ? fallback
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: CachedNetworkImage(
                  key: ValueKey(_index),
                  imageUrl: urls[_index.clamp(0, urls.length - 1)],
                  fit: widget.fit,
                  width: widget.width,
                  height: widget.height,
                  placeholder: (_, _) => fallback,
                  errorWidget: (_, _, _) => fallback,
                ),
              ),
      ),
    );
  }
}

class NetImage extends StatelessWidget {
  const NetImage(
    this.imageId, {
    super.key,
    this.fit = BoxFit.cover,
    this.index = 0,
  });
  final String imageId;
  final BoxFit fit;
  final int index;

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
    imageUrl: imageUrl(imageId, index),
    fit: fit,
    placeholder: (_, _) => Container(color: kSurface2),
    errorWidget: (_, _, _) => Container(color: kSurface2),
  );
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.group});
  final MuscleGroup group;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          group.color.withValues(alpha: .35),
          group.color.withValues(alpha: .1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(child: Icon(group.icon, color: group.color, size: 28)),
  );
}

/// Banner foto dengan gradien gelap di atasnya.
class PhotoBanner extends StatelessWidget {
  const PhotoBanner({
    super.key,
    required this.imageId,
    required this.child,
    this.height = 180,
    this.radius = 20,
  });
  final String imageId;
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
          NetImage(imageId),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0xEE0E1013)],
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class InfoChip extends StatelessWidget {
  const InfoChip(this.label, {super.key, this.icon, this.color});
  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: .25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu pilihan untuk onboarding.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.imageId,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? imageId;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? kAccent.withValues(alpha: .12) : kSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? kAccent : Colors.white10,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (imageId != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: NetImage(imageId!),
                    ),
                  )
                else if (icon != null)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (selected ? kAccent : Colors.white).withValues(
                        alpha: .1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: selected ? kAccent : Colors.white70,
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: kAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badge!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? kAccent : Colors.white24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String formatDuration(int sec) {
  final h = sec ~/ 3600, m = (sec % 3600) ~/ 60, s = sec % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}
