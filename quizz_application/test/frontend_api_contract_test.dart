import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:quizz_application/core/auth/auth_controller.dart';
import 'package:quizz_application/core/auth/auth_models.dart';
import 'package:quizz_application/core/auth/auth_repository.dart';
import 'package:quizz_application/core/network/api_client.dart';
import 'package:quizz_application/core/security/token_storage.dart';
import 'package:quizz_application/features/content/data/content_models.dart';
import 'package:quizz_application/features/content/data/content_repository.dart';
import 'package:quizz_application/features/practice/data/practice_repository.dart';
import 'package:quizz_application/features/practice/presentation/pages/practice_session_page.dart';

void main() {
  test(
    'el registro público conserva el flujo de confirmación por correo',
    () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'requiresEmailConfirmation': true,
            'message': 'Revisa tu correo.',
          }),
          200,
        );
      });
      final storage = _MemoryTokenStorage();
      final apiClient = ApiClient(
        tokenStorage: storage,
        baseUrl: 'https://localhost:7126',
        client: client,
      );
      final repository = AuthRepository(
        apiClient: apiClient,
        tokenStorage: storage,
      );

      final result = await repository.register(
        email: 'estudiante@example.com',
        password: 'Password123',
        firstName: 'Ana',
        lastName: 'Pérez',
      );

      // El backend devuelve un mensaje de confirmación; el registro público
      // nunca emite sesión (debe confirmarse el correo primero).
      expect(result.message, isNotEmpty);
      expect(storage.savedSessions, 0);
      expect(capturedRequest.url.path, '/api/auth/register-student');
      expect(jsonDecode(capturedRequest.body), {
        'email': 'estudiante@example.com',
        'password': 'Password123',
        'firstName': 'Ana',
        'lastName': 'Pérez',
      });
      apiClient.dispose();
    },
  );

  test(
    'el controlador espera la confirmación antes de iniciar sesión',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'requiresEmailConfirmation': true,
            'message': 'Revisa tu correo.',
          }),
          200,
        ),
      );
      final storage = _MemoryTokenStorage();
      final apiClient = ApiClient(
        tokenStorage: storage,
        baseUrl: 'https://localhost:7126',
        client: client,
      );
      final controller = AuthController(
        AuthRepository(apiClient: apiClient, tokenStorage: storage),
      )..status = AuthStatus.unauthenticated;

      final success = await controller.register(
        email: 'estudiante@example.com',
        password: 'Password123',
        firstName: 'Ana',
        lastName: 'Pérez',
      );

      expect(success, isTrue);
      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.currentUser, isNull);
      expect(
        controller.registrationConfirmationEmail,
        'estudiante@example.com',
      );
      apiClient.dispose();
    },
  );

  test('crear profesor no reemplaza la sesión del administrador', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(jsonEncode(_authResponse(role: 'Teacher')), 200);
    });
    final storage = _MemoryTokenStorage(accessToken: 'admin-access-token');
    final apiClient = ApiClient(
      tokenStorage: storage,
      baseUrl: 'https://localhost:7126',
      client: client,
    );
    final repository = AuthRepository(
      apiClient: apiClient,
      tokenStorage: storage,
    );

    await repository.registerStaff(
      email: 'profesor@example.com',
      password: 'Password123',
      firstName: 'Mario',
      lastName: 'Gómez',
    );

    expect(capturedRequest.url.path, '/api/auth/register-staff');
    expect(
      capturedRequest.headers['Authorization'],
      'Bearer admin-access-token',
    );
    expect(jsonDecode(capturedRequest.body), {
      'email': 'profesor@example.com',
      'password': 'Password123',
      'firstName': 'Mario',
      'lastName': 'Gómez',
      'role': 'Teacher',
    });
    // La sesión del admin no debe sobrescribirse con la del profesor creado.
    expect(storage.savedSessions, 0);
    apiClient.dispose();
  });

  test('crea una pregunta con dificultad y respuesta correcta', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'id': 'question-id',
          ...body,
          'subjectName': 'Matemáticas',
          'createdByUserId': 'teacher-id',
          'options': [
            {'id': 'a', 'text': '2', 'isCorrect': false},
            {'id': 'b', 'text': '4', 'isCorrect': true},
          ],
        }),
        201,
      );
    });
    final storage = _MemoryTokenStorage(accessToken: 'teacher-token');
    final apiClient = ApiClient(
      tokenStorage: storage,
      baseUrl: 'https://localhost:7126',
      client: client,
    );
    final repository = ContentRepository(apiClient);
    const draft = QuestionDraft(
      text: '¿Cuánto es 2 + 2?',
      justification: 'La suma de dos y dos es cuatro.',
      difficulty: QuestionDifficulty.easy,
      subjectId: 'subject-id',
      options: [
        QuestionOptionDraft(text: '2', isCorrect: false),
        QuestionOptionDraft(text: '4', isCorrect: true),
      ],
    );

    final question = await repository.createQuestion(draft);

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/api/questions');
    expect(capturedRequest.headers['Authorization'], 'Bearer teacher-token');
    final payload = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
    expect(payload['difficulty'], 1);
    expect(
      (payload['options'] as List).where(
        (option) => (option as Map<String, dynamic>)['isCorrect'] == true,
      ),
      hasLength(1),
    );
    expect(question.id, 'question-id');
    apiClient.dispose();
  });

  test('actualiza y elimina preguntas con los verbos correctos', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      // PUT returns the updated question; DELETE returns no content.
      return request.method == 'PUT'
          ? http.Response(jsonEncode(_questionResponse), 200)
          : http.Response('', 204);
    });
    final storage = _MemoryTokenStorage(accessToken: 'teacher-token');
    final apiClient = ApiClient(
      tokenStorage: storage,
      baseUrl: 'https://localhost:7126',
      client: client,
    );
    final repository = ContentRepository(apiClient);
    const draft = QuestionDraft(
      text: 'Pregunta actualizada',
      justification: 'Justificación',
      difficulty: QuestionDifficulty.medium,
      subjectId: 'subject-id',
      options: [
        QuestionOptionDraft(text: 'A', isCorrect: true),
        QuestionOptionDraft(text: 'B', isCorrect: false),
      ],
    );

    final updatedQuestion = await repository.updateQuestion('question-id', draft);
    await repository.deleteQuestion('question-id');

    expect(requests[0].method, 'PUT');
    expect(requests[0].url.path, '/api/questions/question-id');
    expect(updatedQuestion.id, 'question-id');
    expect(requests[1].method, 'DELETE');
    expect(requests[1].url.path, '/api/questions/question-id');
    apiClient.dispose();
  });

  test('editing a question sends its images back so they are not deleted', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(jsonEncode(_questionResponse), 200);
    });
    final apiClient = ApiClient(
      tokenStorage: _MemoryTokenStorage(accessToken: 'teacher-token'),
      baseUrl: 'https://localhost:7126',
      client: client,
    );
    final repository = ContentRepository(apiClient);
    const draft = QuestionDraft(
      text: 'Pregunta con gráfica',
      imageUrl: '/images/math_q9_tabla.png',
      justification: 'Justificación',
      justificationImageUrl: '/images/formula.png',
      difficulty: QuestionDifficulty.medium,
      subjectId: 'subject-id',
      options: [
        QuestionOptionDraft(
          text: 'A',
          isCorrect: true,
          imageUrl: '/images/math_q12_grafica_a.png',
        ),
        QuestionOptionDraft(text: 'B', isCorrect: false),
      ],
    );

    await repository.updateQuestion('question-id', draft);

    final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
    expect(body['imageUrl'], '/images/math_q9_tabla.png');
    expect(body['justificationImageUrl'], '/images/formula.png');
    expect(
      (body['options'] as List).first['imageUrl'],
      '/images/math_q12_grafica_a.png',
    );
    apiClient.dispose();
  });

  test('restoring the session needs a single refresh-token request that returns the user', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response(jsonEncode(_authResponse(role: 'Student')), 200);
    });
    final storage = _MemoryTokenStorage()..refreshToken = 'stored-refresh-token';
    final apiClient = ApiClient(
      tokenStorage: storage,
      baseUrl: 'https://localhost:7126',
      client: client,
    );
    final repository = AuthRepository(apiClient: apiClient, tokenStorage: storage);

    final restoredUser = await repository.restoreSession();

    expect(requests, hasLength(1));
    expect(requests.single.method, 'POST');
    expect(requests.single.url.path, '/api/auth/refresh-token');
    expect(jsonDecode(requests.single.body), {'refreshToken': 'stored-refresh-token'});
    expect(restoredUser?.email, 'user@example.com');
    expect(storage.refreshToken, 'new-refresh-token');
    apiClient.dispose();
  });

  test('logout revokes the refresh token on /api/auth/logout and clears local tokens', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response('', 204);
    });
    final storage = _MemoryTokenStorage(accessToken: 'access-token')
      ..refreshToken = 'stored-refresh-token';
    final apiClient = ApiClient(
      tokenStorage: storage,
      baseUrl: 'https://localhost:7126',
      client: client,
    );
    final repository = AuthRepository(apiClient: apiClient, tokenStorage: storage);

    await repository.logout();

    expect(capturedRequest.url.path, '/api/auth/logout');
    expect(storage.refreshToken, isNull);
    apiClient.dispose();
  });

  test('revoking an invitation code is a PUT with isActive false that keeps uses and expiration', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({..._invitationCodeResponse, 'isActive': false, 'isUsable': false}),
        200,
      );
    });
    final apiClient = ApiClient(
      tokenStorage: _MemoryTokenStorage(accessToken: 'admin-token'),
      baseUrl: 'https://localhost:7126',
      client: client,
    );
    final repository = ContentRepository(apiClient);
    final code = InvitationCodeModel.fromJson(_invitationCodeResponse);

    final revokedCode = await repository.revokeInvitationCode(code);

    expect(capturedRequest.method, 'PUT');
    expect(capturedRequest.url.path, '/api/invitation-codes/code-id');
    final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
    expect(body['isActive'], false);
    expect(body['maxUses'], 100);
    expect(body['expiresAtUtc'], isNotNull);
    expect(revokedCode.isActive, isFalse);
    apiClient.dispose();
  });

  test('the practice history uses the lightweight summary endpoint', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode([
          {
            'id': 'session-id',
            'subjectId': 'subject-id',
            'subjectName': 'Matemáticas',
            'status': 'Completed',
            'startedAtUtc': '2026-09-10T18:00:00Z',
            'finishedAtUtc': '2026-09-10T18:30:00Z',
            'totalQuestions': 5,
            'answeredQuestions': 4,
            'correctAnswers': 3,
          },
        ]),
        200,
      );
    });
    final apiClient = ApiClient(
      tokenStorage: _MemoryTokenStorage(accessToken: 'student-token'),
      baseUrl: 'https://localhost:7126',
      client: client,
    );

    final history = await PracticeRepository(apiClient).getHistory();

    expect(capturedRequest.url.path, '/api/practice-sessions/history');
    expect(history.single.isCompleted, isTrue);
    expect(history.single.totalQuestions, 5);
    expect(history.single.answeredQuestions, 4);
    expect(history.single.correctAnswers, 3);
    apiClient.dispose();
  });

  test('subscription and report endpoints use the renamed routes', () async {
    final requestedPaths = <String>[];
    final client = MockClient((request) async {
      requestedPaths.add(request.url.path);
      return request.url.path.startsWith('/api/reports')
          ? http.Response(jsonEncode({'institutionName': null, 'students': []}), 200)
          : http.Response('null', 200);
    });
    final apiClient = ApiClient(
      tokenStorage: _MemoryTokenStorage(accessToken: 'token'),
      baseUrl: 'https://localhost:7126',
      client: client,
    );
    final repository = ContentRepository(apiClient);

    expect(await repository.getMySubscription(), isNull);
    await repository.getStudentReports();

    expect(requestedPaths, [
      '/api/subscriptions/current-user',
      '/api/reports/student-performance',
    ]);
    apiClient.dispose();
  });

  test(
    'completa el contrato de inicio, respuesta y cierre de práctica',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/practice-sessions') {
          return http.Response(jsonEncode(_sessionResponse), 201);
        }
        if (request.url.path.endsWith('/answers')) {
          return http.Response(
            jsonEncode({
              'questionId': 'question-id',
              'isCorrect': true,
              'correctOptionId': 'option-b',
              'justification': 'Es la opción correcta.',
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'id': 'session-id',
            'totalQuestions': 1,
            'correctAnswers': 1,
            'scorePercentage': 100,
            'answers': [
              {
                'questionId': 'question-id',
                'questionText': 'Pregunta de prueba',
                'selectedOptionId': 'option-b',
                'correctOptionId': 'option-b',
                'isCorrect': true,
                'justification': 'Es la opción correcta.',
              },
            ],
          }),
          200,
        );
      });
      final storage = _MemoryTokenStorage(accessToken: 'student-token');
      final apiClient = ApiClient(
        tokenStorage: storage,
        baseUrl: 'https://localhost:7126',
        client: client,
      );
      final repository = PracticeRepository(apiClient);

      final session = await repository.startSession(
        subjectId: 'subject-id',
        questionCount: 10,
      );
      final answer = await repository.submitAnswer(
        sessionId: session.id,
        questionId: session.questions.first.id,
        selectedOptionId: 'option-b',
      );
      final result = await repository.finishSession(session.id);

      expect(jsonDecode(requests[0].body), {
        'subjectId': 'subject-id',
        'questionCount': 10,
      });
      expect(requests[1].url.path, '/api/practice-sessions/session-id/answers');
      expect(requests[2].url.path, '/api/practice-sessions/session-id/finish');
      expect(answer.isCorrect, isTrue);
      expect(result.scorePercentage, 100);
      apiClient.dispose();
    },
  );

  testWidgets('el estudiante responde y finaliza una práctica', (tester) async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/practice-sessions') {
        return http.Response(jsonEncode(_sessionResponse), 201);
      }
      if (request.url.path.endsWith('/answers')) {
        return http.Response(
          jsonEncode({
            'questionId': 'question-id',
            'isCorrect': true,
            'correctOptionId': 'option-b',
            'justification': 'Es la opción correcta.',
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'id': 'session-id',
          'totalQuestions': 1,
          'correctAnswers': 1,
          'scorePercentage': 100,
          'answers': [
            {
              'questionId': 'question-id',
              'questionText': 'Pregunta de prueba',
              'selectedOptionId': 'option-b',
              'correctOptionId': 'option-b',
              'isCorrect': true,
              'justification': 'Es la opción correcta.',
            },
          ],
        }),
        200,
      );
    });
    final storage = _MemoryTokenStorage(accessToken: 'student-token');
    final apiClient = ApiClient(
      tokenStorage: storage,
      baseUrl: 'https://localhost:7126',
      client: client,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PracticeSessionPage(
          apiClient: apiClient,
          subject: const SubjectModel(id: 'subject-id', name: 'Matemáticas'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pregunta de prueba'), findsOneWidget);
    await tester.tap(find.text('B').last);
    await tester.pump();
    await tester.tap(find.text('Responder'));
    await tester.pumpAndSettle();
    expect(find.text('¡Respuesta correcta!'), findsOneWidget);

    await tester.tap(find.text('Finalizar práctica'));
    await tester.pumpAndSettle();
    expect(find.text('Práctica completada'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    apiClient.dispose();
  });
}

/// Respuesta completa de un endpoint que emite sesión (login, register-staff, 2fa/verify).
/// Refleja el contrato actual: tokens + user anidado.
Map<String, dynamic> _authResponse({required String role}) {
  return {
    'tokenType': 'Bearer',
    'accessToken': 'new-access-token',
    'expiresAtUtc': '2026-09-10T18:00:00Z',
    'refreshToken': 'new-refresh-token',
    'refreshTokenExpiresAtUtc': '2026-09-24T18:00:00Z',
    'user': {
      'id': 'user-id',
      'email': 'user@example.com',
      'firstName': 'Test',
      'lastName': 'User',
      'roles': [role],
      'schoolId': null,
    },
  };
}

const _questionResponse = {
  'id': 'question-id',
  'text': 'Pregunta actualizada',
  'imageUrl': null,
  'justification': 'Justificación',
  'justificationImageUrl': null,
  'difficulty': 2,
  'subjectId': 'subject-id',
  'subjectName': 'Matemáticas',
  'createdByUserId': 'teacher-id',
  'options': [
    {'id': 'option-a', 'text': 'A', 'isCorrect': true, 'imageUrl': null},
    {'id': 'option-b', 'text': 'B', 'isCorrect': false, 'imageUrl': null},
  ],
};

const _invitationCodeResponse = {
  'id': 'code-id',
  'code': 'COLEGIO-SJ-2026',
  'institutionId': 'school-id',
  'institutionName': 'Colegio San José',
  'maxUses': 100,
  'uses': 3,
  'expiresAtUtc': '2027-04-30T00:00:00Z',
  'isActive': true,
  'isUsable': true,
  'createdAtUtc': '2026-10-01T00:00:00Z',
  'updatedAtUtc': null,
};

const _sessionResponse = {
  'id': 'session-id',
  'subjectId': 'subject-id',
  'subjectName': 'Matemáticas',
  'status': 'InProgress',
  'startedAtUtc': '2026-09-10T18:00:00Z',
  'finishedAtUtc': null,
  'questions': [
    {
      'questionId': 'question-id',
      'text': 'Pregunta de prueba',
      'answered': false,
      'selectedOptionId': null,
      'options': [
        {'id': 'option-a', 'text': 'A'},
        {'id': 'option-b', 'text': 'B'},
      ],
    },
  ],
};

class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage({this.accessToken});

  String? accessToken;
  String? refreshToken;
  int savedSessions = 0;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveSession(AuthSession session) async {
    savedSessions++;
    accessToken = session.accessToken;
    refreshToken = session.refreshToken;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}