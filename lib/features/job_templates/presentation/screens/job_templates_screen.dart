import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_confirm_dialog.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../../core/widgets/ks_filter_sheet.dart';
import '../../../../core/widgets/ks_offline_banner.dart';
import '../../../../core/widgets/ks_search_bar.dart';
import '../../../../core/widgets/ks_step_drawer.dart';
import '../../../../core/widgets/ks_summary_strip.dart';
import '../../../../core/widgets/search_panel_body.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/icon_helpers.dart';
import '../providers/job_template_provider.dart';
import '../../domain/entities/job_template_entity.dart';

class JobTemplatesScreen extends ConsumerStatefulWidget {
  final void Function(JobTemplateEntity template)? onSelectTemplate;
  const JobTemplatesScreen({super.key, this.onSelectTemplate});

  @override
  ConsumerState<JobTemplatesScreen> createState() => _JobTemplatesScreenState();
}

class _JobTemplatesScreenState extends ConsumerState<JobTemplatesScreen> {
  bool _searchOpen = false;
  final _searchController = TextEditingController();
  String _filterServiceType = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserProvider).valueOrNull?.id;
      if (userId != null) {
        ref.read(jobTemplateProvider.notifier).loadTemplates(userId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasFilter => _filterServiceType != 'all';

  List<JobTemplateEntity> _filtered(List<JobTemplateEntity> templates) {
    var result = templates;
    if (_filterServiceType != 'all') {
      result = result.where((t) => t.serviceType == _filterServiceType).toList();
    }
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((t) {
        if (t.name.toLowerCase().contains(query)) return true;
        if (t.serviceType.toLowerCase().contains(query)) return true;
        return false;
      }).toList();
    }
    return result;
  }

  Set<String> _serviceTypes(List<JobTemplateEntity> templates) {
    return templates.map((t) => t.serviceType).where((s) => s.isNotEmpty).toSet();
  }

  Future<void> _showFilterSheet(BuildContext context, List<JobTemplateEntity> allTemplates) async {
    final currentType = _filterServiceType;
    final types = _serviceTypes(allTemplates);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) {
        var draftType = currentType;
        return StatefulBuilder(
          builder: (context, setInnerState) => KsFilterSheet(
            title: "FILTER TEMPLATES",
            onApply: () {
              setState(() => _filterServiceType = draftType);
            },
            onClear: () {
              draftType = 'all';
              setInnerState(() {});
            },
            children: [
              KsFilterChipGroup(
                label: "SERVICE TYPE",
                selected: draftType,
                onSelect: (v) => setInnerState(() { if (v != null) draftType = v; }),
                options: [
                  const KsFilterOption(value: 'all', display: 'ALL', icon: '📋'),
                  ...types.map((name) => KsFilterOption(value: name, display: name.toUpperCase().replaceAll('_', ' '))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(JobTemplateEntity template) {
    final nameCtrl = TextEditingController(text: template.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ksc.primary800,
        title: Text('RENAME TEMPLATE', style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: AppTextStyles.body.copyWith(color: context.ksc.white),
          decoration: InputDecoration(
            hintText: "Template name",
            hintStyle: TextStyle(color: context.ksc.neutral500),
            border: OutlineInputBorder(borderSide: BorderSide(color: context.ksc.primary700)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.ksc.primary700)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: AppTextStyles.label.copyWith(color: context.ksc.neutral400))),
          TextButton(onPressed: () {
            if (nameCtrl.text.trim().isNotEmpty) {
              Navigator.pop(ctx);
              ref.read(jobTemplateProvider.notifier).renameTemplate(template.id, nameCtrl.text.trim());
            }
          }, child: Text('SAVE', style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(jobTemplateProvider);

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "JOB TEMPLATES",
        showBack: true,
        searchable: true,
        isSearchOpen: _searchOpen,
        onSearchToggle: () => setState(() => _searchOpen = !_searchOpen),
        actions: [
          IconButton(
            icon: Icon(LineAwesomeIcons.filter_solid,
              color: _hasFilter ? context.ksc.accent500 : context.ksc.neutral400,
              size: 22),
            onPressed: () {
              final templates = ref.read(jobTemplateProvider).maybeWhen(
                data: (d) => d,
                orElse: () => <JobTemplateEntity>[],
              );
              _showFilterSheet(context, templates);
            },
          ),
        ],
      ),
      body: SearchPanelBody(
        isOpen: _searchOpen,
        searchContent: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: KsSearchBar(
            hint: "Search templates...",
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            onClear: () {
              _searchController.clear();
              setState(() {});
            },
          ),
        ),
        child: Column(
          children: [
            const KsOfflineBanner(),
            // Summary strip
            itemsAsync.whenOrNull(
              data: (items) {
                final withServices = items.where((t) => t.services.isNotEmpty).length;
                return KsSummaryStrip(
                  value: '${items.length}',
                  label: "TEMPLATES",
                  subtitle: '$withServices with services',
                  subtitleIcon: LineAwesomeIcons.file_solid,
                );
              },
            ) ?? const SizedBox.shrink(),
            Expanded(
              child: itemsAsync.when(
                loading: () => Center(child: CircularProgressIndicator(color: context.ksc.accent500)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LineAwesomeIcons.exclamation_triangle_solid, color: context.ksc.error500, size: 48),
                      const SizedBox(height: 16),
                      Text("FAILED TO LOAD", style: AppTextStyles.h2.copyWith(color: context.ksc.white)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          "$e",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: context.ksc.neutral400),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          final userId = ref.read(currentUserProvider).valueOrNull?.id;
                          if (userId != null) ref.read(jobTemplateProvider.notifier).loadTemplates(userId);
                        },
                        child: Text("TAP TO RETRY", style: AppTextStyles.label.copyWith(color: context.ksc.accent500)),
                      ),
                    ],
                  ),
                ),
                data: (templates) {
                  final filtered = _filtered(templates);
                  if (filtered.isEmpty) {
                    return KsEmptyState(
                      icon: LineAwesomeIcons.clipboard_list_solid,
                      title: templates.isEmpty ? "NO TEMPLATES" : "NO MATCHES",
                      subtitle: templates.isEmpty
                          ? "Save a job as template to reuse later"
                          : "Try a different search or filter",
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final t = filtered[index];
                      return _buildCard(t);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(JobTemplateEntity t) {
    final serviceCount = t.services.length;
    final partCount = t.parts.length;
    final hwCount = t.hardwareItems.length;
    final countParts = [
      if (serviceCount > 0) '$serviceCount services',
      if (hwCount > 0) '$hwCount hardware',
      if (partCount > 0) '$partCount parts',
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.ksc.primary700),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTemplatePreview(t),
          onLongPress: () => _showContextMenu(t),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: context.ksc.accent500.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    getLineAwesomeIcon(t.name),
                    color: context.ksc.accent500, size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: context.ksc.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.serviceType.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: context.ksc.neutral500,
                        ),
                      ),
                      if (countParts.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          countParts,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: context.ksc.accent500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow if selectable
                if (widget.onSelectTemplate != null)
                  Icon(LineAwesomeIcons.angle_right_solid, color: context.ksc.neutral500, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, {required Color color}) {
    return Row(
      children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _bulletRow(String left, String? right, {required Color bulletColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 4, height: 4, decoration: BoxDecoration(color: bulletColor, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(left, style: TextStyle(fontSize: 13, color: context.ksc.white, fontWeight: FontWeight.w500))),
          if (right != null) Text(right, style: TextStyle(fontSize: 12, color: context.ksc.neutral400, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showTemplatePreview(JobTemplateEntity t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (_) {
        return KsStepDrawer(
          title: t.name.toUpperCase(),
          steps: null,
          readOnly: true,
          saveLabel: "CLOSE",
          onSave: () async => Navigator.pop(context),
          stepContent: (step, subStep, rebuild, _) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.ksc.accent500.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    t.serviceType.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.ksc.accent500, letterSpacing: 0.8),
                  ),
                ),
                const SizedBox(height: 24),

                // ── SERVICES (gold accent) ──
                if (t.services.isNotEmpty) ...[
                  _sectionLabel('SERVICES', color: context.ksc.accent500),
                  const SizedBox(height: 10),
                  ...t.services.map((s) => _bulletRow(
                    '${s.quantity}x ${s.serviceType.replaceAll('_', ' ')}',
                    s.unitPrice != null ? '¢${(s.unitPrice! / 100).toStringAsFixed(0)}' : null,
                    bulletColor: context.ksc.accent500,
                  )),
                  const SizedBox(height: 20),
                ],

                // ── HARDWARE (blue accent) ──
                if (t.hardwareItems.isNotEmpty) ...[
                  _sectionLabel('HARDWARE', color: context.ksc.primary400),
                  const SizedBox(height: 10),
                  ...t.hardwareItems.map((h) => _bulletRow(
                    '${h.quantity}x ${h.name}',
                    h.unitSalePrice != null ? '¢${(h.unitSalePrice! / 100).toStringAsFixed(0)}' : null,
                    bulletColor: context.ksc.primary400,
                  )),
                  const SizedBox(height: 20),
                ],

                // ── PARTS (green accent) ──
                if (t.parts.isNotEmpty) ...[
                  _sectionLabel('PARTS', color: context.ksc.success500),
                  const SizedBox(height: 10),
                  ...t.parts.map((p) => _bulletRow(
                    '${p.quantity}x ${p.name}',
                    p.unitPrice != null ? '¢${(p.unitPrice! / 100).toStringAsFixed(0)}' : null,
                    bulletColor: context.ksc.success500,
                  )),
                  const SizedBox(height: 20),
                ],

                // ── NOTES (neutral accent) ──
                if (t.notes != null && t.notes!.isNotEmpty) ...[
                  _sectionLabel('NOTES', color: context.ksc.neutral400),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.ksc.primary700.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border(left: BorderSide(color: context.ksc.neutral400.withValues(alpha: 0.3), width: 2)),
                    ),
                    child: Text(t.notes!, style: TextStyle(fontSize: 12, color: context.ksc.neutral300, height: 1.5)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showContextMenu(JobTemplateEntity t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4, margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: context.ksc.neutral600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(LineAwesomeIcons.edit_solid, color: context.ksc.accent500, size: 20),
              title: Text('RENAME', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.ksc.white)),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(t);
              },
            ),
            ListTile(
              leading: Icon(LineAwesomeIcons.trash_alt_solid, color: context.ksc.error500, size: 20),
              title: Text('DELETE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.ksc.error500)),
              onTap: () {
                Navigator.pop(ctx);
                KsConfirmDialog.show(
                  context,
                  title: "DELETE TEMPLATE",
                  message: "Remove \"${t.name}\"?",
                  confirmLabel: "DELETE",
                  cancelLabel: "CANCEL",
                  isDanger: true,
                  onConfirm: () => ref.read(jobTemplateProvider.notifier).deleteTemplate(t.id),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
