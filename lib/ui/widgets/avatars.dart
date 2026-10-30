import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/eventa_colors.dart';

/// Avatar photo, ou initiales sur fond teinté quand il n'y a pas de photo.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.image,
    this.bytes,
    this.initials = '',
    this.size = 36,
    this.online = false,
    this.ring = Colors.white,
  });

  final String? image;

  /// Photo importée (prioritaire sur [image]).
  final Uint8List? bytes;
  final String initials;
  final double size;
  final bool online;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Confetti.lavender,
              border: Border.all(color: ring, width: 2),
              image: bytes != null
                  ? DecorationImage(
                      image: MemoryImage(bytes!),
                      fit: BoxFit.cover,
                    )
                  : image == null
                  ? null
                  : DecorationImage(
                      image: AssetImage(image!),
                      fit: BoxFit.cover,
                    ),
            ),
            child: image == null && bytes == null
                ? Text(
                    initials,
                    style: TextStyle(
                      fontSize: size * 0.36,
                      fontWeight: FontWeight.w700,
                      color: Confetti.violetText,
                    ),
                  )
                : null,
          ),
          if (online)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: Confetti.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: ring, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Avatars qui se chevauchent, avec un compteur « +n ».
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.images,
    this.size = 30,
    this.max = 4,
    this.ring = Colors.white,
  });

  final List<String?> images;
  final double size;
  final int max;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    final shown = images.take(max).toList();
    final extra = images.length - shown.length;
    final step = size * 0.66;
    final count = shown.length + (extra > 0 ? 1 : 0);
    return SizedBox(
      height: size,
      width: count == 0 ? 0 : step * (count - 1) + size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: step * i,
              child: Avatar(image: shown[i], size: size, ring: ring),
            ),
          if (extra > 0)
            Positioned(
              left: step * shown.length,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Confetti.ink,
                  shape: BoxShape.circle,
                  border: Border.all(color: ring, width: 2),
                ),
                child: Text(
                  '+$extra',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
