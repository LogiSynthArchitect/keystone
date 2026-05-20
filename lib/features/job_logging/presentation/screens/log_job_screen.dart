import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../../../core/widgets/ks_step_indicator.dart';
import '../../../../core/utils/service_icon_map.dart';
import '../../../../core/providers/shared_feature_providers.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../customer_history/presentation/providers/customer_providers.dart';
import '../../../customer_history/domain/entities/customer_entity.dart';
import '../providers/job_providers.dart';
import '../../domain/entities/job_service_entity.dart';
import '../../domain/entities/job_part_entity.dart';
import '../../domain/entities/job_expense_entity.dart';
import '../../../service_types/presentation/widgets/service_type_picker_v2.dart';
import '../../../service_types/domain/entities/service_type_entity.dart';
import '../../../inventory/domain/entities/inventory_item_entity.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../recurring_jobs/presentation/providers/recurring_schedule_provider.dart';
import '../../../job_templates/domain/entities/job_template_entity.dart';
import '../../../job_templates/presentation/providers/job_template_provider.dart';
import '../../../../core/router/route_names.dart';

class _ItemRow {
  String? inventoryItemId;
  InventoryItemEntity? inventoryItem;
  final nameController = TextEditingController();
  final qtyController = TextEditingController(text: '1');

  bool get isFromInventory => inventoryItem != null;
  String get displayName => isFromInventory ? inventoryItem!.name : nameController.text.trim();

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
  }

  _ItemRow copy() {
    final i = _ItemRow();
    i.inventoryItemId = inventoryItemId;
    i.inventoryItem = inventoryItem;
    i.nameController.text = nameController.text;
    i.qtyController.text = qtyController.text;
    return i;
  }
}

class _PartRow {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  String? inventoryItemId;

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
  }

  _PartRow copy() {
    final p = _PartRow();
    p.nameController.text = nameController.text;
    p.qtyController.text = qtyController.text;
    p.inventoryItemId = inventoryItemId;
    return p;
  }
}

class _ServiceRow {
  String? serviceType;
  final qtyController = TextEditingController(text: '1');
  final priceController = TextEditingController();

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
  }
}

class _ExpenseRow {
  String category = 'transport';
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();

  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
  }

  _ExpenseRow copy() {
    final e = _ExpenseRow();
    e.category = category;
    e.descriptionController.text = descriptionController.text;
    e.amountController.text = amountController.text;
    return e;
  }
}

class _HardwareRow {
  String? domain;
  String? category;
  final nameController = TextEditingController();
  final qtyController = TextEditingController(text: '1');
  String? inventoryItemId;
  InventoryItemEntity? inventoryItem;

  bool get isFromInventory => inventoryItem != null;
  String get displayName => isFromInventory ? inventoryItem!.name : nameController.text.trim();

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
  }

  _HardwareRow copy() {
    final h = _HardwareRow();
    h.domain = domain;
    h.category = category;
    h.inventoryItemId = inventoryItemId;
    h.inventoryItem = inventoryItem;
    h.nameController.text = nameController.text;
    h.qtyController.text = qtyController.text;
    return h;
  }
}

class LogJobScreen extends ConsumerStatefulWidget {
  final String? preSelectedCustomerId;
  const LogJobScreen({super.key, this.preSelectedCustomerId});

  @override
  ConsumerState<LogJobScreen> createState() => _LogJobScreenState();
}

class _LogJobScreenState extends ConsumerState<LogJobScreen> {
  int _currentStep = 0;
  final int _totalSteps = 6;

  String? _serviceType;
  String? _finalCustomerId;
  String _status = 'in_progress';
  String _paymentStatus = 'unpaid';
  String? _leadSource;
  bool _isRecurring = false;
  bool _serviceExpanded = true;
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

  final List<_ItemRow> _items = [];
  final List<_PartRow> _parts = [];
  final List<_ServiceRow> _additionalServices = [];
  final List<_HardwareRow> _hardwareItems = [];
  final List<_ExpenseRow> _expenses = [];
  int _partSuggestionIndex = -1;
  List<InventoryItemEntity> _partSuggestions = [];
  int _hwSuggestionIndex = -1;
  List<InventoryItemEntity> _hwSuggestions = [];
  final List<XFile> _beforePhotos = [];
  final List<XFile> _afterPhotos = [];

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
                      _beforePhotos.isNotEmpty ||
                      _afterPhotos.isNotEmpty;

  bool get _canMoveForward {
    final hasCustomer = _finalCustomerId != null;
    switch (_currentStep) {
      case 0: return _serviceType != null;
      case 1: return true;
      case 2:
        if (_customerController.text.trim().isEmpty) return false;
        if (hasCustomer) return true;
        final phone = _phoneController.text.trim();
        // Accept 10 digits (with 0) or 9 digits (without 0) — PhoneFormatter normalizes both
        return (phone.length == 10 && phone.startsWith('0')) ||
               (phone.length == 9 && !phone.startsWith('0'));
      case 3:
        final amountText = _amountController.text.trim();
        if (amountText.isEmpty) return true;
        final amount = CurrencyFormatter.parseToPesewas(amountText);
        return amount != null && amount >= 0;
      case 4: return true;
      case 5: return true;
      default: return false;
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.mediumImpact();
      setState(() => _currentStep++);
    } else {
      _onSave();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      _confirmDiscard().then((ok) {
        if (ok && mounted) Navigator.of(context).pop();
      });
    }
  }

