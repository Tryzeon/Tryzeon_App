import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../domain/entities/analytics_event.dart';
import '../models/analytics_event_model.dart';

import 'analytics_mappr.auto_mappr.dart';

@AutoMappr([
  MapType<AnalyticsEvent, AnalyticsEventModel>(
    fields: [Field('eventType', custom: AnalyticsMappr.eventTypeToString)],
  ),
])
class AnalyticsMappr extends $AnalyticsMappr {
  const AnalyticsMappr();

  static String eventTypeToString(final AnalyticsEvent event) => event.eventType.value;
}
