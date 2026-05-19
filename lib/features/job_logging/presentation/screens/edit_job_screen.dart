import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:keystone/core/theme/app_text_styles.dart';
import 'package:keystone/core/theme/ks_colors.dart';
import 'package:keystone/core/widgets/ks_app_bar.dart';
import 'package:keystone/core/widgets/ks_offline_banner.dart';
import 'package:keystone/core/widgets/ks_snackbar.dart';
import 'package:keystone/core/providers/auth_provider.dart';
import 'package:keystone/core/providers/permissions_provider.dart';
import 'package:keystone/core/utils/currency_formatter.dart';
import 'package:keystone/core/utils/date_formatter.dart';
import '../providers/job_providers.dart';
import '../../domain/entities/job_entity.dart';
import '../../domain/entities/job_part_entity.dart';
import '../../domain/entities/job_hardware_entity.dart';
import '../../domain/entities/job_service_entity.dart';
import '../../domain/entities/job_expense_entity.dart';
import '../../domain/usecases/edit_job_usecase.dart';
import '../../../service_types/presentation/widgets/service_type_picker_v2.dart';

class EditJobScreen extends ConsumerStatefulWidget {
  final String jobId;
  const EditJobScreen({super.key, required this.jobId});

  @override
  ConsumerState<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends ConsumerState<EditJobScreen> {
  bool _initialized = false;
  bool _isSaving = false;
  
  String? _serviceType;
  String _status = 'in_progress';
  String _paymentStatus = 'unpaid';
  String? _paymentMethod;

  final _locationController     = TextEditingController();
  final _amountController       = TextEditingController();
  final _quotedAmountController = TextEditingController();
  final _notesController        = TextEditingController();
  List<JobPartEntity> _parts = [];
  List<JobHardwareEntity> _hardwareItems = [];
  List<JobServiceEntity> _services = [];
  bool _partsLoaded = false;
  bool _hardwareLoaded = false;
  bool _servicesLoaded = false;
  bool _expensesLoaded = false;
  String? _leadSource;
  DateTime _jobDate = DateTime.now();

  List<JobExpenseEntity> _expenses = [];

  // Temp controllers for adding new part
  final _newPartNameCtrl = TextEditingController();
  final _newPartQtyCtrl = TextEditingController(text: '1');
  final _newPartPriceCtrl = TextEditingController();

  void _initFromJob(JobEntity job) {
    if (_initialized) return;
    _serviceType = job.serviceType;
    _status = job.status;
    _paymentStatus = job.paymentStatus;
    _paymentMethod = job.paymentMethod;
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
  }

  Future<void> _loadExpenses(String jobId) async {
    final items = await ref.read(jobExpensesProvider(jobId).future);
    if (mounted) setState(() { _expenses = items; _expensesLoaded = true; });
  }

  Future<void> _loadHardware(String jobId) async {
    final items = await ref.read(jobHardwareProvider(jobId).future);
    if (mounted) setState(() { _hardwareItems = items; _hardwareLoaded = true; });
  }

  Future<void> _loadParts(String jobId) async {
    final items = await ref.read(jobPartsProvider(jobId).future);
    if (mounted) setState(() { _parts = items; _partsLoaded = true; });
  }

  Future<void> _loadServices(String jobId) async {
    final items = await ref.read(jobServicesProvider(jobId).future);
    if (mounted) setState(() { _services = items; _servicesLoaded = true; });
  }

  bool get _isDirty => _initialized && (
    _locationController.text.isNotEmpty ||
    _amountController.text.isNotEmpty ||
    _notesController.text.isNotEmpty ||
    _parts.isNotEmpty ||
    _hardwareItems.isNotEmpty ||
    _services.isNotEmpty
  );

  Future<void> _onSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final user = await ref.read(currentUserProvider.future);
    if (user == null) { setState(() => _isSaving = false); return; }

    final changes = <String, dynamic>{};
    
    // Simplistic diffing for core fields
    changes['service_type'] = _serviceType;
    changes['status'] = _status;
    changes['payment_status'] = _paymentStatus;
    changes['payment_method'] = _paymentMethod;
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

      final repo = ref.read(jobRepositoryProvider);
      await repo.saveHardwareItems(widget.jobId, _hardwareItems);
      await repo.saveServices(widget.jobId, _services);
      await repo.saveParts(widget.jobId, _parts);
      await repo.saveExpenses(widget.jobId, _expenses);

      if (mounted) {
        _refetch();
        context.pop();
        KsSnackbar.show(context, message: "Job updated", type: KsSnackbarType.success);
      }
    } catch (e) {
      if (mounted) KsSnackbar.show(context, message: "Update failed: $e", type: KsSnackbarType.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _refetch() {
    ref.invalidate(jobDetailProvider(widget.jobId));
    ref.read(jobListProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailProvider(widget.jobId));
    final permissions = ref.watch(permissionsProvider);
    final isAdmin = ref.watch(currentUserProvider).valueOrNull?.isAdmin ?? false;
    final canEditPrice = permissions.canEditFinalPrice || isAdmin;

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: const KsAppBar(title: "EDIT JOB", showBack: true),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LineAwesomeIcons.exclamation_triangle_solid, size: 64, color: context.ksc.error500),
                const SizedBox(height: 24),
                Text("FAILED TO LOAD", style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text("Could not load this job.", textAlign: TextAlign.center, style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(jobDetailProvider(widget.jobId)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.ksc.accent500,
                    foregroundColor: context.ksc.primary900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text("TAP TO RETRY"),
                ),
              ],
            ),
          ),
        ),
        data: (job) {
          if (job == null) return const Center(child: Text("Job not found"));
          _initFromJob(job);

          return PopScope(
            canPop: !_isDirty,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && _isDirty) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: context.ksc.primary800,
                    title: Text("DISCARD CHANGES?", style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                    content: Text("You have unsaved changes. Discard them?", style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.neutral400)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text("KEEP EDITING", style: TextStyle(color: context.ksc.neutral400))),
                      TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: Text("DISCARD", style: TextStyle(color: context.ksc.error500, fontWeight: FontWeight.bold))),
                    ],
                  ),
                );
              }
            },
            child: Column(
            children: [
              const KsOfflineBanner(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section("SERVICE & STATUS"),
                      ServiceTypePickerV2(
                        selected: _serviceType,
                        onSelected: (t) => setState(() => _serviceType = t),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusSelector(),
                      
                      const SizedBox(height: 32),
                      _section("FINANCIALS"),
                      _field("Quoted Amount", _quotedAmountController, readOnly: !canEditPrice),
                      const SizedBox(height: 16),
                      _field("Final Amount", _amountController, readOnly: !canEditPrice),
                      const SizedBox(height: 16),
                      _buildPaymentStatusRow(),
                      const SizedBox(height: 16),
                      _buildLeadSourceRow(),

                      const SizedBox(height: 32),
                      _section("HARDWARE ITEMS"),
                      if (_hardwareLoaded) _buildHardwareItemsSection(),

                      if (_partsLoaded) ...[
                        const SizedBox(height: 32),
                        _buildPartsSection(),
                      ],

                      if (_servicesLoaded) ...[
                        const SizedBox(height: 32),
                        _buildServicesSection(),
                      ],

                      if (_expensesLoaded) ...[
                        const SizedBox(height: 32),
                        _buildExpensesSection(),
                      ],

                      const SizedBox(height: 32),
                      _section("LOCATION & DATE"),
                      _field("Location", _locationController),
                      const SizedBox(height: 16),
                      _buildDatePicker(),
                      const SizedBox(height: 16),
                      _field("Notes", _notesController, maxLines: 3),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              ],
            ),
          );
          },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(title, style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
  );

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1, bool readOnly = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 10)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: readOnly ? context.ksc.primary700 : context.ksc.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(color: readOnly ? context.ksc.neutral500 : Colors.white, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      ),
    ],
  );

  Widget _buildStatusSelector() {
    final opts = [('quoted', 'QUOTED'), ('in_progress', 'IN PROGRESS'), ('completed', 'COMPLETED'), ('invoiced', 'INVOICED')];
    return Wrap(
      spacing: 8,
      children: opts.map((o) {
        final sel = _status == o.$1;
        return GestureDetector(
          onTap: () => setState(() => _status = o.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: sel ? context.ksc.accent500 : context.ksc.primary700),
            ),
            child: Text(o.$2, style: AppTextStyles.caption.copyWith(color: sel ? context.ksc.accent500 : context.ksc.neutral400, fontWeight: FontWeight.w900)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentStatusRow() {
    final opts = [('unpaid', 'UNPAID'), ('partial', 'PARTIAL'), ('paid', 'PAID')];
    return Row(
      children: opts.map((o) {
        final sel = _paymentStatus == o.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _paymentStatus = o.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary800,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: sel ? context.ksc.accent500 : context.ksc.primary700),
              ),
              child: Text(o.$2, style: AppTextStyles.caption.copyWith(color: sel ? context.ksc.accent500 : context.ksc.neutral400, fontWeight: FontWeight.w900)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() => Container(
    padding: const EdgeInsets.all(24),
    color: context.ksc.primary800,
    child: SafeArea(
      top: false,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.ksc.accent500,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: _isSaving
            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: context.ksc.primary900))
            : Text("SAVE CHANGES", style: AppTextStyles.h2.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900)),
      ),
    ),
  );

  Widget _buildHardwareItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("HARDWARE ITEMS", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            TextButton.icon(
              onPressed: () => _addHardwareItem(),
              icon: Icon(LineAwesomeIcons.plus_solid, size: 14, color: context.ksc.accent500),
              label: Text("ADD", style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
            ),
          ],
        ),
        if (_hardwareItems.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text("No hardware items", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
          ),
        ..._hardwareItems.asMap().entries.map((entry) => _buildEditableHardwareRow(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildEditableHardwareRow(int index, JobHardwareEntity item) {
    final brandCtrl = TextEditingController(text: item.brand);
    final modelCtrl = TextEditingController(text: item.model);
    final keySpecCtrl = TextEditingController(text: item.keySpec);
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: context.ksc.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("ITEM ${index + 1}", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _hardwareItems.removeAt(index)),
                child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.error500, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _editField("Brand", brandCtrl, onChanged: (v) => _hardwareItems[index] = item.copyWith(brand: v))),
              const SizedBox(width: 8),
              Expanded(child: _editField("Model", modelCtrl, onChanged: (v) => _hardwareItems[index] = item.copyWith(model: v))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _editField("Key Spec", keySpecCtrl, onChanged: (v) => _hardwareItems[index] = item.copyWith(keySpec: v))),
              const SizedBox(width: 8),
              Expanded(child: _editField("Qty", qtyCtrl, isNumeric: true, onChanged: (v) => _hardwareItems[index] = item.copyWith(quantity: int.tryParse(v) ?? 1))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("PARTS USED", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            TextButton.icon(
              icon: Icon(LineAwesomeIcons.plus_solid, size: 14, color: context.ksc.accent500),
              label: Text("ADD", style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
              onPressed: () => _showAddPartDialog(),
            ),
          ],
        ),
        if (_parts.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text("No parts", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
          ),
        ..._parts.asMap().entries.map((entry) => _buildEditablePartRow(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildEditablePartRow(int index, JobPartEntity part) {
    final nameCtrl = TextEditingController(text: part.partName);
    final qtyCtrl = TextEditingController(text: part.quantity.toString());
    final priceCtrl = TextEditingController(text: part.unitPrice != null ? (part.unitPrice! / 100.0).toStringAsFixed(2) : '');
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: context.ksc.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
      child: Row(
        children: [
          Expanded(flex: 3, child: _editField("Name", nameCtrl, onChanged: (v) => _parts[index] = part.copyWith(partName: v))),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: _editField("Qty", qtyCtrl, isNumeric: true, onChanged: (v) => _parts[index] = part.copyWith(quantity: int.tryParse(v) ?? 1))),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _editField("Price", priceCtrl, isNumeric: true, onChanged: (v) => _parts[index] = part.copyWith(unitPrice: CurrencyFormatter.parseToPesewas(v)))),
          GestureDetector(
            onTap: () => setState(() => _parts.removeAt(index)),
            child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.error500, size: 18),
          ),
        ],
      ),
    );
  }

  void _showAddPartDialog() {
    _newPartNameCtrl.clear();
    _newPartQtyCtrl.text = '1';
    _newPartPriceCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ksc.primary800,
        title: Text("ADD PART", style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _editField("Part Name", _newPartNameCtrl),
            const SizedBox(height: 12),
            _editField("Quantity", _newPartQtyCtrl, isNumeric: true),
            const SizedBox(height: 12),
            _editField("Price (GHS)", _newPartPriceCtrl, isNumeric: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: TextStyle(color: context.ksc.neutral400))),
          TextButton(
            onPressed: () {
              if (_newPartNameCtrl.text.trim().isEmpty) return;
              setState(() {
                _parts.add(JobPartEntity(
                  id: const Uuid().v4(),
                  jobId: widget.jobId,
                  partName: _newPartNameCtrl.text.trim(),
                  quantity: int.tryParse(_newPartQtyCtrl.text.trim()) ?? 1,
                  unitPrice: CurrencyFormatter.parseToPesewas(_newPartPriceCtrl.text.trim()),
                  createdAt: DateTime.now(),
                ));
              });
              Navigator.pop(ctx);
            },
            child: Text("ADD", style: TextStyle(color: context.ksc.accent500, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addHardwareItem() {
    setState(() {
      _hardwareItems.add(JobHardwareEntity(
        id: const Uuid().v4(),
        jobId: widget.jobId,
        brand: '',
        quantity: 1,
        sortOrder: _hardwareItems.length,
        createdAt: DateTime.now(),
      ));
    });
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("ADDITIONAL SERVICES", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            TextButton.icon(
              icon: Icon(LineAwesomeIcons.plus_solid, size: 14, color: context.ksc.accent500),
              label: Text("ADD", style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
              onPressed: () => _addServiceItem(),
            ),
          ],
        ),
        if (_services.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text("No additional services", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
          ),
        ..._services.asMap().entries.map((entry) => _buildEditableServiceRow(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildEditableServiceRow(int index, JobServiceEntity svc) {
    final typeCtrl = TextEditingController(text: svc.serviceType);
    final qtyCtrl = TextEditingController(text: svc.quantity.toString());
    final priceCtrl = TextEditingController(text: svc.unitPrice != null ? (svc.unitPrice! / 100.0).toStringAsFixed(2) : '');
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: context.ksc.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("SERVICE ${index + 1}", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _services.removeAt(index)),
                child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.error500, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ServiceTypePickerV2(
            selected: svc.serviceType,
            onSelected: (t) => setState(() => _services[index] = svc.copyWith(serviceType: t)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _editField("Qty", qtyCtrl, isNumeric: true, onChanged: (v) => _services[index] = svc.copyWith(quantity: int.tryParse(v) ?? 1))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _editField("Price (GHS)", priceCtrl, isNumeric: true, onChanged: (v) => _services[index] = svc.copyWith(unitPrice: CurrencyFormatter.parseToPesewas(v)))),
            ],
          ),
        ],
      ),
    );
  }

  void _addServiceItem() {
    setState(() {
      _services.add(JobServiceEntity(
        id: const Uuid().v4(),
        jobId: widget.jobId,
        serviceType: '',
        sortOrder: _services.length,
        createdAt: DateTime.now(),
      ));
    });
  }

  Widget _buildLeadSourceRow() {
    final sources = ['referral', 'walk_in', 'whatsapp', 'repeat_customer', 'social_media', 'phone_call', 'online_search', 'other'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("LEAD SOURCE", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: sources.map((s) {
            final isSel = _leadSource == s;
            return GestureDetector(
              onTap: () => setState(() => _leadSource = isSel ? null : s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary800,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isSel ? context.ksc.accent500 : context.ksc.primary700),
                ),
                child: Text(s.replaceAll('_', ' ').toUpperCase(), style: AppTextStyles.caption.copyWith(
                  color: isSel ? context.ksc.accent500 : context.ksc.neutral400,
                  fontWeight: FontWeight.w900,
                )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: _jobDate, firstDate: DateTime(2024), lastDate: DateTime.now());
        if (picked != null) setState(() => _jobDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.ksc.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
        child: Row(children: [
          Icon(LineAwesomeIcons.calendar, size: 20, color: context.ksc.accent500),
          const SizedBox(width: 12),
          Text(DateFormatter.short(_jobDate), style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildExpensesSection() {
    final expTotal = _expenses.fold<int>(0, (sum, e) => sum + (e.amount));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("EXPENSES", style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            TextButton.icon(
              onPressed: () => _showExpensesDrawer(),
              icon: Icon(LineAwesomeIcons.plus_solid, size: 14, color: context.ksc.accent500),
              label: Text(_expenses.isNotEmpty ? "${_expenses.length} items · ${CurrencyFormatter.format(expTotal)}" : "ADD",
                style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
            ),
          ],
        ),
        if (_expenses.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text("No expenses", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
          ),
        ..._expenses.asMap().entries.map((entry) => _buildExpenseRow(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildExpenseRow(int index, JobExpenseEntity expense) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: context.ksc.primary800, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.category.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text(expense.description, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(CurrencyFormatter.format(expense.amount), style: AppTextStyles.caption.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _expenses.removeAt(index)),
              child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.error500, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpensesDrawer() {
    // Local working copies for editing
    final localExpenses = _expenses.map((e) => JobExpenseEntity(
      id: e.id, jobId: e.jobId, category: e.category,
      description: e.description, amount: e.amount, createdAt: e.createdAt,
    )).toList();
    bool dirty = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final categories = ['transport', 'parking', 'subcontractor', 'supplies', 'other'];
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
                              Text("EXPENSES", style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 2),
                              Text(localExpenses.isNotEmpty ? "${localExpenses.length} items" : "No expenses", style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (dirty) {
                              final ok = await _confirmDiscardDrawer(ctx);
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
                          ...localExpenses.asMap().entries.map((entry) {
                            final e = entry.value;
                            final catCtrl = TextEditingController(text: e.category);
                            final descCtrl = TextEditingController(text: e.description);
                            final amtCtrl = TextEditingController(text: e.amount > 0 ? (e.amount / 100.0).toStringAsFixed(2) : '');
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: context.ksc.primary900, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _editField("Category",
                                          TextEditingController(text: e.category.toUpperCase()),
                                          onChanged: (v) { dirty = true; },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _editField("Amount (GHS)", amtCtrl, isNumeric: true,
                                          onChanged: (v) {
                                            dirty = true;
                                            localExpenses[entry.key] = JobExpenseEntity(
                                              id: e.id, jobId: e.jobId, category: catCtrl.text,
                                              description: descCtrl.text,
                                              amount: CurrencyFormatter.parseToPesewas(v) ?? 0,
                                              createdAt: e.createdAt,
                                            );
                                          },
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () { localExpenses.removeAt(entry.key); dirty = true; setSheetState(() {}); },
                                        child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.error500, size: 18),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _editField("Description", descCtrl, onChanged: (v) {
                                    dirty = true;
                                    localExpenses[entry.key] = JobExpenseEntity(
                                      id: e.id, jobId: e.jobId, category: catCtrl.text,
                                      description: v,
                                      amount: CurrencyFormatter.parseToPesewas(amtCtrl.text) ?? 0,
                                      createdAt: e.createdAt,
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),
                          if (localExpenses.length < 10)
                            TextButton.icon(
                              onPressed: () {
                                localExpenses.add(JobExpenseEntity(
                                  id: const Uuid().v4(), jobId: widget.jobId, category: 'transport',
                                  description: '', amount: 0, createdAt: DateTime.now(),
                                ));
                                dirty = true;
                                setSheetState(() {});
                              },
                              icon: const Icon(LineAwesomeIcons.plus_solid, size: 16),
                              label: Text("ADD EXPENSE", style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
                            ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => _expenses = localExpenses);
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: context.ksc.accent500, elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                              child: Text("DONE", style: AppTextStyles.label.copyWith(color: context.ksc.primary900,
                                fontWeight: FontWeight.w900, letterSpacing: 1.0)),
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

  Future<bool> _confirmDiscardDrawer(BuildContext sheetCtx) async {
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

  Widget _editField(String label, TextEditingController controller, {bool isNumeric = false, ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 9)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(color: context.ksc.primary700, borderRadius: BorderRadius.circular(4), border: Border.all(color: context.ksc.primary700)),
          child: TextField(
            controller: controller,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            onChanged: onChanged,
            style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.bold, fontSize: 13),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
          ),
        ),
      ],
    );
  }
}