  void _loadTemplate() {
    final userId = ref.read(currentUserProvider).valueOrNull?.id;
    if (userId == null) return;
    ref.read(jobTemplateProvider.notifier).loadTemplates(userId);

    showModalBottomSheet(
      context: context,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      builder: (ctx) {
        return Consumer(builder: (context, ref, _) {
          final templatesAsync = ref.watch(jobTemplateProvider);
          return templatesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: Text("FAILED TO LOAD", style: AppTextStyles.caption.copyWith(color: context.ksc.error500))),
            data: (templates) {
              if (templates.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("NO TEMPLATES", style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text("Save a job as template first", style: AppTextStyles.body.copyWith(color: context.ksc.neutral500)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final t = templates[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: context.ksc.primary700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListTile(
                      leading: Icon(LineAwesomeIcons.clipboard_list_solid, color: context.ksc.accent500),
                      title: Text(t.name, style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700)),
                      subtitle: Text("${t.serviceType.replaceAll('_', ' ')} · ${t.services.length} services", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _applyTemplate(t);
                      },
                    ),
                  );
                },
              );
            },
          );
        });
      },
    );
  }

  void _applyTemplate(JobTemplateEntity template) {
    setState(() {
      _serviceType = template.serviceType;
      _notesController.text = template.notes ?? '';

      for (final s in template.services) {
        final row = _ServiceRow();
        row.serviceType = s['service_type'] as String?;
        row.qtyController.text = (s['quantity'] as int? ?? 1).toString();
        if (s['unit_price'] != null) {
          row.priceController.text = ((s['unit_price'] as int) / 100.0).toStringAsFixed(2);
        }
        _additionalServices.add(row);
      }

      for (final h in template.hardwareItems) {
        final row = _ItemRow();
        row.nameController.text = h['name'] as String? ?? '';
        row.qtyController.text = (h['quantity'] as int? ?? 1).toString();
        _items.add(row);
      }

      for (final p in template.parts) {
        final row = _ItemRow();
        row.nameController.text = p['part_name'] as String? ?? '';
        row.qtyController.text = (p['quantity'] as int? ?? 1).toString();
        _items.add(row);
      }
    });
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ksc.primary800,
        title: Text('DISCARD DRAFT?', style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        content: Text('Your entered job details will be lost. Leave anyway?', style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('KEEP EDITING', style: AppTextStyles.label.copyWith(color: context.ksc.neutral400))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('DISCARD', style: AppTextStyles.label.copyWith(color: context.ksc.error500, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;
  }

  Future<void> _onSave() async {
    HapticFeedback.heavyImpact();

    if (_finalCustomerId == null) {
      final phone = _phoneController.text.trim();
      final valid = (phone.length == 10 && phone.startsWith('0')) ||
                    (phone.length == 9 && !phone.startsWith('0'));
      if (!valid) {
        if (mounted) KsSnackbar.show(context, message: "Enter a valid Ghana number (e.g. 024 123 4567)", type: KsSnackbarType.error);
        return;
      }
    }

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
        ..._beforePhotos.map((p) => (File(p.path), 'before', _inferMediaType(p.path))),
        ..._afterPhotos.map((p) => (File(p.path), 'after', _inferMediaType(p.path))),
      ],
    );

    if (!mounted) return;
    if (job != null) {
      final repo = ref.read(jobRepositoryProvider);

      if (_additionalServices.isNotEmpty) {
        final services = _additionalServices.asMap().entries.map((e) => JobServiceEntity(
          id: const Uuid().v4(),
          jobId: job.id,
          serviceType: e.value.serviceType ?? '',
          quantity: int.tryParse(e.value.qtyController.text.trim()) ?? 1,
          unitPrice: CurrencyFormatter.parseToPesewas(e.value.priceController.text.trim()),
          sortOrder: e.key,
          createdAt: DateTime.now(),
        )).toList();
        await repo.saveServices(job.id, services);
      }

      if (_items.isNotEmpty) {
        final parts = _items.asMap().entries.map((e) {
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

      final saveAsTemplate = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.ksc.primary800,
          title: Text('SAVE AS TEMPLATE?', style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
          content: Text('Save this job as a reusable template?', style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('NO', style: AppTextStyles.label.copyWith(color: context.ksc.neutral400))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('YES', style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.bold))),
          ],
        ),
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
              services: _additionalServices.map((s) => {
                'service_type': s.serviceType,
                'quantity': int.tryParse(s.qtyController.text.trim()) ?? 1,
                'unit_price': CurrencyFormatter.parseToPesewas(s.priceController.text.trim()),
              }).toList(),
              hardwareItems: _items.where((i) => i.isFromInventory).map((h) => {
                'name': h.nameController.text.trim(),
                'quantity': int.tryParse(h.qtyController.text.trim()) ?? 1,
                'unit_sale_price': h.inventoryItem?.defaultSalePrice,
              }).toList(),
              parts: _items.where((i) => !i.isFromInventory).map((p) => {
                'part_name': p.nameController.text.trim(),
                'quantity': int.tryParse(p.qtyController.text.trim()) ?? 1,
                'unit_price': null,
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
        context.pop();
        KsSnackbar.show(context, message: job.isSynced ? "Job saved" : "Saved locally.", type: KsSnackbarType.success);
      }
    } else {
      final error = ref.read(logJobProvider).errorMessage;
      if (error != null && error.isNotEmpty) {
        KsSnackbar.show(context, message: error, type: KsSnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logJobProvider);
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _previousStep();
      },
      child: Scaffold(
        backgroundColor: context.ksc.primary900,
        appBar: KsAppBar(
          title: "ADD NEW JOB",
          showBack: true,
          onBack: _previousStep,
        ),
        body: Column(
          children: [
            const KsOfflineBanner(),
            KsStepIndicator(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              labels: ["SERVICE", "STATUS", "CUSTOMER", "PRICING", "SCHEDULE", "EXTRAS"],
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: SingleChildScrollView(
                  key: ValueKey<int>(_currentStep),
                  padding: const EdgeInsets.all(24.0),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
            if (!keyboardVisible) _buildBottomAction(state.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      case 3: return _buildStep4();
      case 4: return _buildStep5();
      case 5: return _buildStep6();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    final mainServiceSummary = _serviceType != null
        ? _serviceType!.replaceAll('_', ' ').toUpperCase()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SERVICE PERFORMED", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("The main reason for this visit", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
        _buildExpandableSection(
          collapsedSummary: mainServiceSummary,
          expanded: _serviceExpanded,
          onToggle: () => setState(() => _serviceExpanded = !_serviceExpanded),
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ServiceTypePickerV2(
              selected: _serviceType,
              onSelected: (t) => setState(() => _serviceType = t),
            ),
          ),
        ),
        const SizedBox(height: 48),
        Text("ADDITIONAL SERVICES (OPTIONAL)", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Other services performed during this visit", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
        const SizedBox(height: 16),
        if (_additionalServices.isEmpty)
          KsEmptyState(
            icon: LineAwesomeIcons.tools_solid,
            title: "NO ADDITIONAL SERVICES",
            subtitle: "Tap the button below to add services performed during this visit",
          )
        else
          ..._additionalServices.asMap().entries.map((entry) {
            final svc = entry.value;
            final qty = int.tryParse(svc.qtyController.text) ?? 1;
            final unitPrice = CurrencyFormatter.parseToPesewas(svc.priceController.text.trim()) ?? 0;
            final total = qty * unitPrice;
            final types = ref.read(serviceTypeProvider).valueOrNull ?? [];
            final svcType = types.where((t) => t.name == svc.serviceType).firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: _showAdditionalServicesDrawer,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.ksc.primary800,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: context.ksc.primary700),
                  ),
                  child: Row(
                    children: [
                      Icon(ServiceIconMap.resolve(svcType?.iconName), size: 16, color: context.ksc.accent500),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          svc.serviceType?.replaceAll('_', ' ').toUpperCase() ?? '',
                          style: AppTextStyles.caption.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        total > 0 ? CurrencyFormatter.format(total) : "GHS 0.00",
                        style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showAdditionalServicesDrawer,
            icon: Icon(LineAwesomeIcons.plus_solid, size: 16, color: context.ksc.accent500),
            label: Text("ADD SERVICE", style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.ksc.accent500.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String? collapsedSummary,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.ksc.primary800,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: context.ksc.primary700),
              ),
              child: Row(
                children: [
                  Icon(
                    expanded ? LineAwesomeIcons.angle_down_solid : LineAwesomeIcons.angle_right_solid,
                    size: 12,
                    color: context.ksc.accent500,
                  ),
                  if (collapsedSummary != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(collapsedSummary.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: context.ksc.accent500,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    final options = [
      ('quoted', 'QUOTED'),
      ('in_progress', 'IN PROGRESS'),
      ('completed', 'COMPLETED'),
      ('invoiced', 'INVOICED'),
    ];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: options.map((opt) {
        final isSelected = _status == opt.$1;
        return GestureDetector(
          onTap: () => setState(() => _status = opt.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isSelected ? context.ksc.accent500 : context.ksc.primary700),
            ),
            child: Text(opt.$2, style: AppTextStyles.caption.copyWith(color: isSelected ? context.ksc.accent500 : context.ksc.neutral400, fontWeight: FontWeight.w900)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("JOB STATUS", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Where is this job in the workflow?", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
        const SizedBox(height: 24),
        _buildStatusSelector(),
        const SizedBox(height: 32),
        Text("LEAD SOURCE", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("How did the customer find you?", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
        const SizedBox(height: 24),
        _buildLeadSourceRow(),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("CUSTOMER", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 32),
        _buildCustomerField(
          icon: LineAwesomeIcons.user_solid,
          label: "Customer Name",
          hint: "Kwame Mensah",
          controller: _customerController,
          readOnly: widget.preSelectedCustomerId != null,
          maxLength: 100,
        ),
        if (widget.preSelectedCustomerId == null) ...[
          const SizedBox(height: 16),
          _buildCustomerField(
            icon: LineAwesomeIcons.phone_alt_solid,
            label: "Phone Number",
            hint: "024 123 4567",
            controller: _phoneController,
            fieldHint: "Required for WhatsApp follow-ups.",
            isNumeric: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            onChanged: _onPhoneChanged,
          ),
          if (_matchedCustomerName != null && _matchedCustomerId != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.ksc.accent500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(LineAwesomeIcons.check_circle_solid, size: 20, color: context.ksc.accent500),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("LINKED TO EXISTING CUSTOMER",
                            style: AppTextStyles.caption.copyWith(
                              color: context.ksc.accent500,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(_matchedCustomerName!.toUpperCase(),
                            style: AppTextStyles.body.copyWith(
                              color: context.ksc.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildCustomerField({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    bool readOnly = false,
    bool isNumeric = false,
    String? fieldHint,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Icon(icon, size: 20, color: context.ksc.accent500),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: context.ksc.neutral500,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (fieldHint != null) ...[
                const SizedBox(height: 2),
                Text(fieldHint,
                  style: AppTextStyles.caption.copyWith(
                    color: context.ksc.accent500.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                readOnly: readOnly,
                maxLength: maxLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                inputFormatters: inputFormatters,
                onChanged: onChanged,
                keyboardType: isNumeric ? TextInputType.phone : TextInputType.text,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: readOnly ? context.ksc.neutral500 : context.ksc.white,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTextStyles.bodyLarge.copyWith(
                    color: context.ksc.neutral600,
                    fontWeight: FontWeight.bold,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.only(bottom: 4),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2A3A4A), width: 1),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF4A90D9), width: 1.5),
                  ),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2A3A4A)),
                  ),
                  filled: false,
                ),
              ),
            ],
          ),
        ),
      ],
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
          final useExisting = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: context.ksc.primary800,
              title: Text('CUSTOMER NAME MISMATCH',
                style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
              content: Text(
                'Phone belongs to ${customer.fullName.toUpperCase()}.\n\n'
                'You entered: ${_customerController.text.trim().toUpperCase()}\n\n'
                'Use the existing customer name?',
                style: AppTextStyles.body.copyWith(color: context.ksc.neutral400),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('KEEP MY NAME',
                    style: AppTextStyles.label.copyWith(color: context.ksc.neutral400)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('USE EXISTING',
                    style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
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
      // Silently fail — lookup is non-critical
    }
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("PRICING", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Set the money side of this job", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
        const SizedBox(height: 32),
        _buildPriceCard(
          icon: LineAwesomeIcons.file_invoice_dollar_solid,
          label: "Quoted Amount",
          hint: "0.00",
          controller: _quotedAmountController,
          focusNode: _quotedFocusNode,
        ),
        const SizedBox(height: 16),
        _buildPriceCard(
          icon: LineAwesomeIcons.money_bill_wave_alt_solid,
          label: "Final Amount",
          hint: "0.00",
          controller: _amountController,
          focusNode: _amountFocusNode,
        ),
        const SizedBox(height: 32),
        Text("PAYMENT STATUS", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _buildPaymentStatusRow(),
      ],
    );
  }

  Widget _buildPriceCard({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    FocusNode? focusNode,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Icon(icon, size: 20, color: context.ksc.accent500),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral500,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text("GHS", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [CurrencyInputFormatter()],
                style: AppTextStyles.h2.copyWith(
                  color: context.ksc.white,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTextStyles.h2.copyWith(
                    color: context.ksc.neutral600,
                    fontWeight: FontWeight.w900,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.only(bottom: 4),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2A3A4A), width: 1),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF4A90D9), width: 1.5),
                  ),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2A3A4A)),
                  ),
                  filled: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusRow() {
    final statusOpts = [('unpaid', 'UNPAID'), ('partial', 'PARTIAL'), ('paid', 'PAID')];
    return Row(
      children: statusOpts.map((opt) {
        final isSel = _paymentStatus == opt.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _paymentStatus = opt.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary800,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: isSel ? context.ksc.accent500 : context.ksc.primary700),
              ),
              child: Text(opt.$2, style: AppTextStyles.caption.copyWith(color: isSel ? context.ksc.accent500 : context.ksc.neutral400, fontWeight: FontWeight.w900)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLeadSourceRow() {
    final sources = <String, IconData>{
      'referral': LineAwesomeIcons.user_plus_solid,
      'walk_in': LineAwesomeIcons.user_solid,
      'whatsapp': LineAwesomeIcons.comment_solid,
      'repeat_customer': LineAwesomeIcons.history_solid,
      'social_media': LineAwesomeIcons.share_alt_solid,
      'phone_call': LineAwesomeIcons.phone_alt_solid,
      'online_search': LineAwesomeIcons.search_solid,
      'other': LineAwesomeIcons.ellipsis_h_solid,
    };
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: sources.entries.map((e) {
        final s = e.key;
        final icon = e.value;
        final isSel = _leadSource == s;
        return GestureDetector(
          onTap: () => setState(() => _leadSource = isSel ? null : s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSel ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isSel ? context.ksc.accent500 : context.ksc.primary700),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: isSel ? context.ksc.accent500 : context.ksc.neutral400),
                const SizedBox(width: 6),
                Text(s.replaceAll('_', ' ').toUpperCase(), style: AppTextStyles.caption.copyWith(
                  color: isSel ? context.ksc.accent500 : context.ksc.neutral400,
                  fontWeight: FontWeight.w900,
                )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecurringToggle() {
    final intervals = [('weekly', 'WEEKLY'), ('monthly', 'MONTHLY'), ('quarterly', 'QUARTERLY')];
    final nextDueStr = switch (_recurringInterval) {
      'weekly' => DateFormatter.short(_jobDate.add(const Duration(days: 7))),
      'monthly' => DateFormatter.short(_jobDate.add(const Duration(days: 30))),
      'quarterly' => DateFormatter.short(_jobDate.add(const Duration(days: 90))),
      _ => '',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isRecurring = !_isRecurring),
          child: Row(
            children: [
              Icon(
                _isRecurring ? LineAwesomeIcons.calendar_check_solid : LineAwesomeIcons.calendar_solid,
                color: _isRecurring ? context.ksc.accent500 : context.ksc.neutral500,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text("REPEAT THIS JOB", style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: "Auto-generate follow-up jobs on a schedule.\n"
                              "Weekly = every 7 days\n"
                              "Monthly = every 30 days\n"
                              "Quarterly = every 90 days\n\n"
                              "Works only after a customer is selected.",
                          preferBelow: false,
                          child: Icon(LineAwesomeIcons.question_circle_solid, size: 14, color: context.ksc.neutral500),
                        ),
                      ],
                    ),
                    Text(_isRecurring ? "Next: $nextDueStr" : "Set up weekly / monthly / quarterly", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
                  ],
                ),
              ),
              Switch(
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
                activeColor: context.ksc.accent500,
              ),
            ],
          ),
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 16),
          Row(
            children: intervals.map((opt) {
              final isSelected = _recurringInterval == opt.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _recurringInterval = opt.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary700,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: isSelected ? context.ksc.accent500 : context.ksc.primary700),
                    ),
                    child: Text(opt.$2, style: AppTextStyles.caption.copyWith(
                      color: isSelected ? context.ksc.accent500 : context.ksc.neutral400,
                      fontWeight: FontWeight.w900,
                    )),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomerHistorySuggestions() {
    final suggestions = ref.watch(customerHistorySuggestionsProvider(_finalCustomerId!));
    return suggestions.when(
      data: (data) {
        if (data.hardwareBrands.isEmpty && data.partNames.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LineAwesomeIcons.history_solid, size: 14, color: context.ksc.accent500),
                  const SizedBox(width: 8),
                  Text("FROM PAST JOBS", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ],
              ),
              const SizedBox(height: 10),
              if (data.hardwareBrands.isNotEmpty) ...[
                Text("BRANDS USED", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 9)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: data.hardwareBrands.map((b) => GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_items.isEmpty || _items.last.nameController.text.isNotEmpty) {
                          _items.add(_ItemRow());
                        }
                        _items.last.nameController.text = b;
                      });
                    },
                    child: Text(b.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 10, decoration: TextDecoration.underline)),
                  )).toList(),
                ),
                const SizedBox(height: 10),
              ],
              if (data.partNames.isNotEmpty) ...[
                Text("PARTS USED", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 9)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: data.partNames.map((p) => GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_items.isEmpty || _items.last.nameController.text.isNotEmpty) {
                          _items.add(_ItemRow());
                        }
                        _items.last.nameController.text = p;
                      });
                    },
                    child: Text(p.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 10, decoration: TextDecoration.underline)),
                  )).toList(),
                ),
              ],
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Divider(height: 1, color: Color(0xFF1E2A3A)),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecurringToggle(),
        const SizedBox(height: 48),
        Text("DATE & LOCATION", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("When and where this job took place", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
        const SizedBox(height: 24),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: _jobDate, firstDate: DateTime(2024), lastDate: DateTime.now());
            if (picked != null) setState(() => _jobDate = picked);
          },
          child: Row(
            children: [
              Icon(LineAwesomeIcons.calendar, size: 20, color: context.ksc.accent500),
              const SizedBox(width: 14),
              Text(DateFormatter.short(_jobDate), style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 34, top: 4),
          child: Divider(height: 1, color: Color(0xFF2A3A4A)),
        ),
        const SizedBox(height: 32),
        _buildDarkField(label: "Location", hint: "East Legon, Accra", controller: _locationController, maxLength: 255),
      ],
    );
  }

  Widget _buildStep6() {
    final itemCount = _items.length;
    final expCount = _expenses.length;
    final expTotal = _expenses.fold<int>(0, (sum, e) {
      return sum + (CurrencyFormatter.parseToPesewas(e.amountController.text.trim()) ?? 0);
    });
    final partCount = _parts.length;
    final photoCount = _beforePhotos.length + _afterPhotos.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_finalCustomerId != null)
          _buildCustomerHistorySuggestions(),
        const SizedBox(height: 24),
        _buildExtrasCard(
          icon: Icon(LineAwesomeIcons.box_solid, size: 16, color: context.ksc.accent500),
          title: "Items Used",
          subtitle: "Hardware, parts & supplies",
          trailing: itemCount > 0
              ? _extrasCountTrailing("$itemCount item${itemCount > 1 ? 's' : ''}")
              : _extrasEmptyTrailing(),
          onTap: () => _showItemsDrawer(),
        ),
        _buildExtrasCard(
          icon: Icon(LineAwesomeIcons.coins_solid, size: 16, color: context.ksc.accent500),
          title: "Expenses",
          subtitle: "Transport, parking, subs",
          trailing: expCount > 0
              ? _extrasCountTrailing("$expCount item${expCount > 1 ? 's' : ''}", amount: CurrencyFormatter.format(expTotal))
              : _extrasEmptyTrailing(),
          onTap: () => _showExpensesDrawer(),
        ),
        _buildExtrasCard(
          icon: Icon(LineAwesomeIcons.camera_solid, size: 16, color: context.ksc.accent500),
          title: "Media",
          subtitle: "Photos, videos & audio recordings",
          trailing: photoCount > 0
              ? _extrasCountTrailing("$photoCount item${photoCount > 1 ? 's' : ''}")
              : _extrasEmptyTrailing(),
          onTap: () => _showPhotosDrawer(),
        ),
        _buildExtrasCard(
          icon: Icon(LineAwesomeIcons.edit_solid, size: 16, color: context.ksc.accent500),
          title: "Notes",
          subtitle: "Job notes",
          trailing: _extrasNoteTrailing(),
          onTap: () => _showNotesDrawer(),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildExtrasCard({
    required Widget icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(width: 20, height: 20, child: icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
            const SizedBox(width: 8),
            Icon(LineAwesomeIcons.angle_right_solid,
              color: context.ksc.neutral500, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _extrasCountTrailing(String count, {String? amount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count,
          style: AppTextStyles.caption.copyWith(
            color: context.ksc.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        if (amount != null)
          Text(amount,
            style: AppTextStyles.caption.copyWith(
              color: context.ksc.accent500,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  Widget _extrasEmptyTrailing() {
    return Text("No items",
      style: AppTextStyles.caption.copyWith(
        color: context.ksc.neutral600,
        fontSize: 11,
      ),
    );
  }

  Widget _extrasNoteTrailing() {
    final text = _notesController.text.trim();
    if (text.isEmpty) {
      return Text("No notes",
        style: AppTextStyles.caption.copyWith(
          color: context.ksc.neutral600,
          fontSize: 11,
        ),
      );
    }
    return Text(text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.caption.copyWith(
        color: context.ksc.neutral500,
        fontSize: 11,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildExpenseRow(int index, _ExpenseRow expense) {
    final categories = ['transport', 'parking', 'subcontractor', 'supplies', 'other'];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdown("Category", categories, expense.category, (v) {
                setState(() => expense.category = v ?? 'transport');
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _buildDarkField(
                label: "Amount (GHS)", hint: "0.00",
                controller: expense.amountController, isNumeric: true,
              ),
            ),
            IconButton(
              icon: Icon(LineAwesomeIcons.times_solid, color: context.ksc.error500, size: 18),
              onPressed: () => setState(() => _expenses.removeAt(index)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildDarkField(label: "Description", hint: "e.g. Troski fare to site", controller: expense.descriptionController),
        const Divider(height: 24, color: Color(0xFF1E2A3A)),
      ],
    );
  }

  Widget _buildPartRow(int index, _PartRow part) {
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
                  i.itemType == 'part' &&
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
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E2A3A), width: 1)),
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

        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Divider(height: 1, color: Color(0xFF1E2A3A)),
        ),
      ],
    );
  }


  Widget _buildHardwareRow(int index, _HardwareRow hw, {VoidCallback? onRemove}) {
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
                    i.itemType == 'hardware' &&
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
  Widget _buildInventoryHardwareCard(int index, _HardwareRow hw) {
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
  Widget _buildQtyStepper(_HardwareRow hw) {
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
  void _showInventoryPicker({void Function(_HardwareRow item)? onItemSelected}) {
    final items = ref.read(inventoryProvider).valueOrNull ?? [];
    final hardwareItems = items.where((i) => i.itemType == 'hardware' && !i.isArchived).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        final searchCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = searchCtrl.text.toLowerCase().trim();
            final filtered = query.isEmpty
                ? hardwareItems
                : hardwareItems.where((i) =>
                    i.name.toLowerCase().contains(query) ||
                    (i.brand?.toLowerCase().contains(query) ?? false) ||
                    (i.category?.toLowerCase().contains(query) ?? false)
                  ).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text("SELECT HARDWARE ITEM",
                            style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
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
                  ),
                  const SizedBox(height: 8),
                  // List
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                    ),
                    child: filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32),
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
                                  // Create hardware row pre-filled from inventory
                                  final hw = _HardwareRow();
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
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmDrawerClose(BuildContext sheetCtx) async {
    return await showDialog<bool>(
      context: sheetCtx,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ksc.primary800,
        title: Text('DISCARD CHANGES?', style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        content: Text('You have unsaved changes. Discard them?', style: AppTextStyles.body.copyWith(color: context.ksc.neutral400)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('KEEP EDITING', style: AppTextStyles.label.copyWith(color: context.ksc.neutral400))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('DISCARD', style: AppTextStyles.label.copyWith(color: context.ksc.error500, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;
  }

  void _showAdditionalServicesDrawer() {
    final localServices = _additionalServices.map((s) {
      final copy = _ServiceRow();
      copy.serviceType = s.serviceType;
      copy.qtyController.text = s.qtyController.text;
      copy.priceController.text = s.priceController.text;
      return copy;
    }).toList();
    bool dirty = false;

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final typesAsync = ref.watch(serviceTypeProvider);
            final types = typesAsync.valueOrNull ?? [];

            final grouped = <String, List>{};
            for (final t in types) {
              grouped.putIfAbsent(t.category, () => []).add(t);
            }
            final categories = grouped.keys.toList()..sort();

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2))),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ADDITIONAL SERVICES",
                                style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(
                                localServices.isNotEmpty
                                    ? "${localServices.length} service${localServices.length > 1 ? 's' : ''}"
                                    : "Tap a service below to add it to this job",
                                style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (dirty) {
                              final ok = await _confirmDrawerClose(ctx);
                              if (!ok) return;
                            }
                            if (ctx.mounted) Navigator.pop(ctx, false);
                          },
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
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
                                        final row = _ServiceRow();
                                        row.serviceType = type.name;
                                        if (type.defaultPrice != null) {
                                          row.priceController.text = (type.defaultPrice! / 100.0).toStringAsFixed(2);
                                        }
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
                                            color: alreadyAdded ? context.ksc.neutral600 : context.ksc.primary700,
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
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: () {
                          setState(() {
                            _additionalServices
                              ..clear()
                              ..addAll(localServices);
                          });
                          Navigator.pop(ctx, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.ksc.accent500,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: Text("DONE",
                          style: AppTextStyles.label.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
    required _ServiceRow service,
    required List<ServiceTypeEntity> types,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final qty = int.tryParse(service.qtyController.text) ?? 1;
    final unitPrice = CurrencyFormatter.parseToPesewas(service.priceController.text.trim()) ?? 0;
    final total = qty * unitPrice;
    final svcType = types.where((t) => t.name == service.serviceType).firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF1E2A3A), width: 1)),
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
    required _ServiceRow service,
    required int? existingIndex,
    required VoidCallback onChanged,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final qty = int.tryParse(service.qtyController.text) ?? 1;
            final unitPrice = CurrencyFormatter.parseToPesewas(service.priceController.text.trim()) ?? 0;
            final total = qty * unitPrice;
            final types = ref.read(serviceTypeProvider).valueOrNull ?? [];
            final svcType = types.where((t) => t.name == service.serviceType).firstOrNull;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            existingIndex != null ? "EDIT SERVICE" : "ADD SERVICE",
                            style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx, false),
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 32),
                  // Action button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.ksc.accent500,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: Text(
                          existingIndex != null ? "SAVE" : "ADD",
                          style: AppTextStyles.label.copyWith(
                            color: context.ksc.primary900,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
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
    // Local working copy — only committed to parent on DONE
    final localItems = _hardwareItems.map((h) => h.copy()).toList();
    bool dirty = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final hwCount = localItems.length;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2))),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("HARDWARE ITEMS",
                                style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(
                                hwCount > 0
                                    ? "$hwCount item${hwCount > 1 ? 's' : ''}"
                                    : "No items added",
                                style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (dirty) {
                              final ok = await _confirmDrawerClose(ctx);
                              if (!ok) return;
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
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
                                localItems.add(_HardwareRow());
                                dirty = true;
                                setSheetState(() {});
                              },
                              icon: Icon(LineAwesomeIcons.plus_solid, size: 14, color: context.ksc.neutral500),
                              label: Text("Add Manual Entry",
                                style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _hardwareItems
                                    ..clear()
                                    ..addAll(localItems);
                                });
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.ksc.accent500,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: Text("DONE",
                                style: AppTextStyles.label.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showExpensesDrawer() {
    final localExpenses = _expenses.map((e) => e.copy()).toList();
    bool dirty = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final expCount = localExpenses.length;
            final expTotal = localExpenses.fold<int>(0, (sum, e) {
              return sum + (CurrencyFormatter.parseToPesewas(e.amountController.text.trim()) ?? 0);
            });

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2))),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("EXPENSES",
                                style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(
                                expCount > 0
                                    ? "$expCount item${expCount > 1 ? 's' : ''} · ${CurrencyFormatter.format(expTotal)}"
                                    : "No expenses added",
                                style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (dirty) {
                              final ok = await _confirmDrawerClose(ctx);
                              if (!ok) return;
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          ...localExpenses.asMap().entries.map((entry) =>
                            _buildExpenseRow(entry.key, entry.value)),
                          if (localExpenses.length < 10)
                            TextButton.icon(
                              onPressed: () {
                                localExpenses.add(_ExpenseRow());
                                dirty = true;
                                setSheetState(() {});
                              },
                              icon: const Icon(LineAwesomeIcons.plus_solid, size: 16),
                              label: Text("ADD EXPENSE",
                                style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
                            ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _expenses
                                    ..clear()
                                    ..addAll(localExpenses);
                                });
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.ksc.accent500,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: Text("DONE",
                                style: AppTextStyles.label.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPartsDrawer() {
    final localParts = _parts.map((p) => p.copy()).toList();
    bool dirty = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final partCount = localParts.length;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2))),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("PARTS USED",
                                style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(
                                partCount > 0
                                    ? "$partCount item${partCount > 1 ? 's' : ''}"
                                    : "No parts added",
                                style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (dirty) {
                              final ok = await _confirmDrawerClose(ctx);
                              if (!ok) return;
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          ...localParts.asMap().entries.map((entry) =>
                            _buildPartRow(entry.key, entry.value)),
                          if (localParts.length < 20)
                            TextButton.icon(
                              onPressed: () {
                                localParts.add(_PartRow());
                                dirty = true;
                                setSheetState(() {});
                              },
                              icon: const Icon(LineAwesomeIcons.plus_solid, size: 16),
                              label: Text("ADD PART",
                                style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
                            ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _parts
                                    ..clear()
                                    ..addAll(localParts);
                                });
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.ksc.accent500,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: Text("DONE",
                                style: AppTextStyles.label.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPhotosDrawer() {
    final localBefore = List<XFile>.from(_beforePhotos);
    final localAfter = List<XFile>.from(_afterPhotos);
    bool dirty = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final photoCount = localBefore.length + localAfter.length;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2))),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("MEDIA",
                                style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(
                                photoCount > 0
                                    ? "$photoCount item${photoCount > 1 ? 's' : ''}"
                                    : "No media added",
                                style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (dirty) {
                              final ok = await _confirmDrawerClose(ctx);
                              if (!ok) return;
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _buildPhotoGroup("BEFORE PHOTOS", localBefore, onChanged: () { dirty = true; setSheetState(() {}); }),
                          const SizedBox(height: 16),
                          _buildPhotoGroup("AFTER PHOTOS", localAfter, onChanged: () { dirty = true; setSheetState(() {}); }),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _beforePhotos
                                    ..clear()
                                    ..addAll(localBefore);
                                  _afterPhotos
                                    ..clear()
                                    ..addAll(localAfter);
                                });
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.ksc.accent500,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: Text("DONE",
                                style: AppTextStyles.label.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNotesDrawer() {
    final initialText = _notesController.text;
    bool dirty = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2))),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("NOTES",
                                style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text("Job notes and comments",
                                style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (dirty) {
                              final ok = await _confirmDrawerClose(ctx);
                              if (!ok) return;
                            }
                            _notesController.text = initialText; // restore on discard
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          TextField(
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
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.ksc.accent500,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: Text("DONE",
                                style: AppTextStyles.label.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showItemsDrawer() {
    final localItems = _items.map((i) => i.copy()).toList();
    bool dirty = false;

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final count = localItems.length;

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2))),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ITEMS USED",
                                style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(
                                count > 0
                                    ? "$count item${count > 1 ? 's' : ''}"
                                    : "No items added",
                                style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (dirty) {
                              final ok = await _confirmDrawerClose(ctx);
                              if (!ok) return;
                            }
                            if (ctx.mounted) Navigator.pop(ctx, false);
                          },
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
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
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _items
                              ..clear()
                              ..addAll(localItems);
                          });
                          Navigator.pop(ctx, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.ksc.accent500,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: Text("DONE",
                          style: AppTextStyles.label.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((committed) {
      if (committed != true) {
        for (final i in localItems) {
          i.dispose();
        }
      }
    });
  }

  Widget _buildItemSummaryCard({
    required _ItemRow item,
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
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF1E2A3A), width: 1)),
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
    required _ItemRow item,
    required int? existingIndex,
    required VoidCallback onChanged,
  }) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2))),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            existingIndex != null ? "EDIT ITEM" : "NEW ITEM",
                            style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx, false),
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.ksc.accent500,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: Text(
                          existingIndex != null ? "SAVE" : "ADD",
                          style: AppTextStyles.label.copyWith(
                            color: context.ksc.primary900, fontWeight: FontWeight.w900, letterSpacing: 1.0,
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
      },
    ).then((result) {
      if (result == true) {
        onChanged();
      } else if (existingIndex == null) {
        item.dispose();
      }
    });
  }

  void _showItemSearchDrawer({
    required List<_ItemRow> localItems,
    required VoidCallback onChanged,
  }) {
    final allInv = ref.read(inventoryProvider).valueOrNull ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        final searchCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = searchCtrl.text.toLowerCase().trim();
            final filtered = query.isEmpty
                ? allInv
                : allInv.where((i) =>
                    i.name.toLowerCase().contains(query) ||
                    (i.brand?.toLowerCase().contains(query) ?? false)
                  ).toList();

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2))),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(child: Text("SELECT ITEM",
                          style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900))),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
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
                          hintText: "Search inventory...",
                          hintStyle: AppTextStyles.caption.copyWith(color: context.ksc.neutral600),
                          prefixIcon: Icon(LineAwesomeIcons.search_solid, color: context.ksc.neutral500, size: 18),
                          suffixIcon: searchCtrl.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () { searchCtrl.clear(); setSheetState(() {}); },
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
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.45),
                      child: filtered.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32),
                              child: KsEmptyState(
                                icon: LineAwesomeIcons.box_solid,
                                title: "NO ITEMS FOUND",
                                subtitle: "Add items to your inventory first",
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: context.ksc.primary700),
                              itemBuilder: (_, i) {
                                final invItem = filtered[i];
                                final alreadyAdded = localItems.any((li) =>
                                  li.inventoryItemId == invItem.id);
                                return InkWell(
                                  onTap: alreadyAdded ? null : () {
                                    final row = _ItemRow();
                                    row.inventoryItem = invItem;
                                    row.inventoryItemId = invItem.id;
                                    row.nameController.text = invItem.name;
                                    localItems.add(row);
                                    onChanged();
                                    Navigator.pop(ctx);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          invItem.itemType == 'hardware'
                                              ? LineAwesomeIcons.lock_solid
                                              : LineAwesomeIcons.box_solid,
                                          size: 16, color: alreadyAdded ? context.ksc.neutral600 : context.ksc.accent500,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(invItem.name.toUpperCase(),
                                                style: AppTextStyles.body.copyWith(
                                                  color: alreadyAdded ? context.ksc.neutral600 : context.ksc.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                              ),
                                              if (invItem.brand != null || invItem.category != null)
                                                Text(
                                                  [invItem.brand, invItem.category].nonNulls.join(' · '),
                                                  style: AppTextStyles.caption.copyWith(
                                                    color: alreadyAdded ? context.ksc.neutral600 : context.ksc.neutral500,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (alreadyAdded)
                                          Icon(LineAwesomeIcons.check_circle_solid, size: 16, color: context.ksc.neutral600)
                                        else
                                          Icon(LineAwesomeIcons.plus_solid, size: 16, color: context.ksc.accent500),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final row = _ItemRow();
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
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? current, ValueChanged<String?> onChanged) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 10)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: context.ksc.primary700, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: current,
                dropdownColor: context.ksc.primary800,
                isExpanded: true,
                hint: Text("Select", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
                items: options.map((opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt.replaceAll('_', ' ').toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.white, fontWeight: FontWeight.w600)),
                )).toList(),
                onChanged: (v) => setState(() => onChanged(v)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGroup(String label, List<XFile> photos, {VoidCallback? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(
          children: [
            ...photos.map((p) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      image: p.path.endsWith('.mp4') || p.path.endsWith('.m4a')
                          ? null
                          : DecorationImage(image: FileImage(File(p.path)), fit: BoxFit.cover),
                    ),
                    child: p.path.endsWith('.mp4')
                        ? Icon(LineAwesomeIcons.video_solid, color: context.ksc.accent500, size: 24)
                        : p.path.endsWith('.m4a')
                            ? Icon(LineAwesomeIcons.microphone_solid, color: context.ksc.accent500, size: 24)
                            : null,
                  ),
                  Positioned(top: 0, right: 0, child: GestureDetector(onTap: () {
                    setState(() => photos.remove(p));
                    onChanged?.call();
                  }, child: Container(color: Colors.black54, child: const Icon(Icons.close, size: 16, color: Colors.white)))),
                ],
              ),
            )),
                if (photos.length < 4)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _pickPhoto(photos);
                          onChanged?.call();
                        },
                        child: Container(width: 48, height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)), child: Icon(LineAwesomeIcons.camera_solid, color: context.ksc.neutral500, size: 18)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _pickVideo(photos);
                          onChanged?.call();
                        },
                        child: Container(width: 48, height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)), child: Icon(LineAwesomeIcons.video_solid, color: context.ksc.neutral500, size: 18)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _pickAudio(photos);
                      onChanged?.call();
                    },
                    child: Container(width: 48, height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)), child: Icon(LineAwesomeIcons.microphone_solid, color: context.ksc.neutral500, size: 18)),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickPhoto(List<XFile> list) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
    if (picked != null) setState(() => list.add(picked));
  }

  Future<void> _pickVideo(List<XFile> list) async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 60));
    if (picked != null) setState(() => list.add(picked));
  }

  Future<void> _pickAudio(List<XFile> list) async {
    try {
      final audioPath = '/tmp/keystone_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final recorder = AudioRecorder();
      await recorder.start(const RecordConfig(), path: audioPath);
      await Future.delayed(const Duration(seconds: 30));
      final recordedPath = await recorder.stop();
      if (recordedPath != null && mounted) {
        setState(() => list.add(XFile(recordedPath)));
      }
    } catch (e) {
      debugPrint('[KS:AUDIO] Record failed: $e');
    }
  }

  String _inferMediaType(String path) {
    if (path.endsWith('.mp4') || path.endsWith('.mov')) return 'video';
    if (path.endsWith('.m4a') || path.endsWith('.mp3') || path.endsWith('.wav')) return 'audio';
    return 'image';
  }

  Widget _buildBottomAction(bool isLoading) {
    final isLastStep = _currentStep == _totalSteps - 1;
    final canGo = _canMoveForward;

    return Container(
      width: double.infinity,
      color: context.ksc.primary700,
      padding: const EdgeInsets.all(24.0),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: canGo && !isLoading ? _nextStep : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isLastStep ? 'SAVE JOB RECORD' : 'NEXT STEP',
                style: AppTextStyles.h2.copyWith(color: canGo ? context.ksc.white : context.ksc.neutral500.withValues(alpha: 0.3), fontWeight: FontWeight.w900, letterSpacing: 1.5)
              ),
              if (isLoading) CircularProgressIndicator(color: context.ksc.accent500)
              else Icon(isLastStep ? LineAwesomeIcons.check_solid : LineAwesomeIcons.arrow_right_solid, color: canGo ? context.ksc.accent500 : context.ksc.neutral600),
            ],
          ),
        ),
      ),
    );
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
