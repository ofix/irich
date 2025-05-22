// ///////////////////////////////////////////////////////////////////////////
// Name:        irich/lib/components/svg_image.dart
// Purpose:     wrapper class for svg image
// Author:      songhuabiao
// Created:     2025-04-26 20:30
// Copyright:   (C) Copyright 2024, Wealth Corporation, All Rights Reserved.
// Licence:     GNU GENERAL PUBLIC LICENSE, Version 3
// ///////////////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  const SvgImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      placeholderBuilder:
          (context) => SizedBox(
            width: width,
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          ),
    );
  }
}
