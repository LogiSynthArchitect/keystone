import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/ks_colors.dart';
import '../constants/app_enums.dart';

class SyncStatusIndicator extends StatelessWidget {
  final SyncStatus status;
  final double size;

  const SyncStatusIndicator({
    super.key,
    required this.status,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SyncStatus.synced:
        return Icon(LineAwesomeIcons.check_circle_solid, color: context.ksc.success500, size: size);
      case SyncStatus.pending:
        return Icon(LineAwesomeIcons.sync_solid, color: context.ksc.accent500, size: size);
      case SyncStatus.failed:
        return Icon(LineAwesomeIcons.exclamation_circle_solid, color: context.ksc.error500, size: size);
      case SyncStatus.deleted:
        return Icon(LineAwesomeIcons.trash_solid, color: context.ksc.neutral500, size: size);
    }
  }
}
