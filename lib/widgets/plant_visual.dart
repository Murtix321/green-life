import 'dart:io';

import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../theme.dart';

/// Bir bitkinin en iyi görseli:
/// 1) arka planı silinmiş gerçek katalog fotoğrafı (assets/plants),
/// 2) kullanıcının kendi fotoğrafı (dosya) ya da internetten gelen fotoğraf,
/// 3) yaprak simgesi.
class PlantVisual extends StatelessWidget {
  final Plant plant;
  final double? width;
  final double? height;
  final double radius;

  /// true: kullanıcının fotoğrafı varsa katalog görselinin önüne geçer.
  final bool preferPhoto;

  const PlantVisual(this.plant, {super.key, this.width, this.height, this.radius = 18, this.preferPhoto = false});

  @override
  Widget build(BuildContext context) {
    final photo = plant.photo;
    if (preferPhoto && photo != null) return photoOrAsset(photo, width: width, height: height, radius: radius);
    if (plant.image != null) {
      return Image.asset(plant.image!, width: width, height: height, fit: BoxFit.contain, semanticLabel: plant.name);
    }
    if (photo != null) return photoOrAsset(photo, width: width, height: height, radius: radius);
    return leafPlaceholder(width: width, height: height, radius: radius);
  }
}

/// 'assets/…' → asset (arka planı silinmiş), 'http…' → internet, diğer → telefondaki dosya.
Widget photoOrAsset(String path, {double? width, double? height, double radius = 18}) {
  if (path.startsWith('assets/')) {
    return Image.asset(path, width: width, height: height, fit: BoxFit.contain);
  }
  final Widget img = path.startsWith('http')
      ? Image.network(path, width: width, height: height, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => leafPlaceholder(width: width, height: height, radius: radius))
      : Image.file(File(path), width: width, height: height, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => leafPlaceholder(width: width, height: height, radius: radius));
  return ClipRRect(borderRadius: BorderRadius.circular(radius), child: img);
}

Widget leafPlaceholder({double? width, double? height, double radius = 18}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: GL.glassFill, borderRadius: BorderRadius.circular(radius)),
      child: const Icon(Icons.eco_rounded, color: GL.greenDark, size: 34),
    );
