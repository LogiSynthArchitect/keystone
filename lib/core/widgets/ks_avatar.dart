import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';

enum KsAvatarSize { sm, md, lg, xl }

class KsAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final KsAvatarSize size;

  const KsAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = KsAvatarSize.md,
  });

  @override
  Widget build(BuildContext context) {
    final diameter = _diameter;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.ksc.primary100,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                initials ?? '?',
                style: AppTextStyles.label.copyWith(
                  color: context.ksc.primary700,
                  fontSize: _fontSize,
                ),
              ),
            )
          : null,
    );
  }

  double get _diameter {
    switch (size) {
      case KsAvatarSize.sm: return AppSpacing.avatarSm;
      case KsAvatarSize.md: return AppSpacing.avatarMd;
      case KsAvatarSize.lg: return AppSpacing.avatarLg;
      case KsAvatarSize.xl: return AppSpacing.avatarXl;
    }
  }

  double get _fontSize {
    switch (size) {
      case KsAvatarSize.sm: return 12;
      case KsAvatarSize.md: return 16;
      case KsAvatarSize.lg: return 28;
      case KsAvatarSize.xl: return 40;
    }
  }
}
