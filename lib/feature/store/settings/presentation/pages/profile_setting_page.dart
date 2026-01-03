import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/store/settings/data/profile_service.dart';
import 'package:tryzeon/shared/utils/validators.dart';
import 'package:tryzeon/shared/widgets/app_query_builder.dart';
import 'package:tryzeon/shared/widgets/image_picker_helper.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';
import 'package:typed_result/typed_result.dart';

class StoreProfileSettingsPage extends HookConsumerWidget {
  const StoreProfileSettingsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.05),
                colorScheme.surface,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 自訂 AppBar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '帳號設定',
                            style: textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '管理您的店家資訊',
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 內容
              Expanded(
                child: AppQueryBuilder<StoreProfile?>(
                  query: StoreProfileService.storeProfileQuery(),
                  builder: (final context, final profile) {
                    if (profile == null) {
                      return const Center(child: Text('無法載入店家資料'));
                    }
                    return _StoreProfileForm(profile: profile);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreProfileForm extends HookConsumerWidget {
  const _StoreProfileForm({required this.profile});

  final StoreProfile profile;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final newLogoImage = useState<File?>(null);
    final isLoading = useState(false);

    // Initialize controllers with profile data
    final storeNameController = useTextEditingController(text: profile.name);
    final storeAddressController = useTextEditingController(text: profile.address);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> updateProfile() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;

      final targetProfile = profile.copyWith(
        name: storeNameController.text.trim(),
        address: storeAddressController.text.trim(),
      );

      final result = await StoreProfileService.updateStoreProfile(
        original: profile,
        target: targetProfile,
        logo: newLogoImage.value,
      );

      if (!context.mounted) return;

      isLoading.value = false;

      if (result.isSuccess) {
        Navigator.pop(context);
        TopNotification.show(context, message: '店家資訊已更新', type: NotificationType.success);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!,
          type: NotificationType.error,
        );
      }
    }

    Future<void> updateLogo() async {
      final File? image = await ImagePickerHelper.pickImage(context);
      if (image == null) return;

      newLogoImage.value = image;
    }

    Widget buildTextField({
      required final TextEditingController controller,
      required final String label,
      required final IconData icon,
      final String? Function(String?)? validator,
    }) {
      return TextFormField(
        controller: controller,
        style: textTheme.bodyMedium?.copyWith(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
        ),
        validator: validator,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo卡片
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '店家 Logo',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: updateLogo,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.1),
                            colorScheme.secondary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: newLogoImage.value != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.file(newLogoImage.value!, fit: BoxFit.cover),
                            )
                          : FutureBuilder(
                              future: profile.loadLogo(),
                              builder: (final context, final snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return CircularProgressIndicator(
                                    color: colorScheme.primary,
                                  );
                                }

                                final result = snapshot.data!;
                                if (result.isFailure) {
                                  // Only show notification, don't setState
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (context.mounted) {
                                      TopNotification.show(
                                        context,
                                        message: result.getError()!,
                                        type: NotificationType.error,
                                      );
                                    }
                                  });
                                }

                                if (result.get() != null) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: Image.file(
                                      result.get()!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (final context, final error, final stackTrace) {
                                            return Icon(
                                              Icons.error_rounded,
                                              size: 50,
                                              color: colorScheme.primary,
                                            );
                                          },
                                    ),
                                  );
                                }

                                return Icon(
                                  Icons.camera_alt_rounded,
                                  size: 50,
                                  color: colorScheme.primary,
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '點擊上傳店家 Logo',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 資訊卡片
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '店家資訊',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 店家名稱
                  buildTextField(
                    controller: storeNameController,
                    label: '店家名稱',
                    icon: Icons.store_rounded,
                    validator: AppValidators.validateStoreName,
                  ),

                  const SizedBox(height: 20),

                  // 店家地址
                  buildTextField(
                    controller: storeAddressController,
                    label: '店家地址',
                    icon: Icons.location_on_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 儲存按鈕
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: isLoading.value
                    ? null
                    : LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                color: isLoading.value ? colorScheme.surfaceContainerHighest : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isLoading.value
                    ? null
                    : [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading.value ? null : updateProfile,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: isLoading.value
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save_rounded,
                                color: colorScheme.onPrimary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '儲存',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
