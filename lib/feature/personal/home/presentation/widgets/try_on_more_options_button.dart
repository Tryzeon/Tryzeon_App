import 'dart:ui';
import 'package:flutter/material.dart';

class TryOnMoreOptionsButton extends StatelessWidget {
  const TryOnMoreOptionsButton({
    super.key,
    required this.currentTryonIndex,
    required this.customAvatarIndex,
    required this.onDownload,
    required this.onToggleAvatar,
    required this.onDelete,
  });

  final int currentTryonIndex;
  final int? customAvatarIndex;
  final VoidCallback onDownload;
  final VoidCallback onToggleAvatar;
  final VoidCallback onDelete;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
                child: IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (final context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.download_rounded),
                              title: const Text('下載照片'),
                              subtitle: const Text('儲存到相簿'),
                              onTap: () {
                                Navigator.pop(context);
                                onDownload();
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                customAvatarIndex == currentTryonIndex
                                    ? Icons.person_off_outlined
                                    : Icons.person_outline_rounded,
                              ),
                              title: Text(
                                customAvatarIndex == currentTryonIndex
                                    ? '取消我的形象'
                                    : '設為我的形象',
                              ),
                              subtitle: Text(
                                customAvatarIndex == currentTryonIndex
                                    ? '取消使用此照片作為試穿形象'
                                    : '使用此照片作為試穿形象',
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                onToggleAvatar();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete_outline_rounded),
                              title: const Text('刪除此試穿'),
                              subtitle: const Text('移除這張試穿照片'),
                              onTap: () {
                                Navigator.pop(context);
                                onDelete();
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurface),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
