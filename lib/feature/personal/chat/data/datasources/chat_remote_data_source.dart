import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/config/env.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/chat/data/chat_wire.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_stream_event.dart';

class ChatRemoteDataSource {
  ChatRemoteDataSource(this._supabase, [final Dio? dio]) : _dio = dio ?? Dio();

  final SupabaseClient _supabase;
  final Dio _dio;

  /// Rate-limit and other run failures arrive in-stream as an error event
  /// (handled in [parseStreamLine]); a non-200 status is auth/bad-request only.
  Stream<ChatStreamEvent> sendMessageStream(final List<ChatMessage> history) async* {
    final url = '${Env.supabaseUrl}/functions/v1/${AppConstants.functionChat}';
    final accessToken = _supabase.auth.currentSession?.accessToken ?? '';
    final body = jsonEncode({
      'messages': [for (final m in history) messageToWire(m)],
    });

    final response = await _dio.post<ResponseBody>(
      url,
      data: body,
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'apikey': Env.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        validateStatus: (final _) => true,
      ),
    );

    if ((response.statusCode ?? 0) != 200) {
      yield const ChatStreamEvent.failed(ServerFailure());
      return;
    }

    // ResponseBody.stream is Stream<Uint8List>; Uint8List implements List<int>
    // so .cast<List<int>>() is a sound covariant cast that satisfies utf8.decoder's
    // StreamTransformer<List<int>, String> input type.
    final lines = response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      final event = parseStreamLine(line);
      if (event != null) yield event;
    }
  }
}
