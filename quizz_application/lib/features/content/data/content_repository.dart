import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'content_models.dart';

class ContentRepository {
  const ContentRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<SubjectModel>> getSubjects() async {
    final response = await _apiClient.get('/api/subjects', authenticated: true);
    _ensureSuccess(response);
    return _decodeList(response.body, SubjectModel.fromJson);
  }

  Future<SubjectModel> createSubject({
    required String name,
    String? description,
  }) async {
    final response = await _apiClient.post(
      '/api/subjects',
      authenticated: true,
      body: {'name': name, 'description': _nullIfBlank(description)},
    );
    _ensureSuccess(response);
    return SubjectModel.fromJson(_decodeObject(response.body));
  }

  Future<void> updateSubject(
    String id, {
    required String name,
    String? description,
  }) async {
    final response = await _apiClient.put(
      '/api/subjects/$id',
      authenticated: true,
      body: {'name': name, 'description': _nullIfBlank(description)},
    );
    _ensureSuccess(response);
  }

  Future<void> deleteSubject(String id) async {
    final response = await _apiClient.delete(
      '/api/subjects/$id',
      authenticated: true,
    );
    _ensureSuccess(response);
  }

  Future<List<SchoolModel>> getSchools() async {
    final response = await _apiClient.get('/api/schools', authenticated: true);
    _ensureSuccess(response);
    return _decodeList(response.body, SchoolModel.fromJson);
  }

  Future<SchoolModel> createSchool({required String name, String? city}) async {
    final response = await _apiClient.post(
      '/api/schools',
      authenticated: true,
      body: {'name': name, 'city': _nullIfBlank(city)},
    );
    _ensureSuccess(response);
    return SchoolModel.fromJson(_decodeObject(response.body));
  }

  Future<void> updateSchool(
    String id, {
    required String name,
    String? city,
  }) async {
    final response = await _apiClient.put(
      '/api/schools/$id',
      authenticated: true,
      body: {'name': name, 'city': _nullIfBlank(city)},
    );
    _ensureSuccess(response);
  }

  Future<void> deleteSchool(String id) async {
    final response = await _apiClient.delete(
      '/api/schools/$id',
      authenticated: true,
    );
    _ensureSuccess(response);
  }

  Future<List<QuestionModel>> getQuestions({String? subjectId}) async {
    final query = subjectId == null || subjectId.isEmpty
        ? ''
        : '?subjectId=${Uri.encodeQueryComponent(subjectId)}';
    final response = await _apiClient.get(
      '/api/questions$query',
      authenticated: true,
    );
    _ensureSuccess(response);
    return _decodeList(response.body, QuestionModel.fromJson);
  }

  Future<QuestionModel> createQuestion(QuestionDraft draft) async {
    final response = await _apiClient.post(
      '/api/questions',
      authenticated: true,
      body: draft.toJson(),
    );
    _ensureSuccess(response);
    return QuestionModel.fromJson(_decodeObject(response.body));
  }

  Future<void> updateQuestion(String id, QuestionDraft draft) async {
    final response = await _apiClient.put(
      '/api/questions/$id',
      authenticated: true,
      body: draft.toJson(),
    );
    _ensureSuccess(response);
  }

  Future<void> deleteQuestion(String id) async {
    final response = await _apiClient.delete(
      '/api/questions/$id',
      authenticated: true,
    );
    _ensureSuccess(response);
  }

  List<T> _decodeList<T>(
    String body,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw const FormatException('La respuesta de la API es inválida.');
    }

    return decoded
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
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

  String? _nullIfBlank(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
