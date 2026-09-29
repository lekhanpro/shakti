import 'package:flutter/material.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Unlock')), body: const SizedBox.shrink());
}
