import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';
import '../../data/profile_service.dart';

class StoreAccountSettingsPage extends StatefulWidget {
  const StoreAccountSettingsPage({super.key});

  @override
  State<StoreAccountSettingsPage> createState() => _StoreAccountSettingsPageState();
}

class _StoreAccountSettingsPageState extends State<StoreAccountSettingsPage> {
  File? _logoImage;
  bool isLoading = false;
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController storeAddressController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    setState(() => isLoading = true);

    final result = await StoreProfileService.getStoreProfile();
    if (result.success) {
      setState(() {
        storeNameController.text = result.profile!.storeName;
        storeAddressController.text = result.profile!.address;
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> _saveChanges() async {
    setState(() => isLoading = true);

    final result = await StoreProfileService.updateStoreProfile(
      storeName: storeNameController.text.trim(),
      address: storeAddressController.text.trim(),
    );

    setState(() => isLoading = false);

    if (result.success) {
      if (mounted) {
        Navigator.of(context).pop();
        TopNotification.show(
          context,
          message: '店家資訊已更新',
          type: NotificationType.success,
        );
      }
    } else {
      if (mounted) {
        TopNotification.show(
          context,
          message: result.errorMessage ?? '更新失敗，請稍後再試',
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _logoImage = File(image.path);
      });
      
      // 上傳圖片
      await _uploadLogo();
    }
  }

  Future<void> _uploadLogo() async {
    if (_logoImage == null) return;

    setState(() => isLoading = true);

    try {
      // 上傳 logo 到 storage（會自動保存到本地）
      await StoreProfileService.uploadLogo(_logoImage!);

      if (mounted) {
        TopNotification.show(
          context,
          message: '店家Logo已更新',
          type: NotificationType.success,
        );
        // 重新載入頁面以更新 Logo
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        TopNotification.show(
          context,
          message: '上傳失敗，請稍後再試',
          type: NotificationType.error,
        );
      }
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Color.alphaBlend(
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                Theme.of(context).colorScheme.surface,
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
                  color: Colors.white,
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
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '帳號設定',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '管理您的店家資訊',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
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
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
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
                                color: Colors.white,
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
                                  const Text(
                                    '店家 Logo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(60),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: _logoImage != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(60),
                                              child: Image.file(
                                                _logoImage!,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : FutureBuilder<File?>(
                                              future: StoreProfileService.getLogo(),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return CircularProgressIndicator(
                                                    color: Theme.of(context).colorScheme.primary,
                                                  );
                                                }
                                                if (snapshot.hasData && snapshot.data != null) {
                                                  return ClipRRect(
                                                    borderRadius: BorderRadius.circular(60),
                                                    child: Image.file(
                                                      snapshot.data!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Icon(
                                                          Icons.store_rounded,
                                                          size: 50,
                                                          color: Theme.of(context).colorScheme.primary,
                                                        );
                                                      },
                                                    ),
                                                  );
                                                }
                                                return Icon(
                                                  Icons.camera_alt_rounded,
                                                  size: 50,
                                                  color: Theme.of(context).colorScheme.primary,
                                                );
                                              },
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '點擊上傳店家 Logo',
                                    style: TextStyle(
                                      color: Colors.grey[600],
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
                                color: Colors.white,
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
                                  const Text(
                                    '店家資訊',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // 店家名稱
                                  TextField(
                                    controller: storeNameController,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: '店家名稱',
                                      labelStyle: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.store_rounded,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // 店家地址
                                  TextField(
                                    controller: storeAddressController,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: '店家地址',
                                      labelStyle: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.location_on_rounded,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
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
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _saveChanges,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.save_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '儲存',
                                        style: TextStyle(
                                          color: Colors.white,
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