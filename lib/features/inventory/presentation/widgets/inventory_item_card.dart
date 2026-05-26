import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../domain/entities/inventory_item_entity.dart';

/// A card widget that displays an [InventoryItemEntity] in a consistent,
/// reusable card format — matching the design used in [InventoryScreen].
///
/// Use [alreadyAdded] to show a checkmark (green) or plus (gold) overlay.
/// [onTap] and [onLongPress] are forwarded to the underlying InkWell.
class InventoryItemCard extends StatelessWidget {
  final InventoryItemEntity item;
  final bool alreadyAdded;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const InventoryItemCard({
    super.key,
    required this.item,
    this.alreadyAdded = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.ksc;
    final isLow = item.isLowStock;

    // Stock status
    String stockLabel;
    Color stockColor;
    if (item.quantity == 0) {
      stockLabel = 'OUT OF STOCK';
      stockColor = theme.error500;
    } else if (isLow && item.isLowStockSnoozed) {
      stockLabel = 'SNOOZED';
      stockColor = theme.neutral500;
    } else if (isLow) {
      stockLabel = 'LOW STOCK';
      stockColor = theme.warning500;
    } else {
      stockLabel = 'IN STOCK';
      stockColor = const Color(0xFF4CAF50);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.primary800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alreadyAdded
              ? theme.accent500.withValues(alpha: 0.5)
              : isLow
                  ? theme.warning500.withValues(alpha: 0.5)
                  : theme.primary700,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Photo thumbnail ──
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty
                        ? theme.primary800
                        : theme.primary900,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty
                          ? theme.accent500.withValues(alpha: 0.2)
                          : theme.primary700,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty
                      ? Image.network(item.coverImageUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(child: Text(_categoryEmoji(item.category), style: const TextStyle(fontSize: 22))))
                      : Center(child: Text(_categoryEmoji(item.category), style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),

                // ── Info + Tags ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name row
                      Row(
                        children: [
                          Expanded(
                            child: Text(item.name.toUpperCase(),
                                style: AppTextStyles.body.copyWith(
                                  color: alreadyAdded ? theme.neutral500 : theme.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (item.isArchived)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: theme.neutral500.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                                child: Text("ARCHIVED", style: AppTextStyles.caption.copyWith(color: theme.neutral500, fontSize: 9, fontWeight: FontWeight.w800)),
                              ),
                            ),
                        ],
                      ),

                      // Brand / Model
                      if (item.brand != null || item.model != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (item.brand != null)
                              Text(item.brand!, style: AppTextStyles.caption.copyWith(
                                color: alreadyAdded ? theme.neutral600 : theme.neutral500,
                                fontWeight: FontWeight.w600)),
                            if (item.brand != null && item.model != null) ...[
                              const SizedBox(width: 6),
                              Text("·", style: AppTextStyles.caption.copyWith(color: theme.neutral600)),
                              const SizedBox(width: 6),
                            ],
                            if (item.model != null)
                              Text(item.model!, style: AppTextStyles.caption.copyWith(
                                color: alreadyAdded ? theme.neutral600 : theme.neutral500,
                                fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],

                      // Tags
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          // Category tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: alreadyAdded
                                  ? theme.neutral500.withValues(alpha: 0.1)
                                  : theme.accent500.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(item.category.displayName,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 9, fontWeight: FontWeight.w800,
                                  color: alreadyAdded ? theme.neutral600 : theme.accent500,
                                  letterSpacing: 0.5)),
                          ),
                          // Location tag
                          if (item.location != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: alreadyAdded
                                    ? theme.neutral500.withValues(alpha: 0.1)
                                    : theme.primary700.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LineAwesomeIcons.map_pin_solid, size: 9,
                                      color: alreadyAdded ? theme.neutral600 : theme.neutral500),
                                  const SizedBox(width: 3),
                                  Text(item.location!.toUpperCase(),
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 9, fontWeight: FontWeight.w800,
                                        color: alreadyAdded ? theme.neutral600 : theme.neutral500,
                                        letterSpacing: 0.5)),
                                ],
                              ),
                            ),
                          // AUTO-COGS tag
                          if (item.isAutoCogs)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: alreadyAdded
                                    ? theme.neutral500.withValues(alpha: 0.1)
                                    : theme.primary500.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text("AUTO-COGS",
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 9, fontWeight: FontWeight.w800,
                                    color: alreadyAdded ? theme.neutral600 : theme.primary500,
                                    letterSpacing: 0.5)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Status icons (right side) ──
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Stock badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: alreadyAdded ? Colors.transparent : stockColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        alreadyAdded ? '${item.quantity}' : stockLabel,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: alreadyAdded ? theme.neutral600 : stockColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (alreadyAdded) ...[
                      const SizedBox(height: 4),
                      const Icon(LineAwesomeIcons.check_circle_solid, size: 18, color: Color(0xFF4CAF50)),
                    ] else ...[
                      const SizedBox(height: 4),
                      Icon(LineAwesomeIcons.plus_circle_solid, size: 18, color: theme.accent500),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _categoryEmoji(InventoryItemCategory cat) {
    switch (cat) {
      case InventoryItemCategory.key: return '🔑';
      case InventoryItemCategory.lock: return '🔒';
      case InventoryItemCategory.automotive: return '🚗';
      case InventoryItemCategory.electronic: return '⚡';
      case InventoryItemCategory.safe: return '🔐';
      case InventoryItemCategory.consumable: return '📦';
    }
  }
}
