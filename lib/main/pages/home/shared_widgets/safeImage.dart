import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SafeImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SafeImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: _buildImage(url),
    );
  }

  Widget _buildImage(String? resolvedUrl) {
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      return fallback();
    }

    if (resolvedUrl.startsWith("http")) {
      return Image.network(
        resolvedUrl,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          // Show shimmer while loading
          return _shimmerPlaceholder();
        },
        errorBuilder: (_, __, ___) => fallback(),
      );
    }

    // Local file
    return Image.file(
      File(resolvedUrl),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback(),
    );
  }

  Widget _shimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
     color: Colors.black,
      ),
    );
  }

  Widget fallback() {
    return Image.asset(
      "assets/img/no_internet.png",
      width: width,
      height: height,
      fit: fit,
    );
  }
}
