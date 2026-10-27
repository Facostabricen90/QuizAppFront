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

  Future<void> updateSubject(String id,
      {required String name, String? description}) async {
    final response = await _apiClient.put(
      '/api/subjects/$id',
      authenticated: true,
      body: {'name': name, 'description': _nullIfBlank(description)},
    );
    _ensureSuccess(response);
  }

  Future<void> deleteSubject(String id) async {
    final response = await _apiClient.delete('/api/subjects/$id',
        authenticated: true);
    _ensureSuccess(response);
  }

  Future<List<SchoolModel>> getSchools() async {
    final response =
        await _apiClient.get('/api/institutions', authenticated: true);
    _ensureSuccess(response);
    return _decodeList(response.body, SchoolModel.fromJson);
  }

  Future<SchoolModel> createSchool({required String name, String? city}) async {
    final response = await _apiClient.post(
      '/api/institutions',
      authenticated: true,
      body: {'name': name, 'city': _nullIfBlank(city)},
    );
    _ensureSuccess(response);
    return SchoolModel.fromJson(_decodeObject(response.body));
  }

  Future<void> updateSchool(String id,
      {required String name, String? city}) async {
    final response = await _apiClient.put(
      '/api/institutions/$id',
      authenticated: true,
      body: {'name': name, 'city': _nullIfBlank(city)},
    );
    _ensureSuccess(response);
  }

  Future<void> deleteSchool(String id) async {
    final response =
        await _apiClient.delete('/api/institutions/$id', authenticated: true);
    _ensureSuccess(response);
  }

  Future<List<QuestionModel>> getQuestions({String? subjectId}) async {
    final query = subjectId == null || subjectId.isEmpty
        ? ''
        : '?subjectId=${Uri.encodeQueryComponent(subjectId)}';
    final response = await _apiClient.get('/api/questions$query',
        authenticated: true);
    _ensureSuccess(response);
    return _decodeList(response.body, QuestionModel.fromJson);
  }

  Future<QuestionModel> createQuestion(QuestionDraft draft) async {
    final response = await _apiClient.post('/api/questions',
        authenticated: true, body: draft.toJson());
    _ensureSuccess(response);
    return QuestionModel.fromJson(_decodeObject(response.body));
  }

  Future<void> updateQuestion(String id, QuestionDraft draft) async {
    final response = await _apiClient.put('/api/questions/$id',
        authenticated: true, body: draft.toJson());
    _ensureSuccess(response);
  }

  Future<void> deleteQuestion(String id) async {
    final response =
        await _apiClient.delete('/api/questions/$id', authenticated: true);
    _ensureSuccess(response);
  }

  // ─────────────────────────────────────────────────────────────
  // Códigos de invitación
  // ─────────────────────────────────────────────────────────────

  Future<List<InvitationCodeModel>> getInvitationCodes() async {
    final response =
        await _apiClient.get('/api/invitation-codes', authenticated: true);
    _ensureSuccess(response);
    return _decodeList(response.body, InvitationCodeModel.fromJson);
  }

  Future<InvitationCodeModel> createInvitationCode({
    required String institutionId,
    String? code,
    int maxUses = -1,
    DateTime? expiresAtUtc,
  }) async {
    final response = await _apiClient.post(
      '/api/invitation-codes',
      authenticated: true,
      body: {
        'code': _nullIfBlank(code),
        'institutionId': institutionId,
        'maxUses': maxUses,
        'expiresAtUtc': expiresAtUtc?.toUtc().toIso8601String(),
      },
    );
    _ensureSuccess(response);
    return InvitationCodeModel.fromJson(_decodeObject(response.body));
  }

  Future<void> updateInvitationCode(String id,
      {required int maxUses,
      DateTime? expiresAtUtc,
      required bool isActive}) async {
    final response = await _apiClient.put(
      '/api/invitation-codes/$id',
      authenticated: true,
      body: {
        'maxUses': maxUses,
        'expiresAtUtc': expiresAtUtc?.toUtc().toIso8601String(),
        'isActive': isActive,
      },
    );
    _ensureSuccess(response);
  }

  Future<void> revokeInvitationCode(String id) async {
    final response = await _apiClient.post('/api/invitation-codes/$id/revoke',
        authenticated: true);
    _ensureSuccess(response);
  }

  Future<void> deleteInvitationCode(String id) async {
    final response = await _apiClient.delete('/api/invitation-codes/$id',
        authenticated: true);
    _ensureSuccess(response);
  }

  // ─────────────────────────────────────────────────────────────
  // Planes y suscripciones
  // ─────────────────────────────────────────────────────────────

  /// Catálogo de planes activos. `target` puede ser "Particular" o "Institutional".
  Future<List<PlanModel>> getPlans({String? target}) async {
    final query = target == null || target.isEmpty
        ? ''
        : '?target=${Uri.encodeQueryComponent(target)}';
    final response = await _apiClient.get('/api/plans$query');
    _ensureSuccess(response);
    return _decodeList(response.body, PlanModel.fromJson);
  }

  /// Suscripción relevante para el usuario autenticado.
  /// Devuelve null si el usuario no tiene ninguna suscripción.
    Future<SubscriptionModel?> getMySubscription() async {
      final response = await _apiClient.get(
        '/api/subscriptions/current',
        authenticated: true,
      );

    if (response.statusCode == 404) return null;
    _ensureSuccess(response);

    final decoded = jsonDecode(response.body);
    if (decoded == null) return null;
    if (decoded is! Map) {
      throw const FormatException('La respuesta de la API es inválida.');
    }

    return SubscriptionModel.fromJson(Map<String, dynamic>.from(decoded));
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

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