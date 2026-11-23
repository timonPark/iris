/// 요청·응답 모양. `docs/api/openapi.yaml`의 components/schemas와 같다.
library;

/// 관리자 또는 사용자(`Role`).
enum Role { admin, user }

/// `LoginResponse`.
class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.role,
    required this.passwordChangeRequired,
  });

  final String accessToken;
  final Role role;

  /// 임시 비밀번호 상태. true면 비밀번호 변경 API 외에는 거부된다.
  final bool passwordChangeRequired;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      role: Role.values.byName(json['role'] as String),
      passwordChangeRequired: json['passwordChangeRequired'] as bool,
    );
  }
}

/// `ErrorResponse`의 `error`. [code]로 분기하고 [message]는 화면에 그대로 보여줄 수 있다.
class ApiError {
  const ApiError({required this.code, required this.message});

  final String code;
  final String message;

  /// 오류 모양이 아니면 null.
  static ApiError? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }
    final Object? error = json['error'];
    if (error is! Map<String, dynamic>) {
      return null;
    }
    final Object? code = error['code'];
    final Object? message = error['message'];
    if (code is! String || message is! String) {
      return null;
    }
    return ApiError(code: code, message: message);
  }
}

/// `Session`. 세션 목록의 한 줄.
class Session {
  const Session({
    required this.id,
    required this.title,
    required this.updatedAt,
  });

  final String id;

  /// 첫 질문의 앞 30자 정도.
  final String title;

  /// 최근 활동 시각.
  final DateTime updatedAt;

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      title: json['title'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// `SessionPage`. [nextCursor]가 없으면 마지막 페이지.
class SessionPage {
  const SessionPage({required this.items, this.nextCursor});

  final List<Session> items;
  final String? nextCursor;

  factory SessionPage.fromJson(Map<String, dynamic> json) {
    return SessionPage(
      items: <Session>[
        for (final Object? item in json['items'] as List<dynamic>)
          Session.fromJson(item as Map<String, dynamic>),
      ],
      nextCursor: json['nextCursor'] as String?,
    );
  }
}

/// `AnswerStatus`. 완료 또는 중단됨.
enum AnswerStatus { completed, stopped }

/// `Answer`.
class Answer {
  const Answer({required this.id, required this.text, required this.status});

  final String id;
  final String text;
  final AnswerStatus status;

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'] as String,
      text: json['text'] as String,
      status: AnswerStatus.values.byName(json['status'] as String),
    );
  }
}

/// `Question`. 질문과 그 답변.
class Question {
  const Question({required this.id, required this.text, required this.answer});

  final String id;
  final String text;
  final Answer answer;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      answer: Answer.fromJson(json['answer'] as Map<String, dynamic>),
    );
  }
}

/// `QuestionPage`. 최신 질문부터 내려온다.
class QuestionPage {
  const QuestionPage({required this.items, this.nextCursor});

  final List<Question> items;
  final String? nextCursor;

  factory QuestionPage.fromJson(Map<String, dynamic> json) {
    return QuestionPage(
      items: <Question>[
        for (final Object? item in json['items'] as List<dynamic>)
          Question.fromJson(item as Map<String, dynamic>),
      ],
      nextCursor: json['nextCursor'] as String?,
    );
  }
}
