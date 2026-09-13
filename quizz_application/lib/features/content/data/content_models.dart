enum QuestionDifficulty {
  easy(1, 'Fácil'),
  medium(2, 'Media'),
  hard(3, 'Difícil');

  const QuestionDifficulty(this.apiValue, this.label);

  final int apiValue;
  final String label;

  factory QuestionDifficulty.fromJson(Object? value) {
    if (value is int) {
      return QuestionDifficulty.values.firstWhere(
        (difficulty) => difficulty.apiValue == value,
        orElse: () => QuestionDifficulty.medium,
      );
    }

    final normalized = value?.toString().toLowerCase();
    return switch (normalized) {
      'easy' || '1' => QuestionDifficulty.easy,
      'hard' || '3' => QuestionDifficulty.hard,
      _ => QuestionDifficulty.medium,
    };
  }
}

class SubjectModel {
  const SubjectModel({required this.id, required this.name, this.description});

  final String id;
  final String name;
  final String? description;

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

class SchoolModel {
  const SchoolModel({required this.id, required this.name, this.city});

  final String id;
  final String name;
  final String? city;

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString(),
    );
  }
}

class QuestionOptionModel {
  const QuestionOptionModel({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  final String id;
  final String text;
  final bool isCorrect;

  factory QuestionOptionModel.fromJson(Map<String, dynamic> json) {
    return QuestionOptionModel(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      isCorrect: json['isCorrect'] == true,
    );
  }
}

class QuestionModel {
  const QuestionModel({
    required this.id,
    required this.text,
    required this.justification,
    required this.difficulty,
    required this.subjectId,
    required this.subjectName,
    required this.createdByUserId,
    required this.options,
  });

  final String id;
  final String text;
  final String justification;
  final QuestionDifficulty difficulty;
  final String subjectId;
  final String subjectName;
  final String createdByUserId;
  final List<QuestionOptionModel> options;

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return QuestionModel(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      justification: json['justification']?.toString() ?? '',
      difficulty: QuestionDifficulty.fromJson(json['difficulty']),
      subjectId: json['subjectId']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? '',
      createdByUserId: json['createdByUserId']?.toString() ?? '',
      options: rawOptions is List
          ? rawOptions
                .whereType<Map>()
                .map(
                  (option) => QuestionOptionModel.fromJson(
                    Map<String, dynamic>.from(option),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }
}

class QuestionOptionDraft {
  const QuestionOptionDraft({required this.text, required this.isCorrect});

  final String text;
  final bool isCorrect;

  Map<String, dynamic> toJson() => {'text': text, 'isCorrect': isCorrect};
}

class QuestionDraft {
  const QuestionDraft({
    required this.text,
    required this.justification,
    required this.difficulty,
    required this.subjectId,
    required this.options,
  });

  final String text;
  final String justification;
  final QuestionDifficulty difficulty;
  final String subjectId;
  final List<QuestionOptionDraft> options;

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'justification': justification,
      'difficulty': difficulty.apiValue,
      'subjectId': subjectId,
      'options': options.map((option) => option.toJson()).toList(),
    };
  }
}
