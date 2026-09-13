import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'practice_models.dart';

class PracticeRepository {
  const PracticeRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<PracticeSessionModel>> getMySessions() async {
    final response = await _apiClient.get(
      '/api/practice-sessions',
      authenticated: true,
    );
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('La respuesta de la API es inválida.');
    }
    return decoded
        .whereType<Map>()
        .map(
          (session) =>
              PracticeSessionModel.fromJson(Map<String, dynamic>.from(session)),
        )
        .toList(growable: false);
  }

  Future<PracticeSessionModel> startSession({
    required String subjectId,
    int? questionCount,
  }) async {
    final body = <String, dynamic>{'subjectId': subjectId};
    if (questionCount != null) {
      body['questionCount'] = questionCount;
    }
    final response = await _apiClient.post(
      '/api/practice-sessions',
      authenticated: true,
      body: body,
    );
    _ensureSuccess(response);
    return PracticeSessionModel.fromJson(_decodeObject(response.body));
  }

  Future<AnswerResultModel> submitAnswer({
    required String sessionId,
    required String questionId,
    required String selectedOptionId,
  }) async {
    final response = await _apiClient.post(
      '/api/practice-sessions/$sessionId/answers',
      authenticated: true,
      body: {'questionId': questionId, 'selectedOptionId': selectedOptionId},
    );
    _ensureSuccess(response);
    return AnswerResultModel.fromJson(_decodeObject(response.body));
  }

  Future<PracticeSessionResultModel> finishSession(String sessionId) async {
    final response = await _apiClient.post(
      '/api/practice-sessions/$sessionId/finish',
      authenticated: true,
    );
    _ensureSuccess(response);
    return PracticeSessionResultModel.fromJson(_decodeObject(response.body));
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('La respuesta de la API es inválida.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  void _ensureSuccess(dynamic response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(response);
    }
  }
}
