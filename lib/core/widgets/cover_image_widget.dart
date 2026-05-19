import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';

class CoverImageWidget extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final double height;
  final double borderRadius;

  const CoverImageWidget({
    super.key,
    this.imageUrl,
    required this.fallbackIcon,
    this.height = 120,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(context),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _buildPlaceholder(context);
                },
              )
            : _buildPlaceholder(context),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.ksc.primary800,
            context.ksc.primary700.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(fallbackIcon, color: context.ksc.neutral500.withValues(alpha: 0.4), size: 48),
      ),
    );
  }
}
