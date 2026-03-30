import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:keystone/core/theme/app_text_styles.dart';
import 'package:keystone/core/theme/ks_colors.dart';
import 'package:keystone/core/widgets/ks_app_bar.dart';
import 'package:keystone/core/widgets/ks_offline_banner.dart';
import 'package:keystone/core/widgets/ks_snackbar.dart';
import 'package:keystone/core/providers/auth_provider.dart';
import 'package:keystone/core/providers/permissions_provider.dart';
import '../providers/job_providers.dart';
import '../../domain/entities/job_entity.dart';
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
  
  String? _serviceType;
  String _status = 'in_progress';
  String _paymentStatus = 'unpaid';
  String? _paymentMethod;

  final _locationController     = TextEditingController();
  final _amountController       = TextEditingController();
  final _quotedAmountController = TextEditingController();
  final _notesController        = TextEditingController();
  final _brandController        = TextEditingController();
  final _keywayController       = TextEditingController();

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
    _brandController.text = job.hardwareBrand ?? '';
    _keywayController.text = job.hardwareKeyway ?? '';
    _initialized = true;
  }

  Future<void> _onSave() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    final changes = <String, dynamic>{};
    
    // Simplistic diffing for core fields
    changes['service_type'] = _serviceType;
    changes['status'] = _status;
    changes['payment_status'] = _paymentStatus;
    changes['payment_method'] = _paymentMethod;
    changes['location'] = _locationController.text.trim();
    changes['notes'] = _notesController.text.trim();
    changes['hardware_brand'] = _brandController.text.trim();
    changes['hardware_keyway'] = _keywayController.text.trim();
    
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
      if (mounted) {
        _refetch();
        context.pop();
        KsSnackbar.show(context, message: "Job updated", type: KsSnackbarType.success);
      }
    } catch (e) {
      if (mounted) KsSnackbar.show(context, message: "Update failed: $e", type: KsSnackbarType.error);
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
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (job) {
          if (job == null) return const Center(child: Text("Job not found"));
          _initFromJob(job);

          return Column(
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

                      const SizedBox(height: 32),
                      _section("HARDWARE"),
                      _field("Brand", _brandController),
                      const SizedBox(height: 16),
                      _field("Keyway", _keywayController),

                      const SizedBox(height: 32),
                      _section("OTHER"),
                      _field("Location", _locationController),
                      const SizedBox(height: 16),
                      _field("Notes", _notesController, maxLines: 3),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
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
        onPressed: _onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.ksc.accent500,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text("SAVE CHANGES", style: AppTextStyles.h2.copyWith(color: context.ksc.primary900, fontWeight: FontWeight.w900)),
      ),
    ),
  );
}
