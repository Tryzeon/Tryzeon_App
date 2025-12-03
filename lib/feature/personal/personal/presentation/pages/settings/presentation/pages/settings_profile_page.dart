import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tryzeon/shared/models/body_measurements.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';

import '../../data/profile_service.dart';

class PersonalProfileSettingsPage extends StatefulWidget {
  const PersonalProfileSettingsPage({super.key});

  @override
  State<PersonalProfileSettingsPage> createState() => _PersonalProfileSettingsPageState();
}

class _PersonalProfileSettingsPageState extends State<PersonalProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _measurementControllers = <MeasurementType, TextEditingController>{};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 初始化所有身型數據的控制器
    for (final type in MeasurementType.values) {
      _measurementControllers[type] = TextEditingController();
    }
    _loadProfile(forceRefresh: true);
  }

  Future<void> _loadProfile({final bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    final result = await UserProfileService.getUserProfile(forceRefresh: forceRefresh);

    if (result.isSuccess) {
      final profile = result.data!;
      _nameController.text = profile.name;

      // 使用 Enum 遍歷更新數值
      for (final type in MeasurementType.values) {
        _measurementControllers[type]?.text =
            profile.measurements[type]?.toString() ?? '';
      }
    } else {
      if (mounted) {
        TopNotification.show(
          context,
          message: result.errorMessage!,
          type: NotificationType.error,
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // 收集所有控制器的值並轉換為 Map
    final measurementsJson = <String, dynamic>{};
    for (final entry in _measurementControllers.entries) {
      if (entry.value.text.isNotEmpty) {
        measurementsJson[entry.key.key] = double.tryParse(entry.value.text);
      }
    }

    final result = await UserProfileService.updateUserProfile(
      name: _nameController.text,
      measurements: BodyMeasurements.fromJson(measurementsJson),
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (result.isSuccess) {
        Navigator.pop(context, true);
        TopNotification.show(context, message: '個人資料已更新', type: NotificationType.success);
      } else {
        TopNotification.show(
          context,
          message: result.errorMessage!,
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _measurementControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
                          Text('編輯個人資料', style: textTheme.headlineMedium),
                          Text('更新您的個人資訊', style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 表單內容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // 基本資料卡片
                        _buildSectionCard(
                          context: context,
                          icon: Icons.person_outline_rounded,
                          title: '基本資料',
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: '姓名',
                              icon: Icons.person_outline_rounded,
                              validator: (final value) {
                                if (value == null || value.isEmpty) {
                                  return '請輸入姓名';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 身體測量卡片
                        _buildSectionCard(
                          context: context,
                          icon: Icons.straighten_rounded,
                          title: '身型資料',
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 16,
                              children: MeasurementType.values.map((final type) {
                                return SizedBox(
                                  // 使用 LayoutBuilder 或固定寬度來實現類似 Grid 的效果，
                                  // 這裡簡單地除以 2 減去間距的一半，讓它一行兩個
                                  width:
                                      (MediaQuery.of(context).size.width - 48 - 40 - 12) /
                                      2,
                                  // 48(page padding) + 40(card padding) + 12(spacing)
                                  child: _buildTextField(
                                    controller: _measurementControllers[type]!,
                                    label: type.label,
                                    icon: type.icon,
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // 儲存按鈕
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? LinearGradient(
                                    colors: [
                                      colorScheme.outline,
                                      colorScheme.outlineVariant,
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [colorScheme.primary, colorScheme.secondary],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isLoading
                                ? []
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
                              onTap: _isLoading ? null : _updateProfile,
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: _isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: colorScheme.onPrimary,
                                          strokeWidth: 2.5,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required final BuildContext context,
    required final IconData icon,
    required final String title,
    required final List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
          // 圖示標題
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.1),
                      colorScheme.secondary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Text(title, style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required final TextEditingController controller,
    required final String label,
    required final IconData icon,
    final TextInputType? keyboardType,
    final List<TextInputFormatter>? inputFormatters,
    final String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: textTheme.bodyMedium,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
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
}
