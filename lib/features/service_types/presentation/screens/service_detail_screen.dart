import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/service_categories.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/icon_helpers.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../providers/service_type_provider.dart';
import '../../domain/entities/service_type_entity.dart';

/// Category color map — matches the list screen.
Color _catColor(String key) {
  switch (key) {
    case 'Residential':     return const Color(0xFF4A6EC4);
    case 'Automotive':      return const Color(0xFF2E7D32);
    case 'Commercial':      return const Color(0xFFB8860B);
    case 'Security Systems': return const Color(0xFFC62828);
    case 'Specialty':       return const Color(0xFF6B7280);
    default:                return const Color(0xFF6B7280);
  }
}

class ServiceDetailScreen extends ConsumerWidget {
  final ServiceTypeEntity service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.ksc;
    final cat = ServiceCategory.fromKey(service.category);
    final color = _catColor(service.category);
    final icon = getLineAwesomeIcon(service.iconName);

    return Scaffold(
      backgroundColor: c.primary900,
      body: Column(
        children: [
          // ── App Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: SizedBox(
                      width: 36, height: 36,
                      child: Center(
                        child: Text('\u2190',
                          style: TextStyle(fontSize: 18, color: c.neutral400)),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text('Service Detail',
                    style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w900,
                      letterSpacing: -0.3, color: c.white)),
                  const Spacer(),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {/* TODO: edit */},
                        child: SizedBox(
                          width: 36, height: 36,
                          child: Center(
                            child: Text('\u270E',
                              style: TextStyle(fontSize: 15, color: c.neutral400)),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _confirmDelete(context, ref),
                        child: SizedBox(
                          width: 36, height: 36,
                          child: Center(
                            child: Text('\u2715',
                              style: TextStyle(fontSize: 15, color: c.neutral400)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Scrollable content ──
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero ──
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: c.primary800,
                      border: Border(
                        bottom: BorderSide(color: c.primary700),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(icon, size: 52, color: c.neutral500.withValues(alpha: 0.2)),
                        Positioned(
                          bottom: 12, right: 0,
                          child: GestureDetector(
                            onTap: () {/* TODO: change cover photo */},
                            child: Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: c.primary800,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: c.primary700),
                              ),
                              child: Center(
                                child: Text('\u{1F4F7}',
                                  style: TextStyle(fontSize: 13, color: c.neutral400)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Header: name + price ──
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(service.name,
                                style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3, color: c.white)),
                              const SizedBox(height: 4),
                              Text(
                                (cat?.display ?? service.category).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  letterSpacing: 1, color: color),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('BASE PRICE',
                              style: TextStyle(
                                fontSize: 9, fontWeight: FontWeight.w700,
                                letterSpacing: 1.5, color: c.neutral500)),
                            const SizedBox(height: 2),
                            if (service.defaultPrice != null)
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'GHS ',
                                      style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w700,
                                        color: c.neutral500),
                                    ),
                                    TextSpan(
                                      text: '${(service.defaultPrice! / 100).toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 24, fontWeight: FontWeight.w900,
                                        color: c.white),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Text('--',
                                style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700,
                                  color: c.neutral500)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Border separator ──
                  Divider(height: 1, color: c.primary700),

                  // ── Stats Grid ──
                  Padding(
                    padding: const EdgeInsets.all(0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _StatCell(c, 'Duration', '30 min')),
                            Container(width: 1, height: 44, color: c.primary700),
                            Expanded(child: _StatCell(c, 'Skill', 'Intermediate')),
                          ],
                        ),
                        Divider(height: 1, color: c.primary700),
                        Row(
                          children: [
                            Expanded(child: _StatCell(c, 'Category',
                              cat?.display ?? service.category)),
                            Container(width: 1, height: 44, color: c.primary700),
                            Expanded(child: _StatCell(c, 'Parts', '3 typical')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: c.primary700),

                  // ── Description ──
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DESCRIPTION',
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w800,
                            letterSpacing: 1.5, color: c.neutral500)),
                        const SizedBox(height: 6),
                        Text(
                          '${service.name} service provided by your trusted locksmith. '
                          'Contact for accurate pricing and availability.',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: c.neutral400, height: 1.6),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: c.primary700),

                  // ── Typical Parts ──
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TYPICAL PARTS',
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w800,
                            letterSpacing: 1.5, color: c.neutral500)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6, runSpacing: 6,
                          children: [
                            _PartChip(c, 'Standard Cylinder'),
                            _PartChip(c, 'Screw Kit'),
                            _PartChip(c, 'Strike Plate'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Action buttons ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {/* TODO: edit */},
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: c.primary700),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('\u270E',
                                    style: TextStyle(fontSize: 13, color: c.neutral400)),
                                  const SizedBox(width: 6),
                                  Text('EDIT',
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5, color: c.neutral400)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {/* TODO: create job from this */},
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: const Color(0xFFD4A017),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('+',
                                    style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0A1628))),
                                  const SizedBox(width: 6),
                                  Text('CREATE JOB',
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                      color: const Color(0xFF0A1628))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    KsConfirmDialog.show(
      context,
      title: 'DELETE SERVICE',
      message: "Are you sure you want to remove '${service.name}'?",
      confirmLabel: 'DELETE',
      cancelLabel: 'CANCEL',
      isDanger: true,
      onConfirm: () {
        ref.read(serviceTypeProvider.notifier).deleteServiceType(service.id);
        Navigator.maybePop(context);
      },
    );
  }
}

class _StatCell extends StatelessWidget {
  final KsColors c;
  final String label;
  final String value;

  const _StatCell(this.c, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
            style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700,
              letterSpacing: 1.5, color: c.neutral500)),
          const SizedBox(height: 2),
          Text(value,
            style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800,
              color: c.white)),
        ],
      ),
    );
  }
}

class _PartChip extends StatelessWidget {
  final KsColors c;
  final String label;

  const _PartChip(this.c, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: c.primary800,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.primary700),
      ),
      child: Text(label,
        style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: c.neutral400)),
    );
  }
}
