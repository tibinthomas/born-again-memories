import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/blog_post.dart';
import 'package:my_app/models/forum_question.dart';

void main() {
  test('legacy community content remains visible by default', () {
    final story = BlogPost.fromJson({
      'id': 'story-1',
      'title': 'A first',
      'content': 'Story',
      'authorId': 'author-1',
      'authorName': 'Parent',
      'createdAt': DateTime.utc(2026, 7, 31, 12).millisecondsSinceEpoch,
    });
    final question = ForumQuestion.fromJson({
      'id': 'question-1',
      'content': 'How do you celebrate this?',
      'authorId': 'author-1',
      'authorName': 'Parent',
      'createdAt': DateTime.utc(2026, 7, 31, 12).millisecondsSinceEpoch,
    });

    expect(story.moderationStatus, 'active');
    expect(question.moderationStatus, 'active');
  });

  test('moderation status survives community model serialization', () {
    final answer = ForumAnswer(
      id: 'answer-1',
      content: 'An answer',
      authorId: 'author-2',
      authorName: 'Another parent',
      createdAt: DateTime.utc(2026, 7, 31),
      moderationStatus: 'hidden',
    );

    final restored = ForumAnswer.fromJson(answer.toJson());
    expect(restored.moderationStatus, 'hidden');
  });
}
