import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/crop_options.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

class StoreProfileSettingsPage extends HookConsumerWidget {
  const StoreProfileSettingsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final profileAsync = ref.watch(storeProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('店家資料')),
      body: SafeArea(
        top: false,
        child: profileAsync.when(
          data: (final profile) {
            if (profile == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _StoreProfileForm(profile: profile);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (final error, final stack) => ErrorView(
            message: error.displayMessage(context),
            onRetry: () => ref.invalidate(storeProfileProvider),
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
    final isLoading = ref.watch(storeProfileEditProvider).isLoading;

    final storeNameController = useTextEditingController(text: profile.name);
    final storeAddressController = useTextEditingController(text: profile.address);

    final storeName = useValueListenable(storeNameController).text;
    final storeAddress = useValueListenable(storeAddressController).text;
    final newLogo = newLogoImage.value;
    final selectedChannels = useState<Set<StoreChannel>>(profile.channels);

    final channelsChanged = !setEquals(selectedChannels.value, profile.channels);

    String initialContact(final OrderContactType type) {
      for (final c in profile.orderContacts) {
        if (c.type == type) return c.value;
      }
      return '';
    }

    final lineController = useTextEditingController(
      text: initialContact(OrderContactType.line),
    );
    final facebookController = useTextEditingController(
      text: initialContact(OrderContactType.facebook),
    );
    final instagramController = useTextEditingController(
      text: initialContact(OrderContactType.instagram),
    );

    final lineValue = useValueListenable(lineController).text;
    final facebookValue = useValueListenable(facebookController).text;
    final instagramValue = useValueListenable(instagramController).text;

    List<StoreOrderContact> buildOrderContacts() {
      final list = <StoreOrderContact>[];
      void add(final OrderContactType type, final String raw) {
        final v = raw.trim();
        if (v.isNotEmpty) list.add(StoreOrderContact(type: type, value: v));
      }

      add(OrderContactType.line, lineValue);
      add(OrderContactType.facebook, facebookValue);
      add(OrderContactType.instagram, instagramValue);
      return list;
    }

    final contactsChanged = !listEquals(buildOrderContacts(), profile.orderContacts);

    final hasChanges =
        storeName.trim() != profile.name ||
        storeAddress.trim() != (profile.address ?? '') ||
        newLogo != null ||
        channelsChanged ||
        contactsChanged;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    Future<void> updateProfile() async {
      if (!formKey.currentState!.validate()) return;

      final trimmedAddress = storeAddressController.text.trim();
      final result = await ref
          .read(storeProfileEditProvider.notifier)
          .save(
            name: storeNameController.text.trim(),
            address: trimmedAddress.isEmpty ? null : trimmedAddress,
            channels: selectedChannels.value,
            orderContacts: buildOrderContacts(),
            logoFile: newLogoImage.value,
          );

      if (!context.mounted) return;

      switch (result) {
        case Ok(value: (:final addressUnresolved)):
          if (addressUnresolved) {
            TopNotification.show(context, message: '地址無法定位，將不會出現在附近排序');
          }
          context.pop();
        case Err(:final error):
          TopNotification.show(context, message: error.displayMessage(context));
      }
    }

    Future<void> updateLogo() async {
      final File? image = await ImagePickerHelper.pickImage(
        context,
        crop: const FreeCrop(
          presets: [CropAspectRatioPreset.square],
          style: CropStyle.circle,
        ),
      );
      if (image == null) return;

      newLogoImage.value = image;
    }

    Widget buildLogoPreview() {
      const size = 96.0;

      if (newLogoImage.value != null) {
        return ClipOval(
          child: Image.file(
            newLogoImage.value!,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      }

      final logoUrl = profile.logoUrl;
      if (logoUrl == null || logoUrl.isEmpty) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surfaceContainerHighest,
          ),
          child: Icon(
            Icons.storefront_outlined,
            size: AppSpacing.xl,
            color: colorScheme.onSurfaceVariant,
          ),
        );
      }

      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (final context, final url) => Container(
            width: size,
            height: size,
            color: colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: AppStroke.regular),
              ),
            ),
          ),
          errorWidget: (final context, final url, final error) => Container(
            width: size,
            height: size,
            color: colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.storefront_outlined,
              size: AppSpacing.xl,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Column(
                children: [
                  GestureDetector(onTap: updateLogo, child: buildLogoPreview()),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '點擊更換店家 Logo',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: storeNameController,
              textInputAction: TextInputAction.next,
              validator: AppValidators.validateStoreName,
              decoration: const InputDecoration(labelText: '店家名稱'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: storeAddressController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: '店家地址'),
            ),
            const SizedBox(height: AppSpacing.lg),
            FormField<Set<StoreChannel>>(
              initialValue: selectedChannels.value,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (final value) =>
                  AppValidators.validateNonEmpty(value, message: '請至少選擇一項店家類型'),
              builder: (final field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '店家類型',
                      style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: StoreChannel.values.map((final channel) {
                        final isSelected = selectedChannels.value.contains(channel);
                        return FilterChip(
                          label: Text(channel.label),
                          selected: isSelected,
                          onSelected: (final v) {
                            final next = {...selectedChannels.value};
                            if (v) {
                              next.add(channel);
                            } else {
                              next.remove(channel);
                            }
                            selectedChannels.value = next;
                            field.didChange(next);
                          },
                        );
                      }).toList(),
                    ),
                    if (field.hasError) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        field.errorText!,
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '訂購聯絡方式',
              style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '沒有線上商店時，顧客可透過這些管道私訊下單。',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: lineController,
              textInputAction: TextInputAction.next,
              validator: AppValidators.validateLineId,
              decoration: const InputDecoration(
                labelText: 'LINE ID',
                hintText: '官方帳號 @tryzeon，個人帳號 myshop',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: facebookController,
              textInputAction: TextInputAction.next,
              validator: AppValidators.validateSocialHandle,
              decoration: const InputDecoration(
                labelText: 'Facebook 粉專用戶名',
                hintText: 'MyShop',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: instagramController,
              textInputAction: TextInputAction.done,
              validator: AppValidators.validateSocialHandle,
              decoration: const InputDecoration(
                labelText: 'Instagram 帳號',
                hintText: 'my.shop',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading || !hasChanges ? null : updateProfile,
                child: isLoading
                    ? SizedBox(
                        width: AppSpacing.mdLg,
                        height: AppSpacing.mdLg,
                        child: CircularProgressIndicator(
                          color: colorScheme.onPrimary,
                          strokeWidth: AppStroke.regular,
                        ),
                      )
                    : const Text('儲存'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
