import 'package:flutter/material.dart';

class FakeCallScreen extends StatelessWidget {
  const FakeCallScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Fake call')), body: const SizedBox.shrink());
}
