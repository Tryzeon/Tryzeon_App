import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';
import '../../data/profile_service.dart';

class StoreProfileSettingsPage extends StatefulWidget {
  const StoreProfileSettingsPage({super.key});

  @override
  State<StoreProfileSettingsPage> createState() =>
      _StoreProfileSettingsPageState();
}

class _StoreProfileSettingsPageState extends State<StoreProfileSettingsPage> {
  File? _logoImage;
  StoreProfile? _storeProfile;
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController storeAddressController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile(forceRefresh: true);
  }

  Future<void> _loadProfile({final bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    final result = await StoreProfileService.getStoreProfile(
      forceRefresh: forceRefresh,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      setState(() {
        _storeProfile = result.data;
        storeNameController.text = result.data!.name;
        storeAddressController.text = result.data!.address;
      });
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage!,
        type: NotificationType.error,
      );
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    final result = await StoreProfileService.updateStoreProfile(
      name: storeNameController.text.trim(),
      address: storeAddressController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      Navigator.pop(context, true);
      TopNotification.show(
        context,
        message: '店家資訊已更新',
        type: NotificationType.success,
      );
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage!,
        type: NotificationType.error,
      );
    }
  }

  Future<void> _updateLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _logoImage = File(image.path);
      _isLoading = true;
    });

    final result = await StoreProfileService.uploadLogo(_logoImage!);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      TopNotification.show(
        context,
        message: '店家Logo已更新',
        type: NotificationType.success,
      );
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage!,
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(final BuildContext context) {
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
                        onPressed: () => Navigator.pop(context, false),
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
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
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
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
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
                                    onTap: _updateLogo,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            colorScheme.primary.withValues(
                                              alpha: 0.1,
                                            ),
                                            colorScheme.secondary.withValues(
                                              alpha: 0.1,
                                            ),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(60),
                                        border: Border.all(
                                          color: colorScheme.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      child: _logoImage != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(60),
                                              child: Image.file(
                                                _logoImage!,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : _storeProfile == null
                                          ? Icon(
                                              Icons.camera_alt_rounded,
                                              size: 50,
                                              color: colorScheme.primary,
                                            )
                                          : FutureBuilder(
                                              future: _storeProfile!.loadLogo(),
                                              builder: (final context, final snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return CircularProgressIndicator(
                                                    color: colorScheme.primary,
                                                  );
                                                }

                                                final result = snapshot.data;
                                                if (result == null ||
                                                    !result.isSuccess) {
                                                  return Icon(
                                                    Icons.camera_alt_rounded,
                                                    size: 50,
                                                    color: colorScheme.primary,
                                                  );
                                                }

                                                if (result.data != null) {
                                                  return ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          60,
                                                        ),
                                                    child: Image.file(
                                                      result.data!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            final context,
                                                            final error,
                                                            final stackTrace,
                                                          ) {
                                                            return Icon(
                                                              Icons
                                                                  .store_rounded,
                                                              size: 50,
                                                              color: colorScheme
                                                                  .primary,
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
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
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
                                  TextField(
                                    controller: storeNameController,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: '店家名稱',
                                      labelStyle: textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                            fontSize: 14,
                                          ),
                                      prefixIcon: Icon(
                                        Icons.store_rounded,
                                        color: colorScheme.primary,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.outline.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.outline.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor:
                                          colorScheme.surfaceContainerLow,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // 店家地址
                                  TextField(
                                    controller: storeAddressController,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: '店家地址',
                                      labelStyle: textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                            fontSize: 14,
                                          ),
                                      prefixIcon: Icon(
                                        Icons.location_on_rounded,
                                        color: colorScheme.primary,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.outline.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.outline.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor:
                                          colorScheme.surfaceContainerLow,
                                    ),
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
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _updateProfile,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Row(
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
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
