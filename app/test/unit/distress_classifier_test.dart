import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/engines/distress_classifier.dart';

void main() {
  void expectLevel(List<String> texts, DistressLevel level) {
    for (final t in texts) {
      expect(DistressClassifier.classify(t), level, reason: t);
    }
  }

  test('English danger phrases', () {
    expectLevel([
      'Someone is following me',
      'I think I am being followed home',
      'I was ATTACKED near the station',
      'he raped me',
      'my friend was kidnapped',
      'He has a knife!!',
      'help me please',
      'HELP ME',
      'I want to kill myself',
      'thinking about suicide',
      'I keep wanting to self-harm',
      'I want to end my life',
    ], DistressLevel.danger);
  });

  test('Hindi transliterations', () {
    expectLevel([
      'bachao',
      'Koi mujhe bachao!',
      'madad chahiye',
      'ek aadmi peecha kar raha hai',
    ], DistressLevel.danger);
  });

  test('Kannada transliterations', () {
    expectLevel(['kaapadi', 'nanage sahaya beku'], DistressLevel.danger);
  });

  test('native scripts', () {
    expectLevel(['मुझे बचाओ', 'ನನ್ನನ್ನು ಕಾಪಾಡಿ'], DistressLevel.danger);
  });

  test('concern words', () {
    expectLevel([
      'I feel unsafe walking here',
      'I am scared',
      'this is harassment at work',
      'someone keeps stalking my profile',
      'my manager makes me uncomfortable',
      'I am being harassed',
    ], DistressLevel.concern);
  });

  test('danger outranks concern', () {
    expect(DistressClassifier.classify('I am scared, he has a knife'), DistressLevel.danger);
  });

  test('no false matches inside words', () {
    expectLevel([
      '',
      '   ',
      'knifeless cooking tips',
      'that was helpful, thanks',
      'what a helpful answer',
      'what are good safety apps?',
      'the scaredy-cat movie', // "scaredy" is not "scared"
      'raper-lee is not a word',
      'grape juice',
      'I love this community',
      'Hello, how do I add a contact?',
    ], DistressLevel.none);
  });
}
