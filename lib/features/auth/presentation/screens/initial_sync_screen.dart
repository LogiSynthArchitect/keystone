import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:keystone/core/providers/supabase_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../customer_history/presentation/providers/customer_providers.dart';
import '../../../job_logging/presentation/providers/job_providers.dart';
import '../../../knowledge_base/presentation/providers/notes_providers.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';

class InitialSyncScreen extends ConsumerStatefulWidget {
  const InitialSyncScreen({super.key});

  @override
  ConsumerState<InitialSyncScreen> createState() => _InitialSyncScreenState();
}

class _InitialSyncScreenState extends ConsumerState<InitialSyncScreen> {
  String _status = 'Preparing...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _doInitialSync());
  }

  Future<void> _doInitialSync() async {
    final supabase = ref.read(supabaseClientProvider);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) context.go(RouteNames.dashboard);
      return;
    }

    try {
      setState(() => _status = 'Syncing customers...');
      final customerRepo = ref.read(customerRepositoryProvider);
      var offset = 0;
      const pageSize = 500;
      while (true) {
        final page = await customerRepo.getCustomers(limit: pageSize, offset: offset);
        if (page.length < pageSize) break;
        offset += pageSize;
      }

      setState(() => _status = 'Syncing jobs...');
      final jobRepo = ref.read(jobRepositoryProvider);
      offset = 0;
      while (true) {
        final page = await jobRepo.getJobs(limit: pageSize, offset: offset);
        if (page.length < pageSize) break;
        offset += pageSize;
      }

      setState(() => _status = 'Syncing notes...');
      final noteRepo = ref.read(knowledgeNoteRepositoryProvider);
      offset = 0;
      while (true) {
        final page = await noteRepo.getNotes(limit: pageSize, offset: offset);
        if (page.length < pageSize) break;
        offset += pageSize;
      }

      setState(() => _status = 'Syncing inventory...');
      await ref.read(inventoryRepositoryProvider).getItems(userId);
    } catch (e) {
      debugPrint('[KS:SYNC] Initial sync error: $e');
    }

    final authBox = Hive.box('auth');
    await authBox.put('initial_sync_complete', true);

    if (mounted) context.go(RouteNames.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.ksc.primary900,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LineAwesomeIcons.cloud_download_alt_solid,
                  size: 56,
                ).animate().fadeIn().scaleY(begin: 0, end: 1),
                const SizedBox(height: 32),
                Text(
                  'SETTING UP YOUR ACCOUNT',
                  style: AppTextStyles.caption.copyWith(
                    color: context.ksc.accent500,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w700,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 8),
                Text(
                  'FIRST TIME SYNC',
                  style: AppTextStyles.h1.copyWith(
                    color: context.ksc.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                Text(
                  'Downloading your data.\nThis should only take a moment.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: context.ksc.neutral400,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 48),
                const CircularProgressIndicator(
                  strokeWidth: 3,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 24),
                Text(
                  _status,
                  style: AppTextStyles.caption.copyWith(
                    color: context.ksc.neutral500,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
