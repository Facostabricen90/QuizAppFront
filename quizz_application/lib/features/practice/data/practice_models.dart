class PracticeQuestionOptionModel {
  const PracticeQuestionOptionModel({
    required this.id, 
    required this.text,
    this.imageUrl,
  });

  final String id;
  final String text;
  final String? imageUrl;

  factory PracticeQuestionOptionModel.fromJson(Map<String, dynamic> json) {
    return PracticeQuestionOptionModel(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class PracticeQuestionModel {
  const PracticeQuestionModel({
    required this.id,
    required this.text,
    required this.options,
    required this.answered,
    this.selectedOptionId,
    this.imageUrl, // <--- AGREGADO AQUÍ
  });

  final String id;
  final String text;
  final String? imageUrl; // <--- AGREGADO AQUÍ
  final List<PracticeQuestionOptionModel> options;
  final bool answered;
  final String? selectedOptionId;

  factory PracticeQuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return PracticeQuestionModel(
      id: json['questionId']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(), // <--- AGREGADO AQUÍ
      options: rawOptions is List
          ? rawOptions
                .whereType<Map>()
                .map(
                  (option) => PracticeQuestionOptionModel.fromJson(
                    Map<String, dynamic>.from(option),
                  ),
                )
                .toList(growable: false)
          : const [],
      answered: json['answered'] == true,
      selectedOptionId: json['selectedOptionId']?.toString(),
    );
  }
}

class PracticeSessionModel {
  const PracticeSessionModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.status,
    required this.startedAtUtc,
    required this.questions,
    this.finishedAtUtc,
  });

  final String id;
  final String subjectId;
  final String subjectName;
  final String status;
  final DateTime? startedAtUtc;
  final DateTime? finishedAtUtc;
  final List<PracticeQuestionModel> questions;

  bool get isCompleted => status.toLowerCase() == 'completed';

  factory PracticeSessionModel.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    return PracticeSessionModel(
      id: json['id']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      startedAtUtc: DateTime.tryParse(json['startedAtUtc']?.toString() ?? ''),
      finishedAtUtc: DateTime.tryParse(json['finishedAtUtc']?.toString() ?? ''),
      questions: rawQuestions is List
          ? rawQuestions
                .whereType<Map>()
                .map(
                  (question) => PracticeQuestionModel.fromJson(
                    Map<String, dynamic>.from(question),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }
}

class AnswerResultModel {
  const AnswerResultModel({
    required this.questionId,
    required this.isCorrect,
    required this.correctOptionId,
    required this.justification,
  });

  final String questionId;
  final bool isCorrect;
  final String correctOptionId;
  final String justification;

  factory AnswerResultModel.fromJson(Map<String, dynamic> json) {
    return AnswerResultModel(
      questionId: json['questionId']?.toString() ?? '',
      isCorrect: json['isCorrect'] == true,
      correctOptionId: json['correctOptionId']?.toString() ?? '',
      justification: json['justification']?.toString() ?? '',
    );
  }
}

class AnswerReviewModel {
  const AnswerReviewModel({
    required this.questionId,
    required this.questionText,
    required this.correctOptionId,
    required this.isCorrect,
    required this.justification,
    this.selectedOptionId,
  });

  final String questionId;
  final String questionText;
  final String? selectedOptionId;
  final String correctOptionId;
  final bool isCorrect;
  final String justification;

  factory AnswerReviewModel.fromJson(Map<String, dynamic> json) {
    return AnswerReviewModel(
      questionId: json['questionId']?.toString() ?? '',
      questionText: json['questionText']?.toString() ?? '',
      selectedOptionId: json['selectedOptionId']?.toString(),
      correctOptionId: json['correctOptionId']?.toString() ?? '',
      isCorrect: json['isCorrect'] == true,
      justification: json['justification']?.toString() ?? '',
    );
  }
}

class PracticeSessionResultModel {
  const PracticeSessionResultModel({
    required this.id,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercentage,
    required this.answers,
  });

  final String id;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercentage;
  final List<AnswerReviewModel> answers;

  factory PracticeSessionResultModel.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'];
    return PracticeSessionResultModel(
      id: json['id']?.toString() ?? '',
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      scorePercentage: (json['scorePercentage'] as num?)?.toDouble() ?? 0,
      answers: rawAnswers is List
          ? rawAnswers
                .whereType<Map>()
                .map(
                  (answer) => AnswerReviewModel.fromJson(
                    Map<String, dynamic>.from(answer),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }
}