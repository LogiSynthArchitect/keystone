import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:keystone/core/theme/app_text_styles.dart';
import 'package:keystone/core/theme/ks_colors.dart';
import 'package:keystone/core/widgets/ks_sliding_notification.dart';
import 'package:keystone/core/widgets/ks_success_moment.dart';
import 'package:keystone/core/widgets/ks_confirm_dialog.dart';
import 'package:keystone/core/widgets/ks_step_drawer.dart';
import 'package:keystone/core/providers/auth_provider.dart';
import 'package:keystone/core/providers/permissions_provider.dart';
import 'package:keystone/core/utils/currency_formatter.dart';
import 'package:keystone/features/recurring_jobs/presentation/providers/recurring_schedule_provider.dart';
import 'package:keystone/features/inventory/presentation/providers/inventory_providers.dart';
import 'package:keystone/features/inventory/presentation/widgets/inventory_item_card.dart';
import 'package:keystone/core/widgets/ks_search_bar.dart';
import 'package:keystone/core/widgets/ks_empty_state.dart';
import '../widgets/job_step_types.dart';
import '../providers/job_providers.dart';
import '../../domain/entities/job_entity.dart';
import '../../domain/entities/job_part_entity.dart';
import '../../domain/entities/job_hardware_entity.dart';
import '../../domain/entities/job_service_entity.dart';
import '../../domain/entities/job_expense_entity.dart';
import '../../domain/entities/job_photo_entity.dart';
import '../../domain/usecases/edit_job_usecase.dart';
import '../../data/models/pending_edit_transaction.dart';
import 'package:keystone/core/providers/shared_feature_providers.dart';
import '../../../customer_history/domain/entities/customer_entity.dart';
import '../widgets/job_step_service.dart';
import '../widgets/job_step_status.dart';
import '../widgets/job_step_customer.dart';
import '../widgets/job_step_pricing.dart';
import '../widgets/job_step_schedule.dart';
import '../widgets/job_step_extras.dart';
import 'package:keystone/core/widgets/ks_bottom_sheet_scaffold.dart';
import 'package:keystone/core/utils/service_icon_map.dart';
import '../../../service_types/domain/entities/service_type_entity.dart';

/// Static entry point — shows the Edit Job drawer as a bottom sheet.
class EditJobScreen {
  static Future<void> show(BuildContext context, String jobId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => _EditJobSheet(jobId: jobId),
    );
  }
}

class _EditJobSheet extends ConsumerStatefulWidget {
  final String jobId;
  const _EditJobSheet({required this.jobId});

  @override
  ConsumerState<_EditJobSheet> createState() => _EditJobSheetState();
}

class _EditJobSheetState extends ConsumerState<_EditJobSheet> {
  bool _initialized = false;
  bool _isSaving = false;

  String? _serviceType;
  String _status = 'in_progress';
  String? _originalJobStatus; // locked reference for status transition gating
  String _paymentStatus = 'unpaid';
  String? _leadSource;
  DateTime _jobDate = DateTime.now();
  bool _isRecurring = false;
  String _recurringInterval = '';

  final _locationController = TextEditingController();
  final _amountController = TextEditingController();
  final _quotedAmountController = TextEditingController();
  final _notesController = TextEditingController();
  late final _quotedFocusNode = currencyFocusNode(_quotedAmountController);
  late final _amountFocusNode = currencyFocusNode(_amountController);

  // CUSTOMER step
  final _customerController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _matchedCustomerName;
  String? _matchedCustomerId;

  // SERVICE step — uses ServiceRow (matching LogJobScreen) instead of JobServiceEntity
  List<ServiceRow> _additionalServices = [];

  // EXTRAS step data
  List<ItemRow> _items = [];
  List<JobPartEntity> _parts = [];
  List<JobPartEntity> _originalParts = []; // snapshot for COGS delta computation
  List<JobHardwareEntity> _hardwareItems = [];
  List<JobExpenseEntity> _expenses = [];

  // PHOTOS
  List<JobPhotoEntity> _existingPhotos = [];
  List<XFile> _newGeneralPhotos = [];
  List<XFile> _newBeforePhotos = [];
  List<XFile> _newAfterPhotos = [];
  Set<String> _deletedPhotoIds = {};
  final AudioRecorder _audioRecorder = AudioRecorder();

  int get _photoCount => _existingPhotos.length + _newGeneralPhotos.length + _newBeforePhotos.length + _newAfterPhotos.length;

  @override
  void dispose() {
    _locationController.dispose();
    _amountController.dispose();
    _quotedAmountController.dispose();
    _notesController.dispose();
    _customerController.dispose();
    _phoneController.dispose();
    _quotedFocusNode.dispose();
    _amountFocusNode.dispose();
    _audioRecorder.dispose();

    for (final s in _additionalServices) { s.dispose(); }
    for (final i in _items) { i.dispose(); }
    super.dispose();
  }

  Future<void> _loadPhotos(String jobId) async {
    final photos = await ref.read(jobPhotosProvider(jobId).future);
    if (mounted) setState(() => _existingPhotos = photos);
  }

  void _initFromJob(JobEntity job) {
    if (_initialized) return;
    _serviceType = job.serviceType;
    _status = job.status;
    _originalJobStatus = job.status;
    _paymentStatus = job.paymentStatus;
    _locationController.text = job.location ?? '';
    _amountController.text = job.amountCharged != null ? (job.amountCharged! / 100.0).toStringAsFixed(2) : '';
    _quotedAmountController.text = job.quotedPrice != null ? job.quotedPrice!.toStringAsFixed(2) : '';
    _notesController.text = job.notes ?? '';
    _leadSource = job.leadSource;
    _jobDate = job.jobDate;
    _initialized = true;

    _loadHardware(job.id);
    _loadParts(job.id);
    _loadServices(job.id);
    _loadExpenses(job.id);
    _loadPhotos(job.id);
    _loadCustomer(job.customerId);
    _loadRecurringSchedule(job.customerId);
  }

  void _populateServiceRows(List<JobServiceEntity> services) {
    for (final svc in services) {
      final row = ServiceRow();
      row.serviceType = svc.serviceType;
      row.qtyController.text = svc.quantity.toString();
      if (svc.unitPrice != null) {
        row.priceController.text = (svc.unitPrice! / 100.0).toStringAsFixed(2);
      }
      _additionalServices.add(row);
    }
  }

  void _populateCustomer(CustomerEntity customer) {
    _customerController.text = customer.fullName;
    _phoneController.text = customer.phoneNumber;
    _matchedCustomerName = customer.fullName;
    _matchedCustomerId = customer.id;
  }

  bool get _isDirty => _initialized && (
    _locationController.text.isNotEmpty ||
    _amountController.text.isNotEmpty ||
    _notesController.text.isNotEmpty ||
    _parts.isNotEmpty ||
    _hardwareItems.isNotEmpty ||
    _additionalServices.isNotEmpty ||
    _expenses.isNotEmpty
  );

  Future<void> _loadCustomer(String customerId) async {
    try {
      final repo = ref.read(customerRepositoryProvider);
      final customer = await repo.getCustomerById(customerId);
      if (mounted) setState(() => _populateCustomer(customer));
    } catch (_) {}
  }

  Future<void> _loadExpenses(String jobId) async {
    final items = await ref.read(jobExpensesProvider(jobId).future);
    if (mounted) setState(() => _expenses = items);
  }

  Future<void> _loadHardware(String jobId) async {
    final items = await ref.read(jobHardwareProvider(jobId).future);
    if (mounted) setState(() => _hardwareItems = items);
  }

  Future<void> _loadParts(String jobId) async {
    final items = await ref.read(jobPartsProvider(jobId).future);
    final invItems = ref.read(inventoryProvider).valueOrNull ?? [];
    if (mounted) {
      setState(() {
        _parts = items;
        _originalParts = items; // snapshot for COGS delta computation
        _items = items.map((p) {
          final row = ItemRow();
          row.nameController.text = p.partName;
          row.qtyController.text = (p.quantity ?? 1).toString();
          if (p.unitPrice != null) {
            row.priceController.text = (p.unitPrice! / 100.0).toStringAsFixed(2);
          }
          row.inventoryItemId = p.inventoryItemId;
          if (p.inventoryItemId != null) {
            row.inventoryItem = invItems.where((i) => i.id == p.inventoryItemId).firstOrNull;
          }
          return row;
        }).toList();
      });
    }
  }

  Future<void> _loadServices(String jobId) async {
    final items = await ref.read(jobServicesProvider(jobId).future);
    if (mounted) setState(() => _populateServiceRows(items));
  }

  void _loadRecurringSchedule(String customerId) {
    // Check if an active recurring schedule exists for this customer + service_type
    final schedules = ref.read(recurringScheduleProvider).valueOrNull ?? [];
    try {
      final match = schedules.firstWhere(
        (s) => s.isActive && s.customerId == customerId && s.serviceType == _serviceType,
      );
      if (mounted) {
        setState(() {
          _isRecurring = true;
          _recurringInterval = match.intervalType;
        });
      }
    } catch (_) {
      // No matching schedule found — leave defaults (false / '')
    }
  }

  Future<bool> _confirmDiscard() async {
    if (_isDirty) {
      return await KsConfirmDialog.show(
        context,
        title: 'DISCARD CHANGES?',
        message: 'You have unsaved changes. Discard them?',
        confirmLabel: 'DISCARD',
        cancelLabel: 'KEEP EDITING',
        isDanger: true,
        onConfirm: () {},
      ) ?? false;
    }
    return true;
  }

  Future<void> _onSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final user = await ref.read(currentUserProvider.future);
    if (user == null) { setState(() => _isSaving = false); return; }

    final changes = <String, dynamic>{};
    changes['service_type'] = _serviceType;
    changes['status'] = _status;
    changes['payment_status'] = _paymentStatus;
    changes['location'] = _locationController.text.trim();
    changes['notes'] = _notesController.text.trim();
    if (_leadSource != null) changes['lead_source'] = _leadSource;

    if (_amountController.text.isNotEmpty) {
      changes['amount_charged'] = double.tryParse(_amountController.text.trim());
    }
    if (_quotedAmountController.text.isNotEmpty) {
      changes['quoted_price'] = double.tryParse(_quotedAmountController.text.trim());
    }

    try {
      await ref.read(editJobUsecaseProvider).call(EditJobParams(
        jobId: widget.jobId,
        changes: changes,
        editedBy: user.id,
      ));

      // Convert ServiceRow → JobServiceEntity for persistence
      final serviceEntities = _additionalServices
          .where((s) => s.serviceType != null && s.serviceType!.isNotEmpty)
          .toList()
          .asMap()
          .entries
          .map((e) => JobServiceEntity(
                id: const Uuid().v4(),
                jobId: widget.jobId,
                serviceType: e.value.serviceType!,
                quantity: int.tryParse(e.value.qtyController.text.trim()) ?? 1,
                unitPrice: CurrencyFormatter.parseToPesewas(e.value.priceController.text.trim()),
                sortOrder: e.key,
                createdAt: DateTime.now(),
              ))
          .toList();

      final repo = ref.read(jobRepositoryProvider);
      // Signal that children are being saved — crash before completing means partial data
      await repo.setSubEntitiesSaved(widget.jobId, false);
      await repo.saveHardwareItems(widget.jobId, _hardwareItems);
      await repo.saveServices(widget.jobId, serviceEntities);
      // Parts — WAL-based COGS-aware replacement
      final validItems = _items.where((i) => i.displayName.isNotEmpty).toList();
      if (validItems.isNotEmpty || _originalParts.isNotEmpty) {
        // Build new part entities, preserving UUIDs for items that match by inventoryItemId
        final newParts = validItems.map((i) {
          final matchingOriginal = i.inventoryItemId != null
              ? _originalParts.where((p) => p.inventoryItemId == i.inventoryItemId).firstOrNull
              : null;
          return JobPartEntity(
            id: matchingOriginal?.id ?? const Uuid().v4(),
            jobId: widget.jobId,
            partName: i.displayName,
            quantity: int.tryParse(i.qtyController.text.trim()) ?? 1,
            unitPrice: CurrencyFormatter.parseToPesewas(i.priceController.text.trim()),
            inventoryItemId: i.inventoryItemId,
            createdAt: matchingOriginal?.createdAt ?? DateTime.now(),
          );
        }).toList();

        // Compute COGS delta per inventory item
        final invRepo = ref.read(inventoryRepositoryProvider);
        final allInv = await invRepo.getItems(user.id);
        final adjustments = <InventoryCogsAdjustment>[];
        final txnId = const Uuid().v4();
        for (final newPart in newParts) {
          if (newPart.inventoryItemId == null) continue;
          final invItem = allInv.where((i) => i.id == newPart.inventoryItemId && i.isAutoCogs).firstOrNull;
          if (invItem == null) continue;
          final oldQty = _originalParts
              .where((p) => p.inventoryItemId == newPart.inventoryItemId)
              .fold<int>(0, (sum, p) => sum + (p.quantity ?? 1));
          final newQty = newPart.quantity ?? 1;
          final delta = oldQty - newQty;
          if (delta != 0) {
            adjustments.add(InventoryCogsAdjustment(
              transactionId: txnId,
              itemId: invItem.id,
              delta: delta,
              reason: 'COGS edit: ${newPart.partName} used in job ${widget.jobId.substring(0, 8)}',
              referenceType: 'job',
              referenceId: widget.jobId,
            ));
          }
        }

        await repo.replacePartsWithCogs(widget.jobId, newParts, adjustments, txnId);
        for (final adj in adjustments) {
          await invRepo.adjustStock(
            adj.itemId, user.id, adj.delta, 'job_use',
            reason: adj.reason,
            referenceType: adj.referenceType,
            referenceId: adj.referenceId,
            transactionId: adj.transactionId,
          );
        }
      }

      await repo.saveExpenses(widget.jobId, _expenses);

      // Signal that children are complete — job is safe for sync
      await repo.setSubEntitiesSaved(widget.jobId, true);

      // Handle photo changes
      for (final id in _deletedPhotoIds) {
        await repo.deletePhoto(id);
      }
      final newPhotos = <(File, String, String)>[];
      for (final f in _newGeneralPhotos) {
        newPhotos.add((File(f.path), '', _inferMediaType(f.path)));
      }
      for (final f in _newBeforePhotos) {
        newPhotos.add((File(f.path), 'before', _inferMediaType(f.path)));
      }
      for (final f in _newAfterPhotos) {
        newPhotos.add((File(f.path), 'after', _inferMediaType(f.path)));
      }
      if (newPhotos.isNotEmpty) {
        await repo.savePhotos(widget.jobId, newPhotos);
      }

      if (mounted) {
        _refetch();
        Navigator.of(context).pop();
        await KsSuccessMoment.show(context,
          title: "Job Updated",
        );
      }
    } catch (e) {
      if (mounted) KsSlidingNotification.show(context, message: "Update failed: $e", type: KsNotificationType.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _refetch() {
    ref.invalidate(jobDetailProvider(widget.jobId));
    ref.read(jobListProvider.notifier).load();
  }

  // ──────────────────────────────────────────────
  // KsStepDrawer — loading/error/data shell
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailProvider(widget.jobId));
    return jobAsync.when(
      loading: () => _buildLoadingSheet(),
      error: (err, _) => _buildErrorSheet(err),
      data: (job) {
        if (job == null) return _buildErrorSheet('Job not found');
        _initFromJob(job);
        return _buildDrawer(job);
      },
    );
  }

