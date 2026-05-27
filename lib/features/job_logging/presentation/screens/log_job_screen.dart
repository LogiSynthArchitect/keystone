import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_bottom_sheet_scaffold.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import 'package:keystone/core/widgets/ks_sliding_notification.dart';
import '../../../../core/widgets/ks_step_drawer.dart';
import '../../../../core/utils/service_icon_map.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/ks_search_bar.dart';
import '../../../../core/widgets/ks_success_moment.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../providers/job_providers.dart';
import '../../../inventory/presentation/widgets/inventory_item_card.dart';
import '../../domain/entities/job_entity.dart';
import '../../domain/entities/job_service_entity.dart';
import '../../domain/entities/job_part_entity.dart';
import '../../domain/entities/job_expense_entity.dart';
import '../../../service_types/domain/entities/service_type_entity.dart';
import '../../../inventory/domain/entities/inventory_item_entity.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../recurring_jobs/presentation/providers/recurring_schedule_provider.dart';
import '../../../job_templates/domain/entities/job_template_entity.dart';
import '../../../job_templates/domain/entities/template_service_item.dart';
import '../../../job_templates/domain/entities/template_hardware_item.dart';
import '../../../job_templates/domain/entities/template_part_item.dart';
import '../../../job_templates/presentation/providers/job_template_provider.dart';
import '../widgets/job_step_types.dart';
import '../widgets/job_step_service.dart';
import '../widgets/job_step_status.dart';
import '../widgets/job_step_customer.dart';
import '../widgets/job_step_pricing.dart';
import '../widgets/job_step_schedule.dart';
import '../widgets/job_step_extras.dart';

// Row types (ItemRow, ServiceRow, PartRow, HardwareRow, ExpenseRow)
// are now imported from job_step_types.dart

/// Static entry point — shows the Log Job drawer as a bottom sheet.
class LogJobScreen {
  static Future<void> show(BuildContext context, {String? preSelectedCustomerId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => _LogJobSheet(preSelectedCustomerId: preSelectedCustomerId),
    );
  }
}

class _LogJobSheet extends ConsumerStatefulWidget {
  final String? preSelectedCustomerId;
  const _LogJobSheet({this.preSelectedCustomerId});

  @override
  ConsumerState<_LogJobSheet> createState() => _LogJobSheetState();
}

class _LogJobSheetState extends ConsumerState<_LogJobSheet> {

  String? _serviceType;
  String? _finalCustomerId;
  String _status = 'quoted';
  String _paymentStatus = 'unpaid';
  String? _leadSource;

  bool _isRecurring = false;
  String _recurringInterval = 'monthly';

  final _customerController     = TextEditingController();
  final _phoneController        = TextEditingController();
  final _locationController     = TextEditingController();
  final _amountController       = TextEditingController();
  final _quotedAmountController = TextEditingController();
  final _notesController        = TextEditingController();
  FocusNode? _quotedFocusNode;
  FocusNode? _amountFocusNode;
  String? _matchedCustomerName;
  String? _matchedCustomerId;
  Timer? _phoneLookupDebounce;
  String? _lastLookupPhone;

  final List<ServiceRow> _additionalServices = [];
  final List<ItemRow> _items = [];
  final List<PartRow> _parts = [];
  final List<HardwareRow> _hardwareItems = [];
  final List<ExpenseRow> _expenses = [];
  int _partSuggestionIndex = -1;
  List<InventoryItemEntity> _partSuggestions = [];
  int _hwSuggestionIndex = -1;
  List<InventoryItemEntity> _hwSuggestions = [];
  final List<XFile> _generalPhotos = [];
  final List<XFile> _beforePhotos = [];
  final List<XFile> _afterPhotos = [];

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  DateTime _jobDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final preSelectedId = widget.preSelectedCustomerId;

    _quotedFocusNode = currencyFocusNode(_quotedAmountController);
    _amountFocusNode = currencyFocusNode(_amountController);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(logJobProvider.notifier).reset();

      if (preSelectedId != null) {
        _finalCustomerId = preSelectedId;
        try {
          final repo = ref.read(customerRepositoryProvider);
          final customer = await repo.getCustomerById(preSelectedId);
          setState(() {
            _customerController.text = customer.fullName;
            _phoneController.text    = customer.phoneNumber;
          });
        } catch (e) {
          debugPrint('[KS:LOG_JOB] Fast-prefill failed: $e');
        }
      }

