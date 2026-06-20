import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import 'package:arclock/core/widgets/ks_sliding_notification.dart';
import 'package:arclock/core/widgets/ks_success_moment.dart';
import 'package:arclock/core/widgets/ks_step_drawer.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/usecases/create_customer_usecase.dart';
import '../providers/customer_providers.dart';

class ContactImportSheet extends ConsumerStatefulWidget {
  final List<CustomerEntity> existingCustomers;

  const ContactImportSheet({super.key, required this.existingCustomers});

  @override
  ConsumerState<ContactImportSheet> createState() => _ContactImportSheetState();
}

class _ContactImportSheetState extends ConsumerState<ContactImportSheet> {
  List<Map<String, String>> _contacts = [];
  final Set<int> _selected = {};
  bool _loading = true;
  bool _hasPermission = true;
  int _importing = 0;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final hasPerm = await FlutterContacts.requestPermission(readonly: true);
      if (!hasPerm) {
        setState(() { _loading = false; _hasPermission = false; });
        return;
      }

      final deviceContacts = await FlutterContacts.getContacts(withProperties: true);
      final existingPhones = widget.existingCustomers.map((c) => c.phoneNumber.replaceAll('+', '').replaceAll(' ', '')).toSet();

      setState(() {
        _contacts = deviceContacts
            .where((c) => c.phones.isNotEmpty && c.displayName.isNotEmpty)
            .map((c) => {
              'name': c.displayName,
              'phone': c.phones.first.normalizedNumber.replaceAll(' ', ''),
              'exists': existingPhones.contains(c.phones.first.normalizedNumber.replaceAll(' ', '').replaceAll('+', '')) ? 'true' : 'false',
            })
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) KsSlidingNotification.show(context, message: "Could not load contacts", type: KsNotificationType.error);
    }
  }

  Future<void> _importSelected() async {
    if (_selected.isEmpty) return;
    setState(() => _importing = 1);

    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) return;

    int count = 0;
    for (final i in _selected) {
      final c = _contacts[i];
      if (c['exists'] == 'true') continue;
      try {
        await ref.read(createCustomerUsecaseProvider).call(CreateCustomerParams(
          userId: userId,
          fullName: c['name']!,
          phoneNumber: c['phone']!,
        ));
        count++;
      } catch (_) {}
    }

    setState(() => _importing = 2);
    ref.read(customerListProvider.notifier).refresh();
    if (mounted) {
      Navigator.pop(context);
      await KsSuccessMoment.show(context,
        title: "$count Imported",
        subtitle: count == 1 ? "1 customer added" : "$count customers added",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _importing == 1) {
      return KsStepDrawer(
        title: "IMPORT CONTACTS",
        steps: null,
        showBackArrow: false,
        onSave: _importSelected,
        canAdvance: (_, __) => false,
        onClose: _importing == 0 ? null : () {},
        stepContent: (_, __, ___, ____) {
          if (_importing == 1) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }
          return Center(child: CircularProgressIndicator(color: context.ksc.accent500));
        },
      );
    }

    if (!_hasPermission) {
      return KsStepDrawer(
        title: "IMPORT CONTACTS",
        steps: null,
        showBackArrow: false,
        onSave: _importSelected,
        canAdvance: (_, __) => _selected.isNotEmpty && _importing == 0,
        onClose: null,
        stepContent: (_, __, ___, ____) => Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LineAwesomeIcons.exclamation_triangle_solid, size: 48, color: context.ksc.warning500),
              const SizedBox(height: 16),
              Text("CONTACTS PERMISSION REQUIRED", style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text("Grant contacts access in Settings\nto import phone numbers.", textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: context.ksc.neutral500)),
            ],
          ),
        ),
      );
    }

    if (_contacts.isEmpty) {
      return KsStepDrawer(
        title: "IMPORT CONTACTS",
        steps: null,
        showBackArrow: false,
        onSave: _importSelected,
        canAdvance: (_, __) => _selected.isNotEmpty && _importing == 0,
        onClose: null,
        stepContent: (_, __, ___, ____) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LineAwesomeIcons.address_book_solid, size: 48, color: context.ksc.neutral500),
            const SizedBox(height: 16),
            Text("NO CONTACTS FOUND", style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    // Contact list using DraggableScrollableSheet for smooth 60fps UX
    // Gesture seamlessly transitions from list scroll → sheet dismiss
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.ksc.primary900,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Container(
                  width: 32, height: 4,
                  decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text("IMPORT CONTACTS", style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    Text("${_selected.length}/${_contacts.length}", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF1E293B), height: 1),
              // Scrollable contact list — no shrinkWrap, no gesture war
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _contacts.length,
                  itemBuilder: (_, i) {
                    final c = _contacts[i];
                    final exists = c['exists'] == 'true';
                    final sel = _selected.contains(i);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: exists ? context.ksc.primary700 : context.ksc.primary800,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: sel ? context.ksc.accent500 : context.ksc.primary700),
                      ),
                      child: InkWell(
                        onTap: exists ? null : () => setState(() { if (sel) { _selected.remove(i); } else { _selected.add(i); } }),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(color: context.ksc.primary900, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
                                child: Center(child: Text(String.fromCharCode(c['name']!.runes.first).toUpperCase(), style: AppTextStyles.body.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c['name']!, style: AppTextStyles.body.copyWith(color: exists ? context.ksc.neutral500 : context.ksc.white, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                                    Text(c['phone']!, style: AppTextStyles.caption.copyWith(color: exists ? context.ksc.neutral600 : context.ksc.neutral400, fontSize: 10)),
                                  ],
                                ),
                              ),
                              if (exists)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: context.ksc.success500.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2)),
                                  child: Text("SAVED", style: AppTextStyles.caption.copyWith(color: context.ksc.success500, fontWeight: FontWeight.w900, fontSize: 8)),
                                )
                              else if (sel)
                                Icon(LineAwesomeIcons.check_solid, color: context.ksc.accent500, size: 18),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Bottom action bar
              Container(
                width: double.infinity,
                color: context.ksc.accent500,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _selected.isNotEmpty && _importing == 0 ? _importSelected : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selected.isNotEmpty ? "IMPORT (${_selected.length})" : "IMPORT",
                            style: AppTextStyles.body.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.0),
                          ),
                          Icon(LineAwesomeIcons.arrow_right_solid, color: context.ksc.primary900, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
