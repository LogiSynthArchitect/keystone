import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import 'package:keystone/core/widgets/ks_sliding_notification.dart';
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
      final hasPerm = await FlutterContacts.requestPermission();
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
      KsSlidingNotification.show(context, message: "$count customers imported", type: KsNotificationType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: context.ksc.primary800, border: Border(bottom: BorderSide(color: context.ksc.primary700))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("IMPORT CONTACTS", style: AppTextStyles.h3.copyWith(color: context.ksc.white, letterSpacing: 1.5)),
                  if (_importing == 0)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: context.ksc.accent500))
                  : !_hasPermission
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LineAwesomeIcons.exclamation_triangle_solid, size: 48, color: context.ksc.warning500),
                                const SizedBox(height: 16),
                                Text("CONTACTS PERMISSION REQUIRED", style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 8),
                                Text("Grant contacts access in Settings to import phone numbers.", textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: context.ksc.neutral500)),
                              ],
                            ),
                          ),
                        )
                      : _contacts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LineAwesomeIcons.address_book_solid, size: 48, color: context.ksc.neutral500),
                                  const SizedBox(height: 16),
                                  Text("NO CONTACTS FOUND", style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
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
                                    onTap: exists ? null : () => setState(() { if (sel) _selected.remove(i); else _selected.add(i); }),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36, height: 36,
                                            decoration: BoxDecoration(color: context.ksc.primary900, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
                                            child: Center(child: Text(c['name']![0].toUpperCase(), style: AppTextStyles.body.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900))),
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
            if (_importing == 0)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: context.ksc.primary800, border: Border(top: BorderSide(color: context.ksc.primary700))),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _selected.isEmpty ? null : _importSelected,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.ksc.accent500,
                      foregroundColor: context.ksc.primary900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text("IMPORT ${_selected.isNotEmpty ? '(${_selected.length})' : ''}", style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  ),
                ),
              ),
            if (_importing == 1)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
