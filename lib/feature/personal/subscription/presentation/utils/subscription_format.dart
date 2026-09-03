import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';

String planName(final AppSubscriptionTier tier) => switch (tier) {
  AppSubscriptionTier.free => 'Free',
  AppSubscriptionTier.pro => 'Pro',
  AppSubscriptionTier.max => 'Max',
};

String formatUsage({required final int? used, required final int? limit}) {
  if (limit == 0) return '未開通';
  final usedText = used?.toString() ?? '—';
  if (limit == null) return '$usedText / —';
  return '$usedText / $limit';
}

String formatBenefit({required final bool? value}) {
  if (value == null) return '—';
  return value ? '✓' : '✗';
}

String formatRenewalLine(final AppSubscriptionEntitlement entitlement) {
  if (entitlement.tier == AppSubscriptionTier.free) {
    return '免費試用方案';
  }

  final raw = entitlement.expirationDate;
  if (raw == null || raw.isEmpty) {
    return '訂閱中';
  }

  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return '訂閱中';
  }

  final y = parsed.year.toString().padLeft(4, '0');
  final m = parsed.month.toString().padLeft(2, '0');
  final d = parsed.day.toString().padLeft(2, '0');
  return '$y/$m/$d 續訂';
}
