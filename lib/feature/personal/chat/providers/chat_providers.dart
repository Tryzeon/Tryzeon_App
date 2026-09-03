import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/chat/data/datasources/chat_remote_data_source.dart';
import 'package:tryzeon/feature/personal/chat/data/repositories/chat_repository_impl.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_stream_event.dart';
import 'package:tryzeon/feature/personal/chat/domain/repositories/chat_repository.dart';
import 'package:tryzeon/feature/personal/chat/domain/usecases/send_chat_message.dart';
import 'package:tryzeon/feature/personal/usage/providers/daily_usage_providers.dart';

part 'chat_providers.g.dart';

@riverpod
ChatRemoteDataSource chatRemoteDataSource(final Ref ref) {
  return ChatRemoteDataSource(Supabase.instance.client);
}

@riverpod
ChatRepository chatRepository(final Ref ref) {
  final remoteDataSource = ref.watch(chatRemoteDataSourceProvider);
  return ChatRepositoryImpl(remoteDataSource: remoteDataSource);
}

@riverpod
SendChatMessage sendChatMessageUseCase(final Ref ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return SendChatMessage(repository);
}

/// UI calls this instead of [sendChatMessageUseCaseProvider] directly, so every
/// chat entry point inherits the usage-cache sync.
///
/// `keepAlive: true` because the orchestrator is invoked via `ref.read` (no
/// long-lived listener). Without it, autoDispose may tear the provider down
/// mid-await, causing "Cannot use Ref after dispose" when the async body
/// resumes.
@Riverpod(keepAlive: true)
class ChatAction extends _$ChatAction {
  @override
  void build() {}

  Stream<ChatStreamEvent> execute(final List<ChatMessage> history) async* {
    final useCase = ref.read(sendChatMessageUseCaseProvider);
    final usageCache = ref.read(dailyUsageTodayProvider.notifier);
    await for (final event in useCase(history)) {
      switch (event) {
        case ChatReplied(:final usage):
          usageCache.syncFromSnapshot(usage);
        case ChatFailed(:final failure):
          usageCache.syncFromFailure(failure);
        case ChatToolStarted():
        case ChatToolFinished():
          break;
      }
      yield event;
    }
  }
}
