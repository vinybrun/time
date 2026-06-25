import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../screens/settings_screen.dart';
import '../theme.dart';

const String kRepoUrl = 'https://github.com/vinybrun/time';
const String kApkUrl = '/app/time.apk';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.line),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined, size: 20),
            label: Text(l.openSettings),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => launchUrl(Uri.parse(kApkUrl),
                  mode: LaunchMode.externalApplication),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.android,
                      size: 16, color: AppColors.accentStrong),
                  const SizedBox(width: 6),
                  Text(l.downloadApk,
                      style: const TextStyle(
                          color: AppColors.accentStrong,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          InkWell(
            onTap: () => launchUrl(Uri.parse(kRepoUrl),
                mode: LaunchMode.externalApplication),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l.madeBy,
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 13)),
                const SizedBox(width: 6),
                const Icon(Icons.open_in_new,
                    size: 13, color: AppColors.inkFaint),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
