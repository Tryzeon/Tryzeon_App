import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';

class AppQueryBuilder<T> extends HookConsumerWidget {
  const AppQueryBuilder({
    super.key,
    required this.query,
    required this.builder,
    this.loader,
    this.isCompact = false,
  });

  /// The query to listen to.
  final Query<T> query;

  /// The builder function that is called when the query has data.
  final Widget Function(BuildContext context, T data) builder;

  /// Optional loader widget to show when the query is loading for the first time.
  final Widget? loader;

  /// Whether to use a compact version of the error view.
  final bool isCompact;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // ignore: dynamic_neighbor_all_around
    return QueryBuilder<QueryState<T>>(
      query: query,
      builder: (final context, final state) {
        // Use dynamic to avoid type mismatch issues with package versions
        final dynamic s = state;

        // Side Effect: Show Toast on Error
        if (s.error != null) {
          SchedulerBinding.instance.addPostFrameCallback((final _) {
            // Check if context is still valid before showing notification
            if (context.mounted) {
              TopNotification.show(
                context,
                message: s.error.toString(),
                type: NotificationType.error,
              );
            }
          });
        }

        // Handle success state (Prioritize cached data)
        final data = s.data as T?;
        if (data != null) {
          return builder(context, data);
        }

        // Handle loading state
        if (s is QueryLoading || s is QueryInitial) {
          return loader ??
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
        }

        // Handle error state
        return ErrorView(onRetry: query.refetch, isCompact: isCompact);
      },
    );
  }
}