  Widget _buildLoadingSheet() => Padding(
    padding: EdgeInsets.only(top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 48),
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetHandle(),
        SizedBox(height: 64),
        CircularProgressIndicator(),
        SizedBox(height: 64),
      ],
    ),
  );

  Widget _buildErrorSheet(Object err) => Padding(
    padding: EdgeInsets.only(top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 48),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SheetHandle(),
        const SizedBox(height: 48),
        Icon(LineAwesomeIcons.exclamation_triangle_solid, size: 48, color: context.ksc.error500),
        const SizedBox(height: 16),
        Text("FAILED TO LOAD", style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("$err", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => ref.invalidate(jobDetailProvider(widget.jobId)),
          style: ElevatedButton.styleFrom(backgroundColor: context.ksc.accent500, foregroundColor: context.ksc.primary900),
          child: const Text("TAP TO RETRY"),
        ),
        const SizedBox(height: 48),
      ],
    ),
  );

  Widget _buildDrawer(JobEntity job) {
    final permissions = ref.watch(permissionsProvider);
    final canEditPrice = permissions.canEditFinalPrice || (ref.watch(currentUserProvider).valueOrNull?.isAdmin ?? false);

    return KsStepDrawer(
      title: "EDIT JOB",
      showBackArrow: true,
      onBack: () => _confirmDiscard().then((ok) {
        if (ok && mounted) Navigator.of(context).pop();
      }),
      steps: const [
        KsStep(label: 'SERVICE', icon: LineAwesomeIcons.wrench_solid, subSteps: 1,
          tip: 'Select the main service performed',
          imageAsset: 'assets/icons/3d/transparent/ff5be0-tools.png'),
        KsStep(label: 'STATUS', icon: LineAwesomeIcons.flag_solid, subSteps: 1,
          tip: 'Set the job status',
          imageAsset: 'assets/icons/3d/transparent/e9828b-flag.png'),
        KsStep(label: 'CUSTOMER', icon: LineAwesomeIcons.user_solid, subSteps: 1,
          tip: 'Customer information (read-only on edit)',
          imageAsset: 'assets/icons/3d/transparent/eec43d-chat-bubble.png'),
        KsStep(label: 'PRICING', icon: LineAwesomeIcons.money_bill_wave_alt_solid, subSteps: 1,
          tip: 'Set the quoted or final amount',
          imageAsset: 'assets/icons/3d/transparent/b801dc-3d-coin.png'),
        KsStep(label: 'SCHEDULE', icon: LineAwesomeIcons.calendar_solid, subSteps: 1,
          tip: 'Set the job date and schedule',
          imageAsset: 'assets/icons/3d/transparent/781f28-calendar.png'),
        KsStep(label: 'EXTRAS', icon: LineAwesomeIcons.boxes_solid, subSteps: 1,
          tip: 'Add parts, expenses, and notes',
          imageAsset: 'assets/icons/3d/transparent/4f52f8-cube.png'),
      ],
      nextLabel: "NEXT STEP",
      saveLabel: "SAVE CHANGES",
      canAdvance: (step, subStep) => _canAdvance(step),
      onSave: _onSave,
      onClose: () => _confirmDiscard().then((ok) {
        if (ok && mounted) Navigator.of(context).pop();
      }),
      stepContent: (step, subStep, rebuild, advance) => _buildStepContent(step, advance, canEditPrice),
    );
  }

  bool _canAdvance(int step) {
    if (step == 0) return _serviceType != null && _serviceType!.isNotEmpty;
    return true;
  }

  Widget _buildStepContent(int step, VoidCallback? advance, bool canEditPrice) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _buildStepByIndex(step, advance, canEditPrice),
    );
  }

  Widget _buildStepByIndex(int step, VoidCallback? advance, bool canEditPrice) {
    switch (step) {
      case 0: return _buildServiceStep(advance);
      case 1: return _buildStatusStep();
      case 2: return _buildCustomerStep();
      case 3: return _buildPricingStep(canEditPrice);
      case 4: return _buildScheduleStep();
      case 5: return _buildExtrasStep();
      default: return const SizedBox.shrink();
    }
  }

  // ──────────────────────────────────────────────
  // Step builders
  // ──────────────────────────────────────────────

  Widget _buildServiceStep(VoidCallback? advance) {
    return JobStepService(
      serviceType: _serviceType,
      additionalServices: _additionalServices,
      onServiceTypeChanged: (t) => setState(() => _serviceType = t),
      onOpenAdditionalServices: _showAdditionalServicesDrawer,
    );
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
        for (final old in _additionalServices) { old.dispose(); }
        setState(() => _additionalServices = localServices);
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

  /// Read-only summary card for a selected service in the additional services drawer.
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

  /// Drawer 2: Edit qty + price for a single additional service.
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

  Widget _buildStatusStep() {
    return JobStepStatus(
      status: _status,
      leadSource: _leadSource,
      currentJobStatus: _originalJobStatus,
      onStatusChanged: (v) {
        // Check if this is a backward move while payment is set
        final currentStatusIdx = JobEntity.validStatuses.indexOf(_status);
        final newStatusIdx = JobEntity.validStatuses.indexOf(v);
        final isBackward = newStatusIdx < currentStatusIdx;
        final isPaymentSet = _paymentStatus == 'paid' || _paymentStatus == 'partial';

        if (isBackward && isPaymentSet) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: context.ksc.primary800,
              title: Text('Reset Payment?', style: TextStyle(color: context.ksc.white)),
              content: Text(
                'Moving the job status backward from "$_status" to "$v" will reset the payment status to "unpaid". Continue?',
                style: TextStyle(color: context.ksc.neutral400),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Cancel', style: TextStyle(color: context.ksc.neutral500)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _status = v;
                      _paymentStatus = 'unpaid';
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: Text('Reset & Continue', style: TextStyle(color: context.ksc.accent500)),
                ),
              ],
            ),
          );
        } else {
          setState(() {
            _status = v;
            final allowed = JobEntity.allowedPaymentStatuses(v);
            if (!allowed.contains(_paymentStatus)) {
              _paymentStatus = allowed.first;
            }
          });
        }
      },
      onLeadSourceChanged: (v) => setState(() => _leadSource = v),
    );
  }

  Widget _buildCustomerStep() {
    return JobStepCustomer(
      customerController: _customerController,
      phoneController: _phoneController,
      matchedCustomerName: _matchedCustomerName,
      matchedCustomerId: _matchedCustomerId,
      preSelectedCustomerId: true,
      onPhoneChanged: (_) {}, // no phone changes on edit
    );
  }

  Widget _buildPricingStep(bool canEditPrice) {
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

  Widget _buildScheduleStep() {
    return JobStepSchedule(
      isRecurring: _isRecurring,
      recurringInterval: _recurringInterval,
      jobDate: _jobDate,
      locationController: _locationController,
      onRecurringChanged: (v) => setState(() => _isRecurring = v),
      onIntervalChanged: (v) => setState(() => _recurringInterval = v),
      onDateChanged: (d) => setState(() => _jobDate = d),
    );
  }

  Widget _buildExtrasStep() {
    return JobStepExtras(
      customerId: null, // no customer history suggestions on edit
      itemCount: _hardwareItems.length + _parts.length,
      expenseCount: _expenses.length,
      expenseTotal: _expenses.fold<int>(0, (sum, e) => sum + (e.amount)),
      photoCount: _photoCount,
      notesPreview: _notesController.text.trim().isEmpty ? null : _notesController.text.trim().length > 25 ? '${_notesController.text.trim().substring(0, 25)}…' : _notesController.text.trim(),
      onOpenItems: _showItemsDrawer,
      onOpenExpenses: _showExpensesDrawer,
      onOpenMedia: _showMediaDrawer,
      onOpenNotes: _showNotesDrawer,
    );
  }

  void _showItemsDrawer() {
    // Merge parts + hardware into a single ItemRow list
    final hardwareRows = _hardwareItems.map((h) {
      final row = ItemRow();
      row.nameController.text = h.brand ?? h.category ?? 'Hardware';
      row.qtyController.text = h.quantity.toString();
      row.inventoryItemId = null;
      return row;
    });
    final localItems = [
      ..._items.map((i) => i.copy()),
      ...hardwareRows,
    ];
    bool dirty = false;

    KsBottomSheetScaffold.show<bool>(
      context,
      title: "ITEMS USED",
      isDirty: () => dirty,
      bottomLabel: "DONE",
      onDone: () {
        if (mounted) {
          setState(() {
            _items
              ..clear()
              ..addAll(localItems);
            // Convert items back to parts for persistence
            _parts = _items.where((i) => i.displayName.isNotEmpty).map((i) => JobPartEntity(
              id: const Uuid().v4(),
              jobId: widget.jobId,
              partName: i.displayName,
              quantity: int.tryParse(i.qtyController.text.trim()) ?? 1,
              unitPrice: CurrencyFormatter.parseToPesewas(i.priceController.text.trim()),
              inventoryItemId: i.inventoryItemId,
              createdAt: DateTime.now(),
            )).toList();
          });
        }
      },
      contentBuilder: (ctx, setSheetState) {
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
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(LineAwesomeIcons.box_solid, size: 36, color: context.ksc.neutral600),
                    const SizedBox(height: 12),
                    Text("NO ITEMS ADDED",
                      style: AppTextStyles.h3.copyWith(color: context.ksc.neutral600, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text("Tap ADD ITEM to add parts, supplies,\nor hardware items",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600)),
                  ],
                ),
              ),
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
    );
  }

  void _showMediaDrawer() {
    // Existing photos split by label
    final localGeneral = _existingPhotos.where((p) => p.label == null || p.label!.isEmpty).toList();
    final localBefore = _existingPhotos.where((p) => p.label == 'before').toList();
    final localAfter = _existingPhotos.where((p) => p.label == 'after').toList();
    // New photos
    final localNewGeneral = List<XFile>.from(_newGeneralPhotos);
    final localNewBefore = List<XFile>.from(_newBeforePhotos);
    final localNewAfter = List<XFile>.from(_newAfterPhotos);
    final localDeleted = Set<String>.from(_deletedPhotoIds);
    bool dirty = false;
    int selectedTab = 0; // 0=ALL, 1=BEFORE, 2=AFTER
    bool isLoading = false;

    KsBottomSheetScaffold.show(
      context,
      title: "MEDIA",
      subtitle: "${localGeneral.length + localBefore.length + localAfter.length + localNewGeneral.length + localNewBefore.length + localNewAfter.length} items",
      isDirty: () => dirty,
      bottomLabel: "DONE",
      onDone: () {
        setState(() {
          _existingPhotos = [...localGeneral, ...localBefore, ...localAfter];
          _newGeneralPhotos = localNewGeneral;
          _newBeforePhotos = localNewBefore;
          _newAfterPhotos = localNewAfter;
          _deletedPhotoIds = localDeleted;
        });
      },
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
            _buildEditMediaTab("ALL", localGeneral.length + localBefore.length + localAfter.length + localNewGeneral.length + localNewBefore.length + localNewAfter.length, 0, selectedTab, () {
              selectedTab = 0;
              setSheetState(() {});
            }),
            const SizedBox(width: 3),
            _buildEditMediaTab("BEFORE", localBefore.length + localNewBefore.length, 1, selectedTab, () {
              selectedTab = 1;
              setSheetState(() {});
            }),
            const SizedBox(width: 3),
            _buildEditMediaTab("AFTER", localAfter.length + localNewAfter.length, 2, selectedTab, () {
              selectedTab = 2;
              setSheetState(() {});
            }),
          ],
        ),
      ),
      contentBuilder: (ctx, setSheetState) {
        // Determine which existing and new lists to use based on tab
        final (List<JobPhotoEntity> existingForTab, List<XFile> newForTab, String label) = switch (selectedTab) {
          1 => (localBefore, localNewBefore, "BEFORE"),
          2 => (localAfter, localNewAfter, "AFTER"),
          _ => (localGeneral, localNewGeneral, ""),
        };

        return _buildEditMediaGrid(
          context: ctx,
          existingItems: existingForTab,
          newItems: newForTab,
          label: label,
          isLoading: isLoading,
          onRemoveExisting: (photoId) {
            localDeleted.add(photoId);
            existingForTab.removeWhere((p) => p.id == photoId);
            dirty = true;
            setSheetState(() {});
          },
          onRemoveNew: (index) {
            newForTab.removeAt(index);
            dirty = true;
            setSheetState(() {});
          },
          onAdd: () async {
            final source = await _showEditMediaSourceSheet(ctx);
            if (source == null || !ctx.mounted) return;

            isLoading = true;
            setSheetState(() {});

            XFile? picked;
            if (source == 'camera' || source == 'gallery') {
              final imgSource = source == 'camera' ? ImageSource.camera : ImageSource.gallery;
              picked = await ImagePicker().pickImage(source: imgSource, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
            } else if (source == 'videocam') {
              picked = await ImagePicker().pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 60));
            } else if (source == 'videogallery') {
              picked = await ImagePicker().pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
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
              newForTab.add(picked);
              dirty = true;
            }
            if (ctx.mounted) setSheetState(() {});
          },
        );
      },
    );
  }

  /// Tab button for ALL / BEFORE / AFTER toggle (edit job).
  Widget _buildEditMediaTab(String label, int count, int tabIndex, int selectedTab, VoidCallback onTap) {
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

  /// 2-column media grid for edit — shows existing + new items.
  Widget _buildEditMediaGrid({
    required BuildContext context,
    required List<JobPhotoEntity> existingItems,
    required List<XFile> newItems,
    required String label,
    required bool isLoading,
    required ValueChanged<String> onRemoveExisting,
    required ValueChanged<int> onRemoveNew,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (existingItems.isEmpty && newItems.isEmpty && !isLoading)
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
        if (existingItems.isNotEmpty || newItems.isNotEmpty || isLoading)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
            children: [
              // Existing photos
              ...existingItems.map((photo) =>
                _buildEditMediaCard(
                  storagePath: photo.storagePath,
                  mediaType: photo.mediaType,
                  onRemove: () => onRemoveExisting(photo.id),
                ),
              ),
              // New photos
              ...newItems.asMap().entries.map((entry) =>
                _buildEditNewMediaCard(file: entry.value, onRemove: () => onRemoveNew(entry.key)),
              ),
              if (isLoading) _buildEditShimmerCard(),
              // Add button
              _buildEditMediaAddCard(onTap: isLoading ? null : onAdd),
            ],
          ),
      ],
    );
  }

  /// Card for an existing photo (uses storagePath).
  Widget _buildEditMediaCard({
    required String storagePath,
    required String mediaType,
    required VoidCallback onRemove,
  }) {
    final isVideo = mediaType == 'video';
    final isAudio = mediaType == 'audio';
    final file = File(storagePath);
    final fileExists = file.existsSync();

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Container(
            width: double.infinity, height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: context.ksc.primary900,
              image: !isVideo && !isAudio && fileExists
                  ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
                  : null,
              border: Border.all(color: context.ksc.primary700),
            ),
            child: Center(
              child: isVideo
                  ? Icon(LineAwesomeIcons.video_solid, color: context.ksc.accent500, size: 28)
                  : isAudio
                      ? Icon(LineAwesomeIcons.microphone_solid, color: context.ksc.accent500, size: 28)
                      : !fileExists
                          ? Icon(LineAwesomeIcons.file_image_solid, color: context.ksc.neutral600, size: 28)
                          : null,
            ),
          ),
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
          // Type badge
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
          // Delete button
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

  /// Card for a newly picked file.
  Widget _buildEditNewMediaCard({
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
          if (isVideo)
            Positioned(
              top: 0, bottom: 0, left: 0, right: 0,
              child: Center(
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: context.ksc.accent500, borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                ),
              ),
            ),
          if (isAudio)
            Positioned(
              top: 0, bottom: 0, left: 0, right: 0,
              child: Center(
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: context.ksc.accent500, borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(LineAwesomeIcons.microphone_solid, color: context.ksc.primary900, size: 14),
                ),
              ),
            ),
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
                  color: context.ksc.primary900, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
                child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.error500, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Add media card — dashed border + plus icon.
  Widget _buildEditMediaAddCard({VoidCallback? onTap}) {
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

  /// Shimmer loading card.
  Widget _buildEditShimmerCard() {
    final size = (MediaQuery.of(context).size.width - 56) / 2;
    return SizedBox(
      width: size, height: size,
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
  Future<String?> _showEditMediaSourceSheet(BuildContext ctx) {
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
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: context.ksc.neutral600, borderRadius: BorderRadius.circular(2)),
                ),
              ),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildEditSourceOption(c, LineAwesomeIcons.camera_solid, "Camera", 'camera'),
                        const SizedBox(width: 10),
                        _buildEditSourceOption(c, LineAwesomeIcons.image_solid, "Gallery", 'gallery'),
                        const SizedBox(width: 10),
                        _buildEditSourceOption(c, LineAwesomeIcons.video_solid, "Video (Cam)", 'videocam'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildEditSourceOption(c, LineAwesomeIcons.film_solid, "Video (Gallery)", 'videogallery'),
                        const SizedBox(width: 10),
                        _buildEditSourceOption(c, LineAwesomeIcons.microphone_solid, "Audio", 'audio'),
                        const Expanded(child: SizedBox()),
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
  Widget _buildEditSourceOption(BuildContext ctx, IconData icon, String label, String value) {
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

  /// Infer media type from file path.
  String _inferMediaType(String path) {
    if (path.endsWith('.mp4') || path.endsWith('.mov')) return 'video';
    if (path.endsWith('.m4a') || path.endsWith('.mp3') || path.endsWith('.wav')) return 'audio';
    return 'image';
  }

  /// Audio recording dialog for capturing audio.
  // Shared via a simple internal widget at the bottom of this file.
  // The same pattern as LogJobScreen's _AudioRecordingDialog.

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
            hintText: "Job notes...",
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

  // ──────────────────────────────────────────────
  // Existing section builders (kept from original)
  // ──────────────────────────────────────────────

  // ── Items drawer helpers (matching Add Job pattern) ──────────────────

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
                child: _editField("Item Name", item.nameController),
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
      // drawer still reference item's controllers during unmounting. Disposing
      // them prematurely triggers "TextEditingController used after being disposed"
      // via Flutter's internal Listenable.merge([focusNode, controller]) in TextField.
      // The controller will be garbage-collected when the closure goes out of scope.
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
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: KsSearchBar(
                hint: "Search items...",
                controller: searchCtrl,
                onChanged: (_) => setSheetState(() {}),
              ),
            ),
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

  // ── End Items drawer helpers ──────────────────────────────────────

  void _showExpensesDrawer() {
    final localExpenses = _expenses.map((e) {
      final row = ExpenseRow();
      row.category = e.category;
      row.descriptionController.text = e.description;
      if (e.amount > 0) {
        row.amountController.text = (e.amount / 100.0).toStringAsFixed(2);
      }
      return row;
    }).toList();
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
          _expenses = localExpenses.map((e) => JobExpenseEntity(
            id: const Uuid().v4(),
            jobId: widget.jobId,
            category: e.category,
            description: e.descriptionController.text.trim(),
            amount: CurrencyFormatter.parseToPesewas(e.amountController.text.trim()) ?? 0,
            createdAt: DateTime.now(),
          )).toList();
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

  /// Summary card for an expense — shows emoji, category, description, amount.
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
              // Category emoji
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
  Future<bool> _openExpenseEditDrawer({
    required ExpenseRow expense,
    required int? existingIndex,
    required VoidCallback onChanged,
  }) async {
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

  Widget _editField(String label, TextEditingController controller,
      {bool isNumeric = false, ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
          style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 9)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          onChanged: onChanged,
          style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.bold, fontSize: 13),
          decoration: InputDecoration(
            hintText: isNumeric ? "0.00" : null,
            hintStyle: AppTextStyles.body.copyWith(color: context.ksc.neutral600, fontWeight: FontWeight.w900, fontSize: 13),
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

/// Shared drag handle widget for loading/error shells.
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: 40, height: 4,
        decoration: BoxDecoration(
          color: context.ksc.neutral600,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Audio recording dialog — used by _showMediaDrawer when recording audio.
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
