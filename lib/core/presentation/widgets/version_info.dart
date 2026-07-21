import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

/// The app version line shown at the foot of the settings and login screens.
/// Long-pressing it opens the Talker log viewer.
class VersionInfo extends HookWidget {
  const VersionInfo({super.key});

  @override
  Widget build(final BuildContext context) {
    final version = useMemoized(() async {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version} (${packageInfo.buildNumber})';
    });
    final snapshot = useFuture(version);

    return Center(
      child: GestureDetector(
        onLongPress: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (final context) => TalkerScreen(talker: AppLogger.talker),
            ),
          );
        },
        child: Text(
          'Version ${snapshot.data ?? '...'}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
