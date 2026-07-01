import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
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
      return _shimmerPlaceholder();
    }

    if (resolvedUrl.startsWith("http")) {
      return CachedNetworkImage(
        imageUrl: resolvedUrl,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, __) => _shimmerPlaceholder(),
        errorWidget: (_, __, ___) => fallback(),
      );
    }

    return Image.file(
      File(resolvedUrl),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _shimmerPlaceholder(),
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
