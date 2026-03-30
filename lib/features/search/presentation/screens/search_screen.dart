import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: AppBar(
        backgroundColor: context.ksc.primary900,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: (q) => ref.read(searchProvider.notifier).search(q),
          style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white),
          cursorColor: context.ksc.accent500,
          decoration: InputDecoration(
            hintText: 'Search jobs, customers, notes...',
            hintStyle: AppTextStyles.body.copyWith(color: context.ksc.neutral500),
            border: InputBorder.none,
            prefixIcon: Icon(LineAwesomeIcons.search_solid, color: context.ksc.neutral500, size: 20),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('CANCEL',
                style: AppTextStyles.captionMedium.copyWith(color: context.ksc.accent500)),
          ),
        ],
      ),
      body: _controller.text.isEmpty
          ? _SearchHint()
          : results.isSearching
              ? Center(child: CircularProgressIndicator(color: context.ksc.accent500))
              : results.isEmpty
                  ? _NoResults(query: results.query)
                  : _Results(results: results),
    );
  }
}

// ── Results ───────────────────────────────────────────────────────────────────

class _Results extends StatelessWidget {
  final SearchResults results;
  const _Results({required this.results});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (results.jobs.isNotEmpty) ...[
          _SectionLabel('JOBS (${results.jobs.length})'),
          ...results.jobs.map((j) => _JobTile(job: j)),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (results.customers.isNotEmpty) ...[
          _SectionLabel('CUSTOMERS (${results.customers.length})'),
          ...results.customers.map((c) => _CustomerTile(customer: c)),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (results.notes.isNotEmpty) ...[
          _SectionLabel('NOTES (${results.notes.length})'),
          ...results.notes.map((n) => _NoteTile(note: n)),
        ],
        const SizedBox(height: AppSpacing.huge),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
      child: Text(
        label,
        style: AppTextStyles.captionMedium.copyWith(
          color: context.ksc.neutral500,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  final job;
  const _JobTile({required this.job});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.jobDetail(job.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          children: [
            Icon(LineAwesomeIcons.briefcase_solid, size: 16, color: context.ksc.accent500),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.serviceType,
                    style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (job.amountCharged != null)
                    Text(
                      CurrencyFormatter.formatShort(job.amountCharged!),
                      style: AppTextStyles.caption.copyWith(color: context.ksc.accent500),
                    ),
                ],
              ),
            ),
            Text(
              DateFormatter.relative(job.jobDate),
              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final customer;
  const _CustomerTile({required this.customer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.customerDetail(customer.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          children: [
            Icon(LineAwesomeIcons.user_solid, size: 16, color: context.ksc.neutral400),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.fullName,
                    style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    customer.phoneNumber,
                    style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                  ),
                ],
              ),
            ),
            Icon(LineAwesomeIcons.angle_right_solid, size: 16, color: context.ksc.neutral600),
          ],
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final note;
  const _NoteTile({required this.note});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.noteDetail(note.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          children: [
            Icon(LineAwesomeIcons.sticky_note, size: 16, color: context.ksc.neutral400),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (note.tags.isNotEmpty)
                    Text(
                      (note.tags as List).join(' · '),
                      style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(LineAwesomeIcons.angle_right_solid, size: 16, color: context.ksc.neutral600),
          ],
        ),
      ),
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────

class _SearchHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LineAwesomeIcons.search_solid, size: 56, color: context.ksc.primary700),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'SEARCH EVERYTHING',
              style: AppTextStyles.h3.copyWith(
                  color: context.ksc.neutral600, letterSpacing: 1.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Jobs, customers, and notes\nall in one place.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: context.ksc.neutral700),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LineAwesomeIcons.search_solid, size: 56, color: context.ksc.primary700),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'NO RESULTS',
              style: AppTextStyles.h3.copyWith(
                  color: context.ksc.neutral600, letterSpacing: 1.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Nothing found for "$query"',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: context.ksc.neutral700),
            ),
          ],
        ),
      ),
    );
  }
}
