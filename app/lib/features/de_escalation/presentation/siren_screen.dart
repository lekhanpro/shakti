import 'package:flutter/material.dart';

class SirenScreen extends StatelessWidget {
  const SirenScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Siren')), body: const SizedBox.shrink());
}
