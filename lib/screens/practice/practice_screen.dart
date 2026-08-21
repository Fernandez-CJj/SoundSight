import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/screens/practice/screens/challenges/challenges_screen.dart';
import 'package:soundsight/screens/practice/screens/fundamentals/fundamentals_screen.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Practice')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text('fundamentals'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => FundamentalScreen()),
                  );
                },
              ),
            ),
            Gap(8),
            Card(
              child: ListTile(
                title: Text('challenges'),
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => ChallengesScreen()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
