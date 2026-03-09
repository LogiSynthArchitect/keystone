import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../providers/customer_providers.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  CustomerEntity? _findCustomer(CustomerListState state) {
    try { return state.customers.firstWhere((c) => c.id == customerId); }
    catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerListProvider);
    final customer = _findCustomer(state);

    if (customer == null) {
      return const Scaffold(
        appBar: KsAppBar(title: "Customer", showBack: true),
        body: Center(child: Text("Customer not found.")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.neutral050,
      appBar: KsAppBar(title: customer.fullName, showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + name header
            Center(
              child: Column(children: [
                const SizedBox(height: AppSpacing.lg),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary100,
                  child: Text(
                    customer.fullName[0].toUpperCase(),
                    style: AppTextStyles.h1.copyWith(color: AppColors.primary700),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(customer.fullName, style: AppTextStyles.h2),
                if (customer.isRepeatCustomer) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.primary050, borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
                    child: Text("Repeat customer", style: AppTextStyles.caption.copyWith(color: AppColors.primary700)),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),

            // Contact info card
            _SectionCard(children: [
              _InfoRow(icon: Icons.phone_outlined, label: customer.phoneNumber),
              if (customer.location != null) _InfoRow(icon: Icons.location_on_outlined, label: customer.location!),
              if (customer.hasNotes) _InfoRow(icon: Icons.notes_outlined, label: customer.notes!),
            ]),

            const SizedBox(height: AppSpacing.lg),

            // Stats row
            Row(children: [
              Expanded(child: _StatCard(value: "${customer.totalJobs}", label: "Total jobs")),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _StatCard(
                value: customer.lastJobAt != null ? DateFormatter.relative(customer.lastJobAt!) : "—",
                label: "Last job",
              )),
            ]),

            const SizedBox(height: AppSpacing.xl),

            // WhatsApp button
            GestureDetector(
              onTap: () {
                final phone = customer.phoneNumber.replaceAll('+', '');
                final url = Uri.parse("https://wa.me/$phone");
                launchUrl(url, mode: LaunchMode.externalApplication);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.chat, size: 20, color: Colors.white),
                  const SizedBox(width: AppSpacing.sm),
                  Text("Message on WhatsApp", style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                ]),
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.neutral400),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.neutral700))),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(children: [
        Text(value, style: AppTextStyles.h2.copyWith(color: AppColors.primary700)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.neutral500)),
      ]),
    );
  }
}