      final userId = ref.read(currentUserProvider).valueOrNull?.id;
      if (userId != null) {
        final invItems = ref.read(inventoryProvider.notifier);
        invItems.loadItems(userId);

        ref.read(jobTemplateProvider.notifier).loadTemplates(userId);
      }
    });
  }

  @override
  void dispose() {
    _phoneLookupDebounce?.cancel();
    _customerController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _amountController.dispose();
    _quotedAmountController.dispose();
    _quotedFocusNode?.dispose();
    _amountFocusNode?.dispose();
    _notesController.dispose();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    for (var p in _parts) { p.dispose(); }
    for (var i in _items) { i.dispose(); }
    for (var s in _additionalServices) { s.dispose(); }
    for (var h in _hardwareItems) { h.dispose(); }
    for (var e in _expenses) { e.dispose(); }
    super.dispose();
  }

  bool get _isDirty => _serviceType != null ||
                      _customerController.text.isNotEmpty ||
                      _amountController.text.isNotEmpty ||
                      _notesController.text.isNotEmpty ||
                      _parts.isNotEmpty ||
                      _additionalServices.isNotEmpty ||
                      _hardwareItems.isNotEmpty ||
                      _expenses.isNotEmpty ||
                       _generalPhotos.isNotEmpty ||
                       _beforePhotos.isNotEmpty ||
                       _afterPhotos.isNotEmpty;

  bool _canMoveForwardForStep(int step) {
    final hasCustomer = _finalCustomerId != null;
    switch (step) {
      case 0: return true; // TEMPLATE — always can proceed
      case 1: return _serviceType != null && _serviceType!.isNotEmpty;
      case 2: return true;
      case 3:
        if (_customerController.text.trim().isEmpty) return false;
        if (hasCustomer) return true;
        final phone = _phoneController.text.trim();
        // Accept 10 digits (with 0) or 9 digits (without 0) — PhoneFormatter normalizes both
        return (phone.length == 10 && phone.startsWith('0')) ||
               (phone.length == 9 && !phone.startsWith('0'));
      case 4:
        final amountText = _amountController.text.trim();
        if (amountText.isEmpty) return true;
        final amount = CurrencyFormatter.parseToPesewas(amountText);
        return amount != null && amount >= 0;
      case 5: return true;
      case 6: return true;
      default: return false;
    }
  }



  void _applyTemplate(JobTemplateEntity template) {
    setState(() {
      // Service type
      _serviceType = template.serviceType;

      // Additional services — dispose old controllers first
      for (final s in _additionalServices) { s.dispose(); }
      _additionalServices.clear();
      for (final s in template.services) {
        final row = ServiceRow();
        row.serviceType = s.serviceType;
        row.qtyController.text = s.quantity.toString();
        _additionalServices.add(row);
      }

      // Items (hardware + parts) — match the split in _saveAsTemplate
      for (final i in _items) { i.dispose(); }
      _items.clear();
      final invItems = ref.read(inventoryProvider).valueOrNull ?? [];

      // Hardware items (from inventory)
      for (final h in template.hardwareItems) {
        final row = ItemRow();
        row.nameController.text = h.name;
        row.qtyController.text = h.quantity.toString();
        row.inventoryItemId = h.inventoryItemId;
        if (h.inventoryItemId != null) {
          row.inventoryItem = invItems.where((i) => i.id == h.inventoryItemId).firstOrNull;
        }
        _items.add(row);
      }

      // Parts (non-inventory)
      for (final p in template.parts) {
        final row = ItemRow();
        row.nameController.text = p.name;
        row.qtyController.text = p.quantity.toString();
        row.inventoryItemId = p.inventoryItemId;
        _items.add(row);
      }

      // Notes
      _notesController.text = template.notes ?? '';
    });

    // Show confirmation snackbar
    KsSlidingNotification.show(context, message: 'Template applied — tap NEXT to review', type: KsNotificationType.info);
  }

  Future<void> _saveAsTemplate() async {
    // Must have a service type selected
    if (_serviceType == null || _serviceType!.isEmpty) {
      KsSlidingNotification.show(context, message: 'Select a service type first.', type: KsNotificationType.error);
      return;
    }

    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ksc.primary800,
        title: Text('SAVE AS TEMPLATE', style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: AppTextStyles.body.copyWith(color: context.ksc.white),
          decoration: InputDecoration(
            hintText: "e.g. Deadbolt replacement",
            hintStyle: TextStyle(color: context.ksc.neutral500),
            border: OutlineInputBorder(borderSide: BorderSide(color: context.ksc.primary700)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: AppTextStyles.label.copyWith(color: context.ksc.neutral400))),
          TextButton(onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()), child: Text('SAVE', style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (name == null || name.isEmpty || !mounted) return;

    final userId = ref.read(currentUserProvider).valueOrNull?.id;
    if (userId == null) {
      KsSlidingNotification.show(context, message: 'Not signed in.', type: KsNotificationType.error);
      return;
    }

    final template = JobTemplateEntity(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      serviceType: _serviceType ?? '',
      notes: _notesController.text.trim(),
      services: _additionalServices.asMap().entries.map((e) {
        final s = e.value;
        return TemplateServiceItem(
          id: '${const Uuid().v4()}-svc-${e.key}',
          serviceType: s.serviceType ?? '',
          quantity: int.tryParse(s.qtyController.text.trim()) ?? 1,
          unitPrice: (ref.read(serviceTypeProvider).valueOrNull ?? []).where((t) => t.name == s.serviceType).firstOrNull?.defaultPrice,
          sortOrder: e.key,
        );
      }).toList(),
      hardwareItems: _items.where((i) => i.isFromInventory).toList().asMap().entries.map((e) {
        final h = e.value;
        return TemplateHardwareItem(
          id: '${const Uuid().v4()}-hw-${e.key}',
          name: h.nameController.text.trim(),
          quantity: int.tryParse(h.qtyController.text.trim()) ?? 1,
          unitSalePrice: h.inventoryItem?.defaultSalePrice,
          inventoryItemId: h.inventoryItemId,
        );
      }).toList(),
      parts: _items.where((i) => !i.isFromInventory).toList().asMap().entries.map((e) {
        final p = e.value;
        return TemplatePartItem(
          id: '${const Uuid().v4()}-part-${e.key}',
          name: p.nameController.text.trim(),
          quantity: int.tryParse(p.qtyController.text.trim()) ?? 1,
          unitPrice: null,
          inventoryItemId: p.inventoryItemId,
        );
      }).toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(jobTemplateProvider.notifier).saveTemplate(template);

    if (mounted) {
      KsSlidingNotification.show(context, message: 'Template saved', type: KsNotificationType.success);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    return await KsConfirmDialog.show(
      context,
      title: 'DISCARD DRAFT?',
      message: 'Your entered job details will be lost. Leave anyway?',
      confirmLabel: 'DISCARD',
      cancelLabel: 'KEEP EDITING',
      isDanger: true,
      onConfirm: () {},
    ) ?? false;
  }

  Future<void> _onSave() async {
    HapticFeedback.heavyImpact();

    // ─── Validation ───────────────────────────────────────
    if (_finalCustomerId == null) {
      final phone = _phoneController.text.trim();
      final valid = (phone.length == 10 && phone.startsWith('0')) ||
                    (phone.length == 9 && !phone.startsWith('0'));
      if (!valid) {
        if (mounted) KsSlidingNotification.show(context, message: "Enter a valid Ghana number (e.g. 024 123 4567)", type: KsNotificationType.error);
        return;
      }
    }

    // Recurring check
    if (_isRecurring && (_recurringInterval == null || _recurringInterval!.isEmpty)) {
      if (mounted) KsSlidingNotification.show(context, message: "Select a recurring interval or turn off recurring", type: KsNotificationType.error);
      return;
    }
    if (_isRecurring && _finalCustomerId == null) {
      if (mounted) KsSlidingNotification.show(context, message: "A customer is required for recurring jobs", type: KsNotificationType.error);
      return;
    }

    // Pricing cross-validation
    final quotedPesewas = CurrencyFormatter.parseToPesewas(_quotedAmountController.text.trim());
    var finalPesewas = CurrencyFormatter.parseToPesewas(_amountController.text.trim());

    if (_paymentStatus == 'paid' && (finalPesewas == null || finalPesewas <= 0)) {
      if (mounted) KsSlidingNotification.show(context, message: "Payment is 'Paid' but no final amount set", type: KsNotificationType.error);
      return;
    }

    // Status cross-validation: completed/invoiced require a final amount
    if ((_status == 'completed' || _status == 'invoiced') && (finalPesewas == null || finalPesewas <= 0)) {
      if (mounted) KsSlidingNotification.show(context,
        message: _status == 'completed'
            ? "Set a final amount before marking as completed"
            : "Set a final amount before marking as invoiced",
        type: KsNotificationType.error);
      return;
    }

    // Lead source reminder (non-blocking)
    if (_leadSource == null && mounted) {
      KsSlidingNotification.show(context,
        message: 'Consider adding a lead source for tracking',
        type: KsNotificationType.info);
    }

    // Quoted → final amount prompt: if quoted is set but final is empty, suggest copy
    if (quotedPesewas != null && quotedPesewas > 0 && (finalPesewas == null || finalPesewas <= 0) && mounted) {
      final useQuoted = await KsConfirmDialog.show(
        context,
        title: 'USE QUOTED AMOUNT?',
        message: 'You entered a quoted amount of ${CurrencyFormatter.format(quotedPesewas)} '
            'but no final amount.\n\nWould you like to use the quoted amount as the final amount?',
        confirmLabel: 'USE QUOTED',
        cancelLabel: 'SKIP',
        isDanger: false,
        onConfirm: () {},
      );
      if (useQuoted == true && mounted) {
        _amountController.text = _quotedAmountController.text;
        // Recalculate finalPesewas for the summary below
        finalPesewas = CurrencyFormatter.parseToPesewas(_amountController.text.trim());
      }
    }

    // Count items with empty names
    final skippedItems = _items.where((i) => i.nameController.text.trim().isEmpty).length;
    final validItems = _items.where((i) => i.nameController.text.trim().isNotEmpty).toList();

    // Count expenses with zero amount
    final zeroAmtExpenses = _expenses.where((e) {
      final amt = CurrencyFormatter.parseToPesewas(e.amountController.text.trim());
      return amt == null || amt <= 0;
    }).length;

    // Build summary for confirmation dialog
    final summaryParts = <String>[];
    summaryParts.add('Service: ${_serviceType?.replaceAll('_', ' ')}');
    if (_additionalServices.isNotEmpty) {
      summaryParts.add('Additional: ${_additionalServices.length}');
    }
    if (validItems.isNotEmpty) {
      final totalQty = validItems.fold<int>(0, (s, i) => s + (int.tryParse(i.qtyController.text.trim()) ?? 1));
      summaryParts.add('Items: ${validItems.length} ($totalQty qty)');
    }
    if (_expenses.isNotEmpty) {
      final totalExp = _expenses.fold<int>(0, (s, e) => s + (CurrencyFormatter.parseToPesewas(e.amountController.text.trim()) ?? 0));
      summaryParts.add('Expenses: ${CurrencyFormatter.format(totalExp)}');
    }
    if (finalPesewas != null && finalPesewas > 0) {
      summaryParts.add('Total: ${CurrencyFormatter.format(finalPesewas)}');
    }

    String summaryMsg = summaryParts.join('\n');
    if (skippedItems > 0) {
      summaryMsg += '\n\n⚠️ $skippedItems item${skippedItems > 1 ? 's' : ''} skipped (empty name)';
    }
    if (zeroAmtExpenses > 0) {
      summaryMsg += '\n⚠️ $zeroAmtExpenses expense${zeroAmtExpenses > 1 ? 's' : ''} have no amount';
    }

    // Confirmation dialog
    final confirmed = await KsConfirmDialog.show(
      context,
      title: 'SAVE THIS JOB?',
      message: summaryMsg,
      confirmLabel: 'SAVE JOB',
      cancelLabel: 'REVIEW',
      isDanger: false,
      onConfirm: () {},
    );
    if (confirmed != true || !mounted) return;

    double? gpsLat;
    double? gpsLng;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
      gpsLat = pos.latitude;
      gpsLng = pos.longitude;
    } catch (_) {}

    final job = await ref.read(logJobProvider.notifier).save(
      serviceType: _serviceType!,
      existingCustomerId: _finalCustomerId,
      newCustomerName: _finalCustomerId == null ? _customerController.text.trim() : null,
      customerPhone: _finalCustomerId == null ? PhoneFormatter.normalize(_phoneController.text.trim()) : null,
      jobDate: _jobDate,
      location: _locationController.text.trim(),
      latitude: gpsLat,
      longitude: gpsLng,
      notes: _notesController.text.trim(),
      amountChargedString: _amountController.text.trim(),
      status: _status,
      paymentStatus: _paymentStatus,
      quotedPriceString: _quotedAmountController.text.trim(),
      leadSource: _leadSource,
      parts: _items.map((i) => (
        i.nameController.text.trim(),
        int.tryParse(i.qtyController.text.trim()) ?? 1,
        0,
        i.inventoryItemId,
      )).toList(),
      hardwareItems: [],
      photos: [
        ..._generalPhotos.map((p) => (File(p.path), '', _inferMediaType(p.path))),
        ..._beforePhotos.map((p) => (File(p.path), 'before', _inferMediaType(p.path))),
        ..._afterPhotos.map((p) => (File(p.path), 'after', _inferMediaType(p.path))),
      ],
    );

    if (!mounted) return;
    if (job != null) {
      final repo = ref.read(jobRepositoryProvider);

      final validServices = _additionalServices.where((s) => s.serviceType != null && s.serviceType!.isNotEmpty).toList();
      if (validServices.isNotEmpty) {
        final services = validServices.asMap().entries.map((e) => JobServiceEntity(
          id: const Uuid().v4(),
          jobId: job.id,
          serviceType: e.value.serviceType ?? '',
          quantity: int.tryParse(e.value.qtyController.text.trim()) ?? 1,
          unitPrice: (ref.read(serviceTypeProvider).valueOrNull ?? []).where((t) => t.name == e.value.serviceType).firstOrNull?.defaultPrice,
          sortOrder: e.key,
          createdAt: DateTime.now(),
        )).toList();
        await repo.saveServices(job.id, services);
      }

      final validItems = _items.where((i) => i.nameController.text.trim().isNotEmpty).toList();
      if (validItems.isNotEmpty) {
        final parts = validItems.asMap().entries.map((e) {
          final inv = e.value.inventoryItem;
          return JobPartEntity(
            id: const Uuid().v4(),
            jobId: job.id,
            partName: e.value.nameController.text.trim(),
            quantity: int.tryParse(e.value.qtyController.text.trim()) ?? 1,
            unitPrice: inv?.defaultSalePrice,
            inventoryItemId: e.value.inventoryItemId,
            createdAt: DateTime.now(),
          );
        }).toList();
        await repo.saveParts(job.id, parts);
      }

      if (_expenses.isNotEmpty) {
        final entities = _expenses.map((e) => JobExpenseEntity(
          id: const Uuid().v4(),
          jobId: job.id,
          category: e.category,
          description: e.descriptionController.text.trim(),
          amount: CurrencyFormatter.parseToPesewas(e.amountController.text.trim()) ?? 0,
          createdAt: DateTime.now(),
        )).toList();
        await repo.saveExpenses(job.id, entities);
      }

      ref.read(logJobProvider.notifier).reset();

      final saveAsTemplate = await KsConfirmDialog.show(
        context,
        title: 'SAVE AS TEMPLATE?',
        message: 'Save this job as a reusable template?',
        confirmLabel: 'YES',
        cancelLabel: 'NO',
        isDanger: false,
        onConfirm: () {},
      );

      if (saveAsTemplate == true && mounted) {
        final nameCtrl = TextEditingController();
        final name = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.ksc.primary800,
            title: Text('TEMPLATE NAME', style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
            content: TextField(
              controller: nameCtrl,
              autofocus: true,
              style: AppTextStyles.body.copyWith(color: context.ksc.white),
              decoration: InputDecoration(
                hintText: "e.g. Deadbolt replacement",
                hintStyle: TextStyle(color: context.ksc.neutral500),
                border: OutlineInputBorder(borderSide: BorderSide(color: context.ksc.primary700)),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: AppTextStyles.label.copyWith(color: context.ksc.neutral400))),
              TextButton(onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()), child: Text('SAVE', style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.bold))),
            ],
          ),
        );

        if (name != null && name.isNotEmpty && mounted) {
          final userId = ref.read(currentUserProvider).valueOrNull?.id;
          if (userId != null) {
            final template = JobTemplateEntity(
              id: const Uuid().v4(),
              userId: userId,
              name: name,
              serviceType: _serviceType ?? '',
              notes: _notesController.text.trim(),
      services: _additionalServices.where((s) => s.serviceType != null && s.serviceType!.isNotEmpty).toList().asMap().entries.map((e) {
                final s = e.value;
                return TemplateServiceItem(
                  id: '${const Uuid().v4()}-svc-${e.key}',
                  serviceType: s.serviceType ?? '',
                  quantity: int.tryParse(s.qtyController.text.trim()) ?? 1,
                  unitPrice: (ref.read(serviceTypeProvider).valueOrNull ?? []).where((t) => t.name == s.serviceType).firstOrNull?.defaultPrice,
                  sortOrder: e.key,
                );
              }).toList(),
              hardwareItems: _items.where((i) => i.isFromInventory).toList().asMap().entries.map((e) {
                final h = e.value;
                return TemplateHardwareItem(
                  id: '${const Uuid().v4()}-hw-${e.key}',
                  name: h.nameController.text.trim(),
                  quantity: int.tryParse(h.qtyController.text.trim()) ?? 1,
                  unitSalePrice: h.inventoryItem?.defaultSalePrice,
                  inventoryItemId: h.inventoryItemId,
                );
              }).toList(),
      parts: _items.where((i) => !i.isFromInventory && i.nameController.text.trim().isNotEmpty).toList().asMap().entries.map((e) {
                final p = e.value;
                return TemplatePartItem(
                  id: '${const Uuid().v4()}-part-${e.key}',
                  name: p.nameController.text.trim(),
                  quantity: int.tryParse(p.qtyController.text.trim()) ?? 1,
                  unitPrice: null,
                  inventoryItemId: p.inventoryItemId,
                );
              }).toList(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await ref.read(jobTemplateProvider.notifier).saveTemplate(template);
          }
        }
      }

      if (_isRecurring && _finalCustomerId != null) {
        final addDays = switch (_recurringInterval) {
          'weekly' => 7,
          'monthly' => 30,
          'quarterly' => 90,
          _ => 30,
        };
        await ref.read(recurringScheduleProvider.notifier).add(
          customerId: _finalCustomerId!,
          customerName: _customerController.text.trim(),
          serviceType: _serviceType!,
          intervalType: _recurringInterval,
          nextDueDate: _jobDate.add(Duration(days: addDays)),
          notes: _notesController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        await KsSuccessMoment.show(context,
          title: "Job Saved",
          subtitle: job.isSynced ? null : "Saved locally",
        );
      }
    } else {
      final error = ref.read(logJobProvider).errorMessage;
      if (error != null && error.isNotEmpty) {
        KsSlidingNotification.show(context, message: error, type: KsNotificationType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logJobProvider);

    return KsStepDrawer(
      title: "ADD NEW JOB",
      showBackArrow: true,
      onBack: () => _confirmDiscard().then((ok) {
        if (ok && mounted) Navigator.of(context).pop();
      }),
      steps: const [
        KsStep(label: 'TEMPLATE', icon: LineAwesomeIcons.clipboard_solid, subSteps: 1,
          tip: 'Choose a saved template or start fresh',
          imageAsset: 'assets/icons/3d/transparent/65d841-file-text.png'),
        KsStep(label: 'SERVICE', icon: LineAwesomeIcons.wrench_solid, subSteps: 1,
          tip: 'Select the main service performed',
          imageAsset: 'assets/icons/3d/transparent/ff5be0-tools.png'),
        KsStep(label: 'STATUS', icon: LineAwesomeIcons.flag_solid, subSteps: 1,
          tip: 'Set the job status',
          imageAsset: 'assets/icons/3d/transparent/e9828b-flag.png'),
        KsStep(label: 'CUSTOMER', icon: LineAwesomeIcons.user_solid, subSteps: 1,
          tip: 'Enter customer information',
          imageAsset: 'assets/icons/3d/transparent/eec43d-chat-bubble.png'),
        KsStep(label: 'PRICING', icon: LineAwesomeIcons.money_bill_wave_alt_solid, subSteps: 1,
          tip: 'Set the quoted or final amount',
          imageAsset: 'assets/icons/3d/transparent/b801dc-3d-coin.png'),
        KsStep(label: 'SCHEDULE', icon: LineAwesomeIcons.calendar_solid, subSteps: 1,
          tip: 'Set the job date and schedule',
          imageAsset: 'assets/icons/3d/transparent/781f28-calendar.png'),
        KsStep(label: 'EXTRAS', icon: LineAwesomeIcons.boxes_solid, subSteps: 1,
          tip: 'Add parts, expenses, photos, and notes',
          imageAsset: 'assets/icons/3d/transparent/4f52f8-cube.png'),
      ],
      nextLabel: "NEXT STEP",
      saveLabel: "SAVE JOB RECORD",
      canAdvance: (step, subStep) => _canMoveForwardForStep(step),
      onSave: _onSave,
      onClose: () => _confirmDiscard().then((ok) {
        if (ok && mounted) Navigator.of(context).pop();
      }),
      stepContent: (step, subStep, rebuild, advance) {
        // Inject save-as-template button into step 6 (EXTRAS)
        if (step == 6) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStepByIndex(step, advance),
                const SizedBox(height: 16),
                if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                InkWell(
                  onTap: _saveAsTemplate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SAVE AS TEMPLATE',
                      style: AppTextStyles.label.copyWith(
                        color: context.ksc.accent500,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),        // close InkWell
            ],          // close children
          ),            // close Column
        );              // close Padding + return
      }                 // close if block
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _buildStepByIndex(step, advance),
      );
    },
  );
}

  Widget _buildStepByIndex(int step, VoidCallback? advance) {
    switch (step) {
      case 0: return _buildStep0(advance);
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      case 3: return _buildStep3();
      case 4: return _buildStep4();
      case 5: return _buildStep5();
      case 6: return _buildStep6();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildStep0(VoidCallback? advance) {
    final templatesAsync = ref.watch(jobTemplateProvider);
    final templates = templatesAsync.valueOrNull ?? [];

    if (templatesAsync.hasError && templates.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          KsSlidingNotification.show(context,
            message: 'Could not load templates',
            type: KsNotificationType.error);
        }
      });
    }

    if (templates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: KsEmptyState(
          icon: LineAwesomeIcons.clipboard_solid,
          title: 'NO TEMPLATES YET',
          subtitle: 'Save a job as a template from the EXTRAS step\nto reuse it here.',
          actionLabel: 'START FRESH',
          onAction: advance,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...templates.map((t) => _buildTemplateCard(t, advance)),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: advance,
          icon: const Icon(LineAwesomeIcons.plus_solid, size: 14),
          label: Text('START FRESH',
            style: AppTextStyles.label.copyWith(
              color: context.ksc.accent500,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.ksc.accent500,
            side: BorderSide(color: context.ksc.accent500, width: 1.5),
            minimumSize: const Size(double.infinity, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(JobTemplateEntity template, VoidCallback? advance) {
    final serviceIcon = ServiceIconMap.resolve(template.serviceType);
    final partsSummary = <String>[];
    if (template.services.isNotEmpty) {
      partsSummary.add('${template.services.length} additional service${template.services.length > 1 ? 's' : ''}');
    }
    if (template.hardwareItems.isNotEmpty) {
      partsSummary.add('${template.hardwareItems.length} hardware item${template.hardwareItems.length > 1 ? 's' : ''}');
    }
    if (template.parts.isNotEmpty) {
      partsSummary.add('${template.parts.length} part${template.parts.length > 1 ? 's' : ''}');
    }
    final summaryStr = partsSummary.isNotEmpty ? partsSummary.join(', ') : 'No additional items';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          _applyTemplate(template);
          advance?.call();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.ksc.primary700,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(serviceIcon, color: context.ksc.accent500, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name,
                      style: AppTextStyles.body.copyWith(
                        color: context.ksc.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(template.serviceType,
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.accent500, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(summaryStr,
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.neutral500, fontSize: 10)),
                  ],
                ),
              ),
              Icon(LineAwesomeIcons.angle_right_solid,
                color: context.ksc.neutral500, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return JobStepService(
      serviceType: _serviceType,
      additionalServices: _additionalServices,
      onServiceTypeChanged: (t) => setState(() {
        _serviceType = t;
      }),
      onOpenAdditionalServices: _showAdditionalServicesDrawer,
    );
  }

  Widget _buildStep2() {
    return JobStepStatus(
      status: _status,
      leadSource: _leadSource,
      onStatusChanged: (v) => setState(() {
        _status = v;
        // Auto-reset payment to the first allowed option if current is invalid
        final allowed = JobEntity.allowedPaymentStatuses(v);
        if (!allowed.contains(_paymentStatus)) {
          _paymentStatus = allowed.first;
        }
      }),
      onLeadSourceChanged: (v) => setState(() => _leadSource = v),
    );
  }

  Widget _buildStep3() {
    return JobStepCustomer(
      customerController: _customerController,
      phoneController: _phoneController,
      matchedCustomerName: _matchedCustomerName,
      matchedCustomerId: _matchedCustomerId,
      preSelectedCustomerId: widget.preSelectedCustomerId != null,
      onPhoneChanged: _onPhoneChanged,
    );
  }

  void _onPhoneChanged(String value) {
    _phoneLookupDebounce?.cancel();

    // Auto-prepend '0' if user typed 9 digits without leading zero
    // e.g. "241234567" → "0241234567" — PhoneFormatter normalizes both identically
    if (value.length == 9 && !value.startsWith('0')) {
      _phoneController.text = '0$value';
      return;
    }

    if (value.length == 10 && value.startsWith('0')) {
      _lastLookupPhone = value;
      _phoneLookupDebounce = Timer(const Duration(milliseconds: 300), () {
        _lookupCustomer(value);
      });
    } else {
      if (_matchedCustomerName != null) {
        setState(() {
          _matchedCustomerName = null;
          _matchedCustomerId = null;
          _finalCustomerId = null;
        });
      }
    }
  }

  Future<void> _lookupCustomer(String phone) async {
    try {
      final normalized = PhoneFormatter.normalize(phone);
      final repo = ref.read(customerRepositoryProvider);
      final customer = await repo.getCustomerByPhone(normalized);

      // Stale check — a newer lookup has since been triggered
      if (_lastLookupPhone != phone) return;

      if (customer != null && mounted) {
        final typedName = _customerController.text.trim().toLowerCase();
        final matchedName = customer.fullName.toLowerCase();

        if (typedName.isNotEmpty && typedName != matchedName) {
          // Name mismatch — prompt user
          final useExisting = await KsConfirmDialog.show(
            context,
            title: 'CUSTOMER NAME MISMATCH',
            message: 'Phone belongs to ${customer.fullName.toUpperCase()}.\n\n'
                'You entered: ${_customerController.text.trim().toUpperCase()}\n\n'
                'Use the existing customer name?',
            confirmLabel: 'USE EXISTING',
            cancelLabel: 'KEEP MY NAME',
            isDanger: false,
            onConfirm: () {},
          );

          if (useExisting == true && mounted) {
            setState(() {
              _customerController.text = customer.fullName;
              _matchedCustomerName = customer.fullName;
              _matchedCustomerId = customer.id;
              _finalCustomerId = customer.id;
            });
          } else if (mounted) {
            setState(() {
              _matchedCustomerName = null;
              _matchedCustomerId = null;
              _finalCustomerId = null;
            });
          }
        } else {
          // Name matches (or empty) — silently link
          setState(() {
            _matchedCustomerName = customer.fullName;
            _matchedCustomerId = customer.id;
            _finalCustomerId = customer.id;
            if (typedName.isEmpty) {
              _customerController.text = customer.fullName;
            }
          });
        }
      } else if (mounted && _matchedCustomerName != null) {
        setState(() {
          _matchedCustomerName = null;
          _matchedCustomerId = null;
          _finalCustomerId = null;
        });
      }
    } catch (_) {
      if (mounted) {
        KsSlidingNotification.show(context,
          message: 'Could not check for existing customer',
          type: KsNotificationType.error);
      }
    }
  }

  Widget _buildStep4() {
    return JobStepPricing(
      quotedAmountController: _quotedAmountController,
      amountController: _amountController,
      quotedFocusNode: _quotedFocusNode,
      amountFocusNode: _amountFocusNode,
      jobStatus: _status,
      paymentStatus: _paymentStatus,
      onPaymentStatusChanged: (v) => setState(() => _paymentStatus = v),
    );
  }

  Widget _buildStep5() {
    return JobStepSchedule(
      isRecurring: _isRecurring,
      recurringInterval: _recurringInterval,
      jobDate: _jobDate,
      locationController: _locationController,
      onRecurringChanged: (v) => setState(() => _isRecurring = v),
      onIntervalChanged: (v) => setState(() => _recurringInterval = v),
      onDateChanged: (v) => setState(() => _jobDate = v),
    );
  }

  Widget _buildStep6() {
    return JobStepExtras(
      customerId: _finalCustomerId,
      itemCount: _items.length,
      expenseCount: _expenses.length,
      expenseTotal: _expenses.fold<int>(0, (sum, e) =>
        sum + (CurrencyFormatter.parseToPesewas(e.amountController.text.trim()) ?? 0)),
      photoCount: _generalPhotos.length + _beforePhotos.length + _afterPhotos.length,
      notesPreview: _notesController.text.trim().isEmpty ? null : _notesController.text.trim().length > 25 ? '${_notesController.text.trim().substring(0, 25)}…' : _notesController.text.trim(),
      onOpenItems: _showItemsDrawer,
      onOpenExpenses: _showExpensesDrawer,
      onOpenMedia: _showPhotosDrawer,
      onOpenNotes: _showNotesDrawer,
      onBrandSuggestionTapped: (brand) {
        setState(() {
          if (_items.isEmpty || _items.last.nameController.text.isNotEmpty) {
            _items.add(ItemRow());
          }
          _items.last.nameController.text = brand;
        });
      },
      onPartSuggestionTapped: (part) {
        setState(() {
          if (_items.isEmpty || _items.last.nameController.text.isNotEmpty) {
            _items.add(ItemRow());
          }
          _items.last.nameController.text = part;
        });
      },
    );
  }

  Widget _buildPartRow(int index, PartRow part) {
    final showSuggestions = _partSuggestionIndex == index && _partSuggestions.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: _buildDarkField(
              label: "Part Name", hint: "Deadbolt", controller: part.nameController,
              onChanged: (v) {
                final items = ref.read(inventoryProvider).valueOrNull ?? [];
                final matches = items.where((i) =>
                  i.category == InventoryItemCategory.consumable &&
                  i.name.toLowerCase().contains(v.toLowerCase())
                ).take(5).toList();
                setState(() {
                  _partSuggestionIndex = matches.isNotEmpty ? index : -1;
                  _partSuggestions = matches;
                });
              },
            )),
            const SizedBox(width: 8),
            Expanded(flex: 1, child: _buildDarkField(label: "Qty", hint: "1", controller: part.qtyController, isNumeric: true)),
            IconButton(icon: Icon(LineAwesomeIcons.times_solid, color: context.ksc.error500, size: 18), onPressed: () => setState(() => _parts.removeAt(index))),
          ],
        ),
        if (showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _partSuggestions.map((item) {
                return InkWell(
                  onTap: () {
                    part.nameController.text = item.name;
                    part.inventoryItemId = item.id;
                    setState(() {
                      _partSuggestionIndex = -1;
                      _partSuggestions = [];
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(item.name, style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        Padding(
          padding: EdgeInsets.only(top: 4),
          child: Divider(height: 1, color: context.ksc.primary700),
        ),
      ],
    );
  }


  Widget _buildHardwareRow(int index, HardwareRow hw, {VoidCallback? onRemove}) {
    final showSuggestions = _hwSuggestionIndex == index && _hwSuggestions.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("ITEM ${index + 1}", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)),
            const Spacer(),
            IconButton(
              icon: Icon(LineAwesomeIcons.times_solid, color: context.ksc.error500, size: 18),
              onPressed: onRemove ?? () => setState(() => _hardwareItems.removeAt(index)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildDarkField(
                label: "Hardware Name", hint: "e.g. Yale 210",
                controller: hw.nameController,
                onChanged: (v) {
                  final items = ref.read(inventoryProvider).valueOrNull ?? [];
                  final matches = items.where((i) =>
                    i.category == InventoryItemCategory.lock &&
                    i.name.toLowerCase().contains(v.toLowerCase())
                  ).take(5).toList();
                  setState(() {
                    _hwSuggestionIndex = matches.isNotEmpty ? index : -1;
                    _hwSuggestions = matches;
                  });
                },
              ),
            ),
          ],
        ),
        if (showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E2A3A), width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _hwSuggestions.map((item) {
                return InkWell(
                  onTap: () {
                    hw.nameController.text = item.name;
                    hw.inventoryItemId = item.id;
                    setState(() {
                      _hwSuggestionIndex = -1;
                      _hwSuggestions = [];
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(LineAwesomeIcons.lock_solid, size: 14, color: context.ksc.accent500),
                        const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w600)),
                                  if (item.brand != null)
                                    Text(item.brand!, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDarkField(label: "Qty", hint: "1", controller: hw.qtyController, isNumeric: true),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Divider(height: 1, color: Color(0xFF1E2A3A)),
        ),
      ],
    );
  }

  /// Compact card for hardware selected from inventory.
  Widget _buildInventoryHardwareCard(int index, HardwareRow hw) {
    final item = hw.inventoryItem;

    return Column(
      children: [
        Row(
          children: [
            Icon(LineAwesomeIcons.lock_solid, size: 16, color: context.ksc.accent500),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item?.name.toUpperCase() ?? 'HARDWARE',
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _buildQtyStepper(hw),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(LineAwesomeIcons.times_solid, color: context.ksc.error500, size: 16),
              onPressed: () => setState(() => _hardwareItems.removeAt(index)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Divider(height: 1, color: Color(0xFF1E2A3A)),
        ),
      ],
    );
  }

  /// Qty stepper with [-] [+] buttons
  Widget _buildQtyStepper(HardwareRow hw) {
    final qty = int.tryParse(hw.qtyController.text) ?? 1;
    return Container(
      decoration: BoxDecoration(
        color: context.ksc.primary900,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              if (qty > 1) {
                setState(() => hw.qtyController.text = (qty - 1).toString());
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(LineAwesomeIcons.minus_solid, size: 12, color: context.ksc.neutral500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$qty',
              style: AppTextStyles.caption.copyWith(
                color: context.ksc.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() => hw.qtyController.text = (qty + 1).toString());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(LineAwesomeIcons.plus_solid, size: 12, color: context.ksc.neutral500),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet to pick hardware from inventory.
  void _showInventoryPicker({void Function(HardwareRow item)? onItemSelected}) {
    final items = ref.read(inventoryProvider).valueOrNull ?? [];
    final hardwareItems = items.where((i) => i.category == InventoryItemCategory.lock && !i.isArchived).toList();
    final searchCtrl = TextEditingController();

    KsBottomSheetScaffold.show(
      context,
      title: "SELECT HARDWARE ITEM",
      bottomLabel: null,
      contentBuilder: (ctx, setSheetState) {
        final query = searchCtrl.text.toLowerCase().trim();
        final filtered = query.isEmpty
            ? hardwareItems
            : hardwareItems.where((i) =>
                i.name.toLowerCase().contains(query) ||
                (i.brand?.toLowerCase().contains(query) ?? false) ||
                i.category.displayName.toLowerCase().contains(query)
              ).toList();

        return Column(
          children: [
            // Search field
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: context.ksc.primary900,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: context.ksc.primary700),
              ),
              child: TextField(
                controller: searchCtrl,
                onChanged: (_) => setSheetState(() {}),
                style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w600),
                cursorColor: context.ksc.accent500,
                decoration: InputDecoration(
                  hintText: "Search by name, brand...",
                  hintStyle: AppTextStyles.caption.copyWith(color: context.ksc.neutral600),
                  prefixIcon: Icon(LineAwesomeIcons.search_solid, color: context.ksc.neutral500, size: 18),
                  suffixIcon: searchCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            searchCtrl.clear();
                            setSheetState(() {});
                          },
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 18),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // List
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.45,
              ),
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: KsEmptyState(
                        icon: LineAwesomeIcons.lock_solid,
                        title: "NO HARDWARE ITEMS",
                        subtitle: "Add hardware items to your inventory first",
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: context.ksc.primary700),
                      itemBuilder: (_, i) {
                        final invItem = filtered[i];
                        final stockStatus = invItem.isLowStock
                            ? "${invItem.quantity} left (low)"
                            : "Stock: ${invItem.quantity}";
                        return InkWell(
                          onTap: () {
                            final hw = HardwareRow();
                            hw.inventoryItem = invItem;
                            hw.inventoryItemId = invItem.id;
                            hw.nameController.text = invItem.name;
                            hw.qtyController.text = '1';
                            if (onItemSelected != null) {
                              onItemSelected(hw);
                            } else {
                              setState(() => _hardwareItems.add(hw));
                            }
                            Navigator.pop(ctx);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                            child: Row(
                              children: [
                                Icon(LineAwesomeIcons.lock_solid, size: 16, color: context.ksc.accent500),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(invItem.name.toUpperCase(),
                                        style: AppTextStyles.body.copyWith(
                                          color: context.ksc.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        invItem.brand != null
                                            ? "${invItem.brand} · $stockStatus"
                                            : stockStatus,
                                        style: AppTextStyles.caption.copyWith(
                                          color: context.ksc.neutral500,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (invItem.defaultSalePrice != null)
                                  Text(
                                    CurrencyFormatter.format(invItem.defaultSalePrice!),
                                    style: AppTextStyles.caption.copyWith(
                                      color: context.ksc.accent500,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmDrawerClose(BuildContext sheetCtx) async {
    return await KsConfirmDialog.show(
      sheetCtx,
      title: 'DISCARD CHANGES?',
      message: 'You have unsaved changes. Discard them?',
      confirmLabel: 'DISCARD',
      cancelLabel: 'KEEP EDITING',
      isDanger: true,
      onConfirm: () => Navigator.pop(sheetCtx),
    ) ?? false;
  }

  void _showAdditionalServicesDrawer() {
    final localServices = _additionalServices.map((s) {
      final copy = ServiceRow();
      copy.serviceType = s.serviceType;
      copy.qtyController.text = s.qtyController.text;
      copy.priceController.text = s.priceController.text;
      return copy;
    }).toList();
    bool dirty = false;

    final svcCount = localServices.length;
    KsBottomSheetScaffold.show<bool>(
      context,
      title: "ADDITIONAL SERVICES",
      subtitle: svcCount > 0
          ? "$svcCount service${svcCount > 1 ? 's' : ''}"
          : "Tap a service below to add it to this job",
      isDirty: () => dirty,
      bottomLabel: "DONE",
      onDone: () {
        setState(() {
          _additionalServices
            ..clear()
            ..addAll(localServices);
        });
      },
      contentBuilder: (ctx, setSheetState) {
        final typesAsync = ref.watch(serviceTypeProvider);
        final types = typesAsync.valueOrNull ?? [];

        final grouped = <String, List>{};
        for (final t in types) {
          grouped.putIfAbsent(t.category, () => []).add(t);
        }
        final categories = grouped.keys.toList()..sort();

        return Column(
          children: [
            if (localServices.isNotEmpty) ...[
              ...localServices.asMap().entries.map((entry) {
                return _buildAdditionalServiceSummaryCard(
                  service: entry.value,
                  types: types,
                  onTap: () {
                    _showServiceEditDrawer(
                      service: entry.value,
                      existingIndex: entry.key,
                      onChanged: () {
                        dirty = true;
                        setSheetState(() {});
                      },
                    );
                  },
                  onRemove: () {
                    localServices.removeAt(entry.key);
                    entry.value.dispose();
                    dirty = true;
                    setSheetState(() {});
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
            ...categories.map((cat) {
              final items = grouped[cat]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(cat.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.neutral500,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  ...items.map((type) {
                    final alreadyAdded = localServices.any((s) => s.serviceType == type.name);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: alreadyAdded ? null : () async {
                          final row = ServiceRow();
                          row.serviceType = type.name;
                          final added = await _showServiceEditDrawer(
                            service: row,
                            existingIndex: null,
                            onChanged: () {
                              localServices.add(row);
                              dirty = true;
                              setSheetState(() {});
                            },
                          );
                          if (!added) row.dispose();
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: alreadyAdded ? context.ksc.primary700.withValues(alpha: 0.3) : context.ksc.primary800,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: alreadyAdded ? context.ksc.neutral600 : context.ksc.accent500.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                ServiceIconMap.resolve(type.iconName),
                                size: 18,
                                color: alreadyAdded ? context.ksc.neutral600 : context.ksc.accent500,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(type.name.replaceAll('_', ' ').toUpperCase(),
                                  style: AppTextStyles.body.copyWith(
                                    color: alreadyAdded ? context.ksc.neutral600 : context.ksc.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (type.defaultPrice != null && type.defaultPrice! > 0)
                                Text(CurrencyFormatter.format(type.defaultPrice!),
                                  style: AppTextStyles.caption.copyWith(
                                    color: alreadyAdded ? context.ksc.neutral600 : context.ksc.accent500,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                              if (alreadyAdded)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(LineAwesomeIcons.check_circle_solid, size: 16, color: context.ksc.neutral600),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    ).then((committed) {
      if (committed != true) {
        for (final s in localServices) {
          s.dispose();
        }
      }
    });
  }

  /// Read-only summary card for a selected service in Drawer 1.
  /// Tapping opens the edit drawer (Drawer 2).
  Widget _buildAdditionalServiceSummaryCard({
    required ServiceRow service,
    required List<ServiceTypeEntity> types,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final qty = int.tryParse(service.qtyController.text) ?? 1;
    final svcType = types.where((t) => t.name == service.serviceType).firstOrNull;
    final unitPrice = (svcType?.defaultPrice ?? 0);
    final total = qty * unitPrice;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1)),
            ),
            child: Row(
              children: [
                Icon(
                  ServiceIconMap.resolve(svcType?.iconName),
                size: 20,
                color: context.ksc.accent500,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.serviceType?.replaceAll('_', ' ').toUpperCase() ?? '',
                      style: AppTextStyles.body.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Qty: $qty × ${CurrencyFormatter.format(unitPrice)}",
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.neutral500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    total > 0 ? CurrencyFormatter.format(total) : "GHS 0.00",
                    style: AppTextStyles.h3.copyWith(
                      color: context.ksc.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(LineAwesomeIcons.times_circle_solid, color: context.ksc.error500, size: 20),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Drawer 2: Edit qty + price for a single service.
  /// If [existingIndex] is null, the service is new (ADD mode).
  /// If [existingIndex] is set, it's editing an existing service.
  Future<bool> _showServiceEditDrawer({
    required ServiceRow service,
    required int? existingIndex,
    required VoidCallback onChanged,
  }) async {
    bool validationOk = true;
    final result = await KsBottomSheetScaffold.show<bool>(
      context,
      title: existingIndex != null ? "EDIT SERVICE" : "ADD SERVICE",
      bottomLabel: existingIndex != null ? "SAVE" : "ADD",
      onDone: () {
        // Validate qty
        final qty = int.tryParse(service.qtyController.text.trim());
        validationOk = qty != null && qty > 0;
        if (!validationOk) {
          KsSlidingNotification.show(context, message: 'Quantity must be a positive number', type: KsNotificationType.error);
        }
      },
      canPop: () => validationOk,
      contentBuilder: (ctx, setSheetState) {
        final qty = int.tryParse(service.qtyController.text) ?? 1;
        final customPrice = CurrencyFormatter.parseToPesewas(service.priceController.text.trim());
        final types = ref.read(serviceTypeProvider).valueOrNull ?? [];
        final svcType = types.where((t) => t.name == service.serviceType).firstOrNull;
        final unitPrice = customPrice ?? (svcType?.defaultPrice ?? 0);
        final total = qty * unitPrice;

        return Column(
          children: [
            // Service icon + name (read-only)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(
                    ServiceIconMap.resolve(svcType?.iconName),
                    size: 24,
                    color: context.ksc.accent500,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      service.serviceType?.replaceAll('_', ' ').toUpperCase() ?? '',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Qty row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text("QTY",
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral600,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildDrawerQtyStepper(service.qtyController, () => setSheetState(() {})),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Unit price field (underline only)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("UNIT PRICE (GHS)",
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral600,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: service.priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [CurrencyInputFormatter()],
                          onChanged: (_) => setSheetState(() {}),
                          style: AppTextStyles.body.copyWith(
                            color: context.ksc.accent500,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: "0.00",
                            hintStyle: AppTextStyles.body.copyWith(
                              color: context.ksc.neutral600,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.only(bottom: 4),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF2A3A4A), width: 1),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF4A90D9), width: 1.5),
                            ),
                            filled: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("GHS",
                        style: AppTextStyles.caption.copyWith(
                          color: context.ksc.neutral500,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Total display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("TOTAL",
                        style: AppTextStyles.caption.copyWith(
                          color: context.ksc.neutral600,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        total > 0 ? CurrencyFormatter.format(total) : "GHS 0.00",
                        style: AppTextStyles.h2.copyWith(
                          color: context.ksc.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      onChanged();
      return true;
    }
    return false;
  }

  Widget _buildDrawerQtyStepper(TextEditingController controller, VoidCallback onChanged) {
    final qty = int.tryParse(controller.text) ?? 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (qty > 1) {
              controller.text = (qty - 1).toString();
              onChanged();
            }
          },
          child: Icon(LineAwesomeIcons.minus_solid, size: 14, color: context.ksc.neutral500),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('$qty',
            style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
        GestureDetector(
          onTap: () {
            controller.text = (qty + 1).toString();
            onChanged();
          },
          child: Icon(LineAwesomeIcons.plus_solid, size: 14, color: context.ksc.neutral500),
        ),
      ],
    );
  }

  void _showHardwareDrawer() {
    final localItems = _hardwareItems.map((h) => h.copy()).toList();
    bool dirty = false;

    KsBottomSheetScaffold.show(
      context,
      title: "HARDWARE ITEMS",
      isDirty: () => dirty,
      bottomLabel: "DONE",
      onDone: () {
        setState(() {
          _hardwareItems
            ..clear()
            ..addAll(localItems);
        });
      },
      contentBuilder: (ctx, setSheetState) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showInventoryPicker(
                    onItemSelected: (hw) {
                      localItems.add(hw);
                      dirty = true;
                      setSheetState(() {});
                    },
                  );
                },
                icon: Icon(LineAwesomeIcons.search_solid, size: 16, color: context.ksc.accent500),
                label: Text("SELECT FROM INVENTORY",
                  style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.ksc.accent500.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...localItems.asMap().entries.map((entry) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: entry.value.isFromInventory
                    ? _buildInventoryHardwareCard(entry.key, entry.value)
                    : _buildHardwareRow(
                        entry.key,
                        entry.value,
                        onRemove: () {
                          localItems.removeAt(entry.key);
                          dirty = true;
                          setSheetState(() {});
                        },
                      ),
              ),
            ),
            if (localItems.isNotEmpty) const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  localItems.add(HardwareRow());
                  dirty = true;
                  setSheetState(() {});
                },
                icon: Icon(LineAwesomeIcons.plus_solid, size: 14, color: context.ksc.neutral500),
                label: Text("Add Manual Entry",
                  style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      },
    );
  }
  void _showExpensesDrawer() {
    final localExpenses = _expenses.map((e) => e.copy()).toList();
    bool dirty = false;

    KsBottomSheetScaffold.show(
      context,
      title: "EXPENSES",
      subtitle: localExpenses.isNotEmpty
          ? "${localExpenses.length} expense${localExpenses.length > 1 ? 's' : ''} · ${
              CurrencyFormatter.format(localExpenses.fold<int>(0, (sum, e) =>
                sum + (CurrencyFormatter.parseToPesewas(e.amountController.text.trim()) ?? 0)))
            }"
          : "No expenses added",
      isDirty: () => dirty,
      bottomLabel: "DONE",
      onDone: () {
        setState(() {
          _expenses
            ..clear()
            ..addAll(localExpenses);
        });
      },
      contentBuilder: (ctx, setSheetState) {
        return Column(
          children: [
            // Expense cards
            ...localExpenses.asMap().entries.map((entry) =>
              _buildExpenseSummaryCard(
                expense: entry.value,
                onTap: () {
                  _openExpenseEditDrawer(
                    expense: entry.value,
                    existingIndex: entry.key,
                    onChanged: () {
                      dirty = true;
                      setSheetState(() {});
                    },
                  );
                },
                onRemove: () {
                  localExpenses.removeAt(entry.key);
                  entry.value.dispose();
                  dirty = true;
                  setSheetState(() {});
                  // Rebuild subtitle via setSheetState
                },
              ),
            ),
            const SizedBox(height: 12),
            // ADD EXPENSE button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final row = ExpenseRow();
                  _openExpenseEditDrawer(
                    expense: row,
                    existingIndex: null,
                    onChanged: () {
                      localExpenses.add(row);
                      dirty = true;
                      setSheetState(() {});
                    },
                  );
                },
                icon: Icon(LineAwesomeIcons.plus_solid, size: 16, color: context.ksc.accent500),
                label: Text("ADD EXPENSE",
                  style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.ksc.accent500.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Summary card for an expense in the list — shows category emoji, name, description, amount.
  Widget _buildExpenseSummaryCard({
    required ExpenseRow expense,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final amt = CurrencyFormatter.parseToPesewas(expense.amountController.text.trim());
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.ksc.primary700),
          ),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: context.ksc.accent500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(_expenseCategoryEmoji(expense.category), style: const TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.category.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800),
                    ),
                    if (expense.descriptionController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(expense.descriptionController.text,
                          style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              // Amount
              Text(
                amt != null ? CurrencyFormatter.format(amt) : "GHS 0.00",
                style: AppTextStyles.body.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, fontSize: 13),
              ),
              const SizedBox(width: 4),
              // Delete
              IconButton(
                icon: Icon(LineAwesomeIcons.times_circle_solid, color: context.ksc.error500, size: 20),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a bottom sheet with the 5 expense categories. Returns the selected value or null.
  Future<String?> _openExpenseCategorySheet({required String current}) async {
    final categories = ['transport', 'parking', 'subcontractor', 'supplies', 'other'];
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        String selected = current;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: Row(
                      children: [
                        Expanded(child: Text("SELECT CATEGORY",
                            style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900))),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Category options
                  ...categories.map((cat) {
                    final isSelected = selected == cat;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 3),
                      child: InkWell(
                        onTap: () {
                          selected = cat;
                          setSheetState(() {});
                          Navigator.pop(ctx, cat);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? context.ksc.accent500 : context.ksc.accent500.withValues(alpha: 0.25),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(_expenseCategoryEmoji(cat), style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(cat.replaceAll('_', ' ').toUpperCase(),
                                  style: AppTextStyles.body.copyWith(
                                    color: isSelected ? context.ksc.white : context.ksc.neutral400,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(LineAwesomeIcons.check_circle_solid, size: 18, color: context.ksc.accent500),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
    return result;
  }

  /// Dedicated drawer for ADD / EDIT an expense.
  /// Follows the same pattern as _showServiceEditDrawer and _showItemEditDrawer.
  Future<bool> _openExpenseEditDrawer({
    required ExpenseRow expense,
    required int? existingIndex,
    required VoidCallback onChanged,
  }) async {
    // Pre-populate category if empty
    if (expense.category == 'transport') { /* default */ }
    bool dirty = false;

    bool validationOk = true;

    final result = await KsBottomSheetScaffold.show<bool>(
      context,
      title: existingIndex != null ? "EDIT EXPENSE" : "ADD EXPENSE",
      bottomLabel: existingIndex != null ? "SAVE" : "ADD",
      onDone: () {
        final amt = CurrencyFormatter.parseToPesewas(expense.amountController.text.trim());
        validationOk = amt != null && amt > 0;
        if (!validationOk) {
          KsSlidingNotification.show(context, message: 'Enter an amount greater than 0', type: KsNotificationType.error);
        }
      },
      canPop: () => validationOk,
      contentBuilder: (ctx, setSheetState) {
        final qty = 1; // single expense
        final amt = CurrencyFormatter.parseToPesewas(expense.amountController.text.trim());
        final total = amt ?? 0;

        return Column(
          children: [
            // Category picker — tappable, opens bottom sheet
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("CATEGORY",
                    style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, fontWeight: FontWeight.w800, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final newCat = await _openExpenseCategorySheet(current: expense.category);
                      if (newCat != null && ctx.mounted) {
                        expense.category = newCat;
                        setSheetState(() {});
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Text(_expenseCategoryEmoji(expense.category), style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(expense.category.replaceAll('_', ' ').toUpperCase(),
                              style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Icon(LineAwesomeIcons.angle_down_solid, size: 14, color: context.ksc.neutral500),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Amount (GHS)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("AMOUNT (GHS)",
                    style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, fontWeight: FontWeight.w800, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: expense.amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [CurrencyInputFormatter()],
                          onChanged: (_) => setSheetState(() {}),
                          style: AppTextStyles.body.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "0.00",
                            hintStyle: AppTextStyles.body.copyWith(color: context.ksc.neutral600, fontWeight: FontWeight.w900, fontSize: 16),
                            isDense: true,
                            contentPadding: const EdgeInsets.only(bottom: 4),
                            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2A3A4A), width: 1)),
                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4A90D9), width: 1.5)),
                            filled: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("GHS", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("DESCRIPTION",
                    style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, fontWeight: FontWeight.w800, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: expense.descriptionController,
                    style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w600),
                    cursorColor: context.ksc.accent500,
                    decoration: InputDecoration(
                      hintText: "e.g. Troski fare to site",
                      hintStyle: AppTextStyles.caption.copyWith(color: context.ksc.neutral600),
                      isDense: true,
                      contentPadding: const EdgeInsets.only(bottom: 8),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2A3A4A), width: 1)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF4A90D9), width: 1.5)),
                      filled: false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Total
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("TOTAL",
                        style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        total > 0 ? CurrencyFormatter.format(total) : "GHS 0.00",
                        style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900, fontSize: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      onChanged();
      return true;
    }
    return false;
  }

  /// Emoji helper for expense category
  String _expenseCategoryEmoji(String category) {
    switch (category) {
      case 'transport': return '🚕';
      case 'parking': return '🅿️';
      case 'subcontractor': return '👷';
      case 'supplies': return '📦';
      case 'other': return '📋';
      default: return '📋';
    }
  }

  void _showPartsDrawer() {
    final localParts = _parts.map((p) => p.copy()).toList();
    bool dirty = false;

    KsBottomSheetScaffold.show(
      context,
      title: "PARTS USED",
      isDirty: () => dirty,
      bottomLabel: "DONE",
      onDone: () {
        setState(() {
          _parts
            ..clear()
            ..addAll(localParts);
        });
      },
      contentBuilder: (ctx, setSheetState) {
        return Column(
          children: [
            ...localParts.asMap().entries.map((entry) =>
              _buildPartRow(entry.key, entry.value)),
            if (localParts.length < 20)
              TextButton.icon(
                onPressed: () {
                  localParts.add(PartRow());
                  dirty = true;
                  setSheetState(() {});
                },
                icon: const Icon(LineAwesomeIcons.plus_solid, size: 16),
                label: Text("ADD PART",
                  style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
              ),
          ],
        );
      },
    );
  }
  void _showPhotosDrawer() {
    final localGeneral = List<XFile>.from(_generalPhotos);
    final localBefore = List<XFile>.from(_beforePhotos);
    final localAfter = List<XFile>.from(_afterPhotos);
    bool dirty = false;
    int selectedTab = 0; // 0=ALL, 1=BEFORE, 2=AFTER
    bool isLoading = false;

    KsBottomSheetScaffold.show(
      context,
      title: "MEDIA",
      subtitle: "${localGeneral.length + localBefore.length + localAfter.length} items · "
          "${localBefore.length} before · ${localAfter.length} after",
      isDirty: () => dirty,
      bottomLabel: "DONE",
      onDone: () {
        setState(() {
          _generalPhotos
            ..clear()
            ..addAll(localGeneral);
          _beforePhotos
            ..clear()
            ..addAll(localBefore);
          _afterPhotos
            ..clear()
            ..addAll(localAfter);
        });
      },
      // Tabs are sticky — outside scroll area
      stickyHeader: (ctx, setSheetState) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: context.ksc.primary900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Row(
          children: [
            _buildMediaTab("ALL", localGeneral.length + localBefore.length + localAfter.length, 0, selectedTab, () {
              selectedTab = 0;
              setSheetState(() {});
            }),
            const SizedBox(width: 3),
            _buildMediaTab("BEFORE", localBefore.length, 1, selectedTab, () {
              selectedTab = 1;
              setSheetState(() {});
            }),
            const SizedBox(width: 3),
            _buildMediaTab("AFTER", localAfter.length, 2, selectedTab, () {
              selectedTab = 2;
              setSheetState(() {});
            }),
          ],
        ),
      ),
      contentBuilder: (ctx, setSheetState) {
        final activeList = switch (selectedTab) {
          1 => localBefore,
          2 => localAfter,
          _ => localGeneral,
        };
        final label = switch (selectedTab) {
          1 => "BEFORE",
          2 => "AFTER",
          _ => "",
        };

        return _buildMediaGrid(
          files: activeList,
          label: label,
          isLoading: isLoading,
          onRemove: (index) {
            activeList.removeAt(index);
            dirty = true;
            setSheetState(() {});
          },
          onAdd: () async {
            final source = await _showMediaSourceSheet(ctx);
            if (source == null || !ctx.mounted) return;

            isLoading = true;
            setSheetState(() {});

            XFile? picked;
            if (source == 'camera' || source == 'gallery') {
              final imgSource = source == 'camera'
                  ? ImageSource.camera
                  : ImageSource.gallery;
              picked = await ImagePicker()
                  .pickImage(source: imgSource, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
            } else if (source == 'videocam') {
              picked = await ImagePicker()
                  .pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 60));
            } else if (source == 'videogallery') {
              picked = await ImagePicker()
                  .pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
            } else if (source == 'audio') {
              final hasPermission = await _audioRecorder.hasPermission();
              if (hasPermission && ctx.mounted) {
                final result = await showDialog<String>(
                  context: ctx,
                  barrierDismissible: false,
                  builder: (c) => _AudioRecordingDialog(recorder: _audioRecorder),
                );
                if (result != null) picked = XFile(result);
              }
            }

            isLoading = false;
            if (picked != null && ctx.mounted) {
              activeList.add(picked);
              dirty = true;
            }
            if (ctx.mounted) setSheetState(() {});
          },
        );
      },
    );
  }

  /// Tab button for ALL / BEFORE / AFTER toggle.
  Widget _buildMediaTab(String label, int count, int tabIndex, int selectedTab, VoidCallback onTap) {
    final active = tabIndex == selectedTab;
    final dotColor = switch (tabIndex) {
      0 => context.ksc.accent500,
      1 => const Color(0xFF6BB5FF),
      2 => const Color(0xFF4CAF50),
      _ => context.ksc.neutral500,
    };
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? context.ksc.accent500 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? context.ksc.primary900 : dotColor,
                ),
              ),
              const SizedBox(width: 6),
              Text("$label ($count)",
                style: AppTextStyles.caption.copyWith(
                  color: active ? context.ksc.primary900 : context.ksc.neutral400,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 2-column media grid with add button.
  Widget _buildMediaGrid({
    required List<XFile> files,
    required String label,
    required bool isLoading,
    required ValueChanged<int> onRemove,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Empty state with tappable ADD MEDIA
        if (files.isEmpty && !isLoading)
          InkWell(
            onTap: onAdd,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(LineAwesomeIcons.camera_solid, size: 36, color: context.ksc.neutral600),
                    const SizedBox(height: 12),
                    Text(label.isEmpty ? "NO MEDIA" : "NO $label MEDIA",
                      style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LineAwesomeIcons.plus_solid, size: 14, color: context.ksc.accent500),
                          const SizedBox(width: 6),
                          Text("ADD MEDIA",
                            style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // 2-col grid
        if (files.isNotEmpty || isLoading)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
            children: [
              ...files.asMap().entries.map((entry) =>
                _buildMediaCard(
                  file: entry.value,
                  onRemove: () => onRemove(entry.key),
                ),
              ),
              if (isLoading) _buildShimmerCard(),
              // Add button
              _buildMediaAddCard(onTap: isLoading ? null : onAdd),
            ],
          ),
      ],
    );
  }

  /// Add media card — dashed border + plus icon.
  Widget _buildMediaAddCard({VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: context.ksc.primary700, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LineAwesomeIcons.plus_solid, size: 24, color: context.ksc.accent500),
            const SizedBox(height: 6),
            Text("ADD MEDIA",
              style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  /// Single media card with type badge, play overlay, delete.
  Widget _buildMediaCard({
    required XFile file,
    required VoidCallback onRemove,
  }) {
    final path = file.path;
    final isVideo = path.endsWith('.mp4') || path.endsWith('.mov');
    final isAudio = path.endsWith('.m4a') || path.endsWith('.mp3') || path.endsWith('.wav');

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          // Thumbnail
          Container(
            width: double.infinity, height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: context.ksc.primary900,
              image: !isVideo && !isAudio
                  ? DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover)
                  : null,
              border: Border.all(color: context.ksc.primary700),
            ),
            child: isVideo
                ? Center(child: Icon(LineAwesomeIcons.video_solid, color: context.ksc.accent500, size: 28))
                : isAudio
                    ? Center(child: Icon(LineAwesomeIcons.microphone_solid, color: context.ksc.accent500, size: 28))
                    : null,
          ),
          // Play button overlay (video only)
          if (isVideo)
            Positioned(
              top: 0, bottom: 0, left: 0, right: 0,
              child: Center(
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: context.ksc.accent500,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                ),
              ),
            ),
          // Mic overlay (audio only)
          if (isAudio)
            Positioned(
              top: 0, bottom: 0, left: 0, right: 0,
              child: Center(
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: context.ksc.accent500,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(LineAwesomeIcons.microphone_solid, color: context.ksc.primary900, size: 14),
                ),
              ),
            ),
          // Type badge — bottom-left, solid colored bg
          Positioned(
            bottom: 4, left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isVideo
                    ? const Color(0xFF6BB5FF).withValues(alpha: 0.85)
                    : isAudio
                        ? const Color(0xFFB388FF).withValues(alpha: 0.85)
                        : context.ksc.accent500.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isVideo ? "VIDEO" : isAudio ? "AUDIO" : "PHOTO",
                style: AppTextStyles.caption.copyWith(
                  color: context.ksc.primary900,
                  fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          // Delete button (top-right)
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.error500, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer loading card.
  Widget _buildShimmerCard() {
    final size = (MediaQuery.of(context).size.width - 56) / 2;
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: context.ksc.primary900,
          border: Border.all(color: context.ksc.primary700),
        ),
      ),
    );
  }

  /// Unified source picker: Camera, Gallery, Video (cam), Video (gallery), Audio.
  Future<String?> _showMediaSourceSheet(BuildContext ctx) {
    return showModalBottomSheet<String>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (c) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Row(
                  children: [
                    Expanded(child: Text("ADD MEDIA",
                        style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900))),
                    GestureDetector(
                      onTap: () => Navigator.pop(c),
                      child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Options grid
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _sourceOption(c, LineAwesomeIcons.camera_solid, "Camera", 'camera'),
                        const SizedBox(width: 10),
                        _sourceOption(c, LineAwesomeIcons.image_solid, "Gallery", 'gallery'),
                        const SizedBox(width: 10),
                        _sourceOption(c, LineAwesomeIcons.video_solid, "Video (Cam)", 'videocam'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _sourceOption(c, LineAwesomeIcons.film_solid, "Video (Gallery)", 'videogallery'),
                        const SizedBox(width: 10),
                        _sourceOption(c, LineAwesomeIcons.microphone_solid, "Audio", 'audio'),
                        const Expanded(child: SizedBox()), // Spacer for symmetry
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Single source option — transparent bg, border, icon.
  Widget _sourceOption(BuildContext ctx, IconData icon, String label, String value) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pop(ctx, value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.ksc.primary700, width: 1),
              ),
              child: Icon(icon, size: 22, color: context.ksc.accent500),
            ),
            const SizedBox(height: 6),
            Text(label.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500, fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  void _showNotesDrawer() {
    final initialText = _notesController.text;
    bool dirty = false;

    KsBottomSheetScaffold.show(
      context,
      title: "NOTES",
      subtitle: "Job notes and comments",
      isDirty: () => dirty,
      bottomLabel: "DONE",
      onDone: () {},
      onClose: () {
        _notesController.text = initialText; // restore on discard
      },
      contentBuilder: (ctx, setSheetState) {
        return TextField(
          controller: _notesController,
          onChanged: (_) {
            if (!dirty) { dirty = true; setSheetState(() {}); }
          },
          maxLines: 5,
          maxLength: 2000,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: "Specific hardware used...",
            hintStyle: TextStyle(color: context.ksc.neutral500),
            contentPadding: const EdgeInsets.only(bottom: 8, top: 12),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.ksc.primary700, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.ksc.accent500, width: 1.5),
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: context.ksc.primary700),
            ),
            filled: false,
          ),
        );
      },
    );
  }
  void _showItemsDrawer() {
    final localItems = _items.map((i) => i.copy()).toList();
    bool dirty = false;

    KsBottomSheetScaffold.show<bool>(
      context,
      title: "ITEMS USED",
      isDirty: () => dirty,
      bottomLabel: "DONE",
      onDone: () {
        setState(() {
          _items
            ..clear()
            ..addAll(localItems);
        });
      },
      contentBuilder: (ctx, setSheetState) {
        final count = localItems.length;
        return Column(
          children: [
            if (localItems.isNotEmpty) ...[
              ...localItems.asMap().entries.map((entry) {
                return _buildItemSummaryCard(
                  item: entry.value,
                  onTap: () {
                    _showItemEditDrawer(
                      item: entry.value,
                      existingIndex: entry.key,
                      onChanged: () {
                        dirty = true;
                        setSheetState(() {});
                      },
                    );
                  },
                  onRemove: () {
                    localItems.removeAt(entry.key);
                    entry.value.dispose();
                    dirty = true;
                    setSheetState(() {});
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showItemSearchDrawer(
                    localItems: localItems,
                    onChanged: () {
                      dirty = true;
                      setSheetState(() {});
                    },
                  );
                },
                icon: Icon(LineAwesomeIcons.plus_solid, size: 16, color: context.ksc.accent500),
                label: Text("ADD ITEM", style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.ksc.accent500.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    ).then((committed) {
      if (committed != true) {
        for (final i in localItems) i.dispose();
      }
    });
  }

  Widget _buildItemSummaryCard({
    required ItemRow item,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final qty = int.tryParse(item.qtyController.text) ?? 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.ksc.primary700, width: 1)),
          ),
          child: Row(
            children: [
              Icon(
                item.isFromInventory ? LineAwesomeIcons.lock_solid : LineAwesomeIcons.box_solid,
                size: 20,
                color: context.ksc.accent500,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName.toUpperCase(),
                      style: AppTextStyles.body.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Qty: $qty · ${item.isFromInventory ? "From inventory" : "Manual entry"}",
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.neutral500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(LineAwesomeIcons.times_circle_solid, color: context.ksc.error500, size: 20),
                onPressed: onRemove,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemEditDrawer({
    required ItemRow item,
    required int? existingIndex,
    required VoidCallback onChanged,
  }) {
    bool validationOk = true;
    KsBottomSheetScaffold.show<bool>(
      context,
      title: existingIndex != null ? "EDIT ITEM" : "NEW ITEM",
      bottomLabel: existingIndex != null ? "SAVE" : "ADD",
      onDone: () {
        // Manual entry items need a name
        if (!item.isFromInventory) {
          validationOk = item.nameController.text.trim().isNotEmpty;
          if (!validationOk) {
            KsSlidingNotification.show(context, message: 'Enter an item name', type: KsNotificationType.error);
          }
        }
      },
      canPop: () => validationOk,
      contentBuilder: (ctx, setSheetState) {
        return Column(
          children: [
            if (item.isFromInventory) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(LineAwesomeIcons.lock_solid, size: 24, color: context.ksc.accent500),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.displayName.toUpperCase(),
                        style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text("From inventory",
                  style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontSize: 10),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildDarkField(
                  label: "Item Name", hint: "e.g. Mortise screw",
                  controller: item.nameController,
                  maxLength: 100,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text("QTY",
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral600, fontWeight: FontWeight.w800, fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildDrawerQtyStepper(item.qtyController, () => setSheetState(() {})),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Unit price field (underline only) — same pattern as service edit drawer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("UNIT PRICE (GHS)",
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral600,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: item.priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [CurrencyInputFormatter()],
                          onChanged: (_) => setSheetState(() {}),
                          style: AppTextStyles.body.copyWith(
                            color: context.ksc.accent500,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: "0.00",
                            hintStyle: AppTextStyles.body.copyWith(
                              color: context.ksc.neutral600,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.only(bottom: 4),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF2A3A4A), width: 1),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF4A90D9), width: 1.5),
                            ),
                            filled: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("GHS",
                        style: AppTextStyles.caption.copyWith(
                          color: context.ksc.neutral500,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Total display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("TOTAL",
                        style: AppTextStyles.caption.copyWith(
                          color: context.ksc.neutral600,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      () {
                        final qty = int.tryParse(item.qtyController.text) ?? 1;
                        final customPrice = CurrencyFormatter.parseToPesewas(item.priceController.text.trim());
                        final total = qty * (customPrice ?? 0);
                        return Text(
                          total > 0 ? CurrencyFormatter.format(total) : "GHS 0.00",
                          style: AppTextStyles.h2.copyWith(
                            color: context.ksc.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        );
                      }(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ).then((result) {
      if (result == true) {
        onChanged();
      }
      // Note: item is intentionally NOT disposed here — TextFields inside the
      // drawer still reference item's controllers during unmounting.
    });
  }

  void _showItemSearchDrawer({
    required List<ItemRow> localItems,
    required VoidCallback onChanged,
  }) {
    final allInv = ref.read(inventoryProvider).valueOrNull ?? [];
    final searchCtrl = TextEditingController();

    KsBottomSheetScaffold.show(
      context,
      title: "SELECT ITEM",
      bottomLabel: null,
      contentBuilder: (ctx, setSheetState) {
        final query = searchCtrl.text.toLowerCase().trim();
        final filtered = query.isEmpty
            ? allInv
            : allInv.where((i) =>
                i.name.toLowerCase().contains(query) ||
                (i.brand?.toLowerCase().contains(query) ?? false) ||
                (i.category.displayName.toLowerCase().contains(query)) ||
                (i.location?.toLowerCase().contains(query) ?? false)
              ).toList();

        return Column(
          children: [
            // Search field — using KsSearchBar for consistent underline + gold focus
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: KsSearchBar(
                hint: "Search items...",
                controller: searchCtrl,
                onChanged: (_) => setSheetState(() {}),
              ),
            ),
            // List
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.45),
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: KsEmptyState(
                        icon: LineAwesomeIcons.box_solid,
                        title: "NO ITEMS FOUND",
                        subtitle: "Add items to your inventory first",
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: filtered.map((invItem) {
                        final alreadyAdded = localItems.any((li) =>
                          li.inventoryItemId == invItem.id);
                        return InventoryItemCard(
                          key: ValueKey(invItem.id),
                          item: invItem,
                          alreadyAdded: alreadyAdded,
                          onTap: alreadyAdded ? null : () {
                            final row = ItemRow();
                            row.inventoryItem = invItem;
                            row.inventoryItemId = invItem.id;
                            row.nameController.text = invItem.name;
                            localItems.add(row);
                            onChanged();
                            Navigator.pop(ctx);
                          },
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  final row = ItemRow();
                  _showItemEditDrawer(
                    item: row,
                    existingIndex: null,
                    onChanged: () {
                      localItems.add(row);
                      onChanged();
                    },
                  );
                },
                icon: Icon(LineAwesomeIcons.edit_solid, size: 14, color: context.ksc.neutral500),
                label: Text("Add Manual Entry",
                  style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      },
    );
  }

  String _inferMediaType(String path) {
    if (path.endsWith('.mp4') || path.endsWith('.mov')) return 'video';
    if (path.endsWith('.m4a') || path.endsWith('.mp3') || path.endsWith('.wav')) return 'audio';
    return 'image';
  }



  Widget _buildDarkField({required String label, required String hint, required TextEditingController controller, TextInputType type = TextInputType.text, int maxLines = 1, bool readOnly = false, bool isNumeric = false, String? fieldHint, List<TextInputFormatter>? inputFormatters, int? maxLength, ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 10)),
        if (fieldHint != null) ...[const SizedBox(height: 4), Text(fieldHint, style: AppTextStyles.caption.copyWith(color: context.ksc.accent500.withValues(alpha: 0.7), fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0.5))],
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          maxLines: maxLines,
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          autocorrect: !isNumeric,
          enableSuggestions: !isNumeric,
          onChanged: onChanged,
          style: AppTextStyles.body.copyWith(color: readOnly ? context.ksc.neutral500 : context.ksc.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.ksc.neutral500),
            contentPadding: const EdgeInsets.only(bottom: 8, top: 12),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.ksc.primary700, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: context.ksc.accent500, width: 1.5),
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: context.ksc.primary700),
            ),
            filled: false,
          ),
        ),
      ],
    );
  }
}

/// Recording dialog — opens immediately starts recording,
/// shows live timer + stop button. Returns file path on stop, null on cancel.
class _AudioRecordingDialog extends StatefulWidget {
  final AudioRecorder recorder;
  const _AudioRecordingDialog({required this.recorder});

  @override
  State<_AudioRecordingDialog> createState() => _AudioRecordingDialogState();
}

class _AudioRecordingDialogState extends State<_AudioRecordingDialog> {
  int _duration = 0;
  Timer? _timer;
  bool _isStopping = false;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/${const Uuid().v4()}.m4a';
    await widget.recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: filePath);
    if (!mounted) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _duration++);
    });
  }

  Future<void> _stopRecording() async {
    if (_isStopping) return;
    setState(() => _isStopping = true);
    _timer?.cancel();
    final filePath = await widget.recorder.stop();
    if (!mounted) return;
    if (filePath != null) {
      Navigator.of(context).pop(filePath);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _duration ~/ 60;
    final seconds = _duration % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Dialog(
      backgroundColor: context.ksc.primary800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: context.ksc.primary700),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 12, height: 12,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Text("RECORDING",
                  style: AppTextStyles.caption.copyWith(
                    color: context.ksc.error500,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  )),
              ],
            ),
            const SizedBox(height: 24),
            Text(timeStr,
              style: AppTextStyles.h1.copyWith(
                color: context.ksc.white,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              )),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _stopRecording,
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: context.ksc.error500,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: _isStopping
                    ? const Padding(padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.stop, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(height: 8),
            Text("Tap stop when done",
              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
          ],
        ),
      ),
    );
  }
}
