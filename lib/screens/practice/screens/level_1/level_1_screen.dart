import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Level1Question {
  const Level1Question({
    required this.text,
    required this.choices,
    required this.correctIndex,
  });

  final String text;
  final List<String> choices;
  final int correctIndex;
}

const level1Questions = <Level1Question>[
  Level1Question(
    text: 'What are the two types of keys found on a piano keyboard?',
    choices: [
      'High keys and low keys',
      'White keys and black keys',
      'Major keys and minor keys',
      'Long keys and short keys',
    ],
    correctIndex: 1,
  ),
  Level1Question(
    text: 'How are the black keys arranged on the piano?',
    choices: [
      'Groups of 1 and 2',
      'Groups of 2 and 3',
      'Groups of 3 and 4',
      'Groups of 4 and 5',
    ],
    correctIndex: 1,
  ),
  Level1Question(
    text: 'Where can you find the note C?',
    choices: [
      'To the right of a group of 2 black keys',
      'To the left of a group of 2 black keys',
      'Between a group of 3 black keys',
      'To the right of a group of 3 black keys',
    ],
    correctIndex: 1,
  ),
  Level1Question(
    text:
        'Starting from C, which is the correct order of the white-key note names?',
    choices: [
      'A, B, C, D, E, F, G',
      'C, D, E, F, G, A, B',
      'C, E, D, F, G, B, A',
      'C, D, F, E, G, A, B',
    ],
    correctIndex: 1,
  ),
  Level1Question(
    text: 'What happens after the note B in the repeating note sequence?',
    choices: [
      'It starts again at A',
      'It starts again at C',
      'It stops',
      'It starts again at D',
    ],
    correctIndex: 1,
  ),
  Level1Question(
    text: 'Which white-key notes are found around a group of 2 black keys?',
    choices: ['C, D, and E', 'D, E, and F', 'F, G, and A', 'A, B, and C'],
    correctIndex: 0,
  ),
  Level1Question(
    text: 'Which white-key notes are found around a group of 3 black keys?',
    choices: [
      'C, D, E, and F',
      'D, E, F, and G',
      'F, G, A, and B',
      'G, A, B, and C',
    ],
    correctIndex: 2,
  ),
  Level1Question(
    text: 'What is Middle C?',
    choices: [
      'The first C on the left side of the piano',
      'The highest C on the piano',
      'The C located near the center of the keyboard',
      'A black key in the middle of the piano',
    ],
    correctIndex: 2,
  ),
  Level1Question(
    text:
        'What happens to the pitch as you move from left to right on the piano?',
    choices: [
      'It becomes lower',
      'It becomes higher',
      'It stays the same',
      'It becomes quieter',
    ],
    correctIndex: 1,
  ),
  Level1Question(
    text: 'If you start on F, which notes come next in the white-key order?',
    choices: ['E, D, C', 'G, A, B', 'C, D, E', 'A, C, D'],
    correctIndex: 1,
  ),
];

class Level1Screen extends StatefulWidget {
  const Level1Screen({super.key});

  @override
  State<Level1Screen> createState() => _Level1ScreenState();
}

class _Level1ScreenState extends State<Level1Screen> {
  int questionIndex = 0;
  List<int?> answers = List<int?>.filled(level1Questions.length, null);
  bool quizFinished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const choiceLabels = ['A', 'B', 'C', 'D'];

    if (quizFinished) {
      var score = 0;
      for (var index = 0; index < level1Questions.length; index++) {
        if (answers[index] == level1Questions[index].correctIndex) {
          score++;
        }
      }

      return Scaffold(
        appBar: AppBar(title: const Text('Level 1 Quiz')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Quiz complete!', style: TextStyle(fontSize: 26)),
              const SizedBox(height: 8),
              Text(
                'You got $score out of ${level1Questions.length} correct.',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              for (var index = 0; index < level1Questions.length; index++)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${index + 1}: ${level1Questions[index].text}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your answer: ${choiceLabels[answers[index]!]}.'
                          ' ${level1Questions[index].choices[answers[index]!]}',
                        ),
                        Text(
                          'Correct answer: ${choiceLabels[level1Questions[index].correctIndex]}.'
                          ' ${level1Questions[index].choices[level1Questions[index].correctIndex]}',
                          style: TextStyle(
                            color:
                                answers[index] ==
                                    level1Questions[index].correctIndex
                                ? Colors.green.shade700
                                : Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  setState(() {
                    questionIndex = 0;
                    answers = List<int?>.filled(level1Questions.length, null);
                    quizFinished = false;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final question = level1Questions[questionIndex];
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final questionContent = <Widget>[
      Text('Question ${questionIndex + 1} of ${level1Questions.length}'),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: (questionIndex + 1) / level1Questions.length,
      ),
      const SizedBox(height: 32),
      Text(question.text, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 20),
    ];

    final answerContent = <Widget>[
      for (var index = 0; index < question.choices.length; index++)
        Card(
          child: ListTile(
            leading: Text('${choiceLabels[index]}.'),
            title: Text(question.choices[index]),
            selected: index == answers[questionIndex],
            selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
            onTap: () {
              setState(() {
                answers[questionIndex] = index;
              });
            },
          ),
        ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: answers[questionIndex] == null
            ? null
            : () {
                if (questionIndex == level1Questions.length - 1) {
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('Review Your Answers'),
                        content: SizedBox(
                          width: 500,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.sizeOf(dialogContext).height *
                                  0.55,
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: level1Questions.length,
                              itemBuilder: (context, index) {
                                final reviewQuestion = level1Questions[index];
                                final answerIndex = answers[index]!;
                                return ListTile(
                                  title: Text(
                                    '${index + 1}. ${reviewQuestion.text}',
                                  ),
                                  subtitle: Text(
                                    'Your answer: ${choiceLabels[answerIndex]}.'
                                    ' ${reviewQuestion.choices[answerIndex]}',
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Back'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              setState(() {
                                quizFinished = true;
                              });
                            },
                            child: const Text('Confirm'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  setState(() {
                    questionIndex++;
                  });
                }
              },
        child: Text(
          questionIndex == level1Questions.length - 1 ? 'Finish' : 'Next',
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Level 1 Quiz')),
      body: SafeArea(
        child: isLandscape
            ? Row(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: questionContent,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: answerContent,
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [...questionContent, ...answerContent],
              ),
      ),
    );
  }
}
