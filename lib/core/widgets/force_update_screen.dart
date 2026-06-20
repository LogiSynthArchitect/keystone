import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/ks_colors.dart';
import '../theme/app_text_styles.dart';

class ForceUpdateScreen extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final String? apkUrl;
  final String? releaseNotes;

  const ForceUpdateScreen({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    this.apkUrl,
    this.releaseNotes,
  });

  Future<void> _download() async {
    if (apkUrl == null || apkUrl!.isEmpty) return;
    final uri = Uri.tryParse(apkUrl!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.ksc.primary900,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LineAwesomeIcons.exclamation_triangle_solid,
                    size: 64, color: context.ksc.accent500),
                const SizedBox(height: 24),
                Text('Update Available',
                    style: AppTextStyles.h1.copyWith(
                      color: context.ksc.white,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 12),
                Text(
                  'You are using version $currentVersion.\n'
                  'Please update to $latestVersion to continue.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: context.ksc.neutral400),
                ),
                if (releaseNotes != null && releaseNotes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.ksc.primary800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("What's new:",
                            style: AppTextStyles.caption.copyWith(
                              color: context.ksc.accent500,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 8),
                        Text(releaseNotes!,
                            style: AppTextStyles.caption.copyWith(color: context.ksc.neutral300)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _download,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.ksc.accent500,
                      foregroundColor: context.ksc.primary900,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text('UPDATE NOW',
                        style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
