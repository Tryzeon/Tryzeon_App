import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';

import '../../data/profile_service.dart';

class PersonalProfileSettingsPage extends StatefulWidget {
  const PersonalProfileSettingsPage({super.key});

  @override
  State<PersonalProfileSettingsPage> createState() =>
      _PersonalProfileSettingsPageState();
}

class _PersonalProfileSettingsPageState
    extends State<PersonalProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _shoulderWidthController = TextEditingController();
  final _sleeveLengthController = TextEditingController();

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

    final result = await UserProfileService.getUserProfile(
      forceRefresh: forceRefresh,
    );

    if (result.isSuccess) {
      final profile = result.data!;
      _nameController.text = profile.name;
      _heightController.text = profile.height?.toString() ?? '';
      _weightController.text = profile.weight?.toString() ?? '';
      _chestController.text = profile.chest?.toString() ?? '';
      _waistController.text = profile.waist?.toString() ?? '';
      _hipsController.text = profile.hips?.toString() ?? '';
      _shoulderWidthController.text = profile.shoulderWidth?.toString() ?? '';
      _sleeveLengthController.text = profile.sleeveLength?.toString() ?? '';
    } else {
      if (mounted) {
        TopNotification.show(
          context,
          message: result.errorMessage ?? '載入個人資料失敗，請稍後再試',
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

    final result = await UserProfileService.updateUserProfile(
      name: _nameController.text,
      height: _heightController.text.isNotEmpty
          ? double.tryParse(_heightController.text)
          : null,
      weight: _weightController.text.isNotEmpty
          ? double.tryParse(_weightController.text)
          : null,
      chest: _chestController.text.isNotEmpty
          ? double.tryParse(_chestController.text)
          : null,
      waist: _waistController.text.isNotEmpty
          ? double.tryParse(_waistController.text)
          : null,
      hips: _hipsController.text.isNotEmpty
          ? double.tryParse(_hipsController.text)
          : null,
      shoulderWidth: _shoulderWidthController.text.isNotEmpty
          ? double.tryParse(_shoulderWidthController.text)
          : null,
      sleeveLength: _sleeveLengthController.text.isNotEmpty
          ? double.tryParse(_sleeveLengthController.text)
          : null,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (result.isSuccess) {
        Navigator.pop(context, true);
        TopNotification.show(
          context,
          message: '個人資料已更新',
          type: NotificationType.success,
        );
      } else {
        TopNotification.show(
          context,
          message: result.errorMessage ?? '更新失敗，請稍後再試',
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _shoulderWidthController.dispose();
    _sleeveLengthController.dispose();
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
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _heightController,
                                    label: '身高 (cm)',
                                    icon: Icons.height_rounded,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _weightController,
                                    label: '體重 (kg)',
                                    icon: Icons.monitor_weight_outlined,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _chestController,
                                    label: '胸圍 (cm)',
                                    icon: Icons.accessibility_rounded,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _waistController,
                                    label: '腰圍 (cm)',
                                    icon: Icons.accessibility_rounded,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _hipsController,
                                    label: '臀圍 (cm)',
                                    icon: Icons.accessibility_rounded,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _shoulderWidthController,
                                    label: '肩寬 (cm)',
                                    icon: Icons.accessibility_rounded,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _sleeveLengthController,
                              label: '袖長 (cm)',
                              icon: Icons.accessibility_rounded,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'),
                                ),
                              ],
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
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.secondary,
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isLoading
                                ? []
                                : [
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.save_rounded,
                                            color: colorScheme.onPrimary,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '儲存',
                                            style: textTheme.titleMedium
                                                ?.copyWith(
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
