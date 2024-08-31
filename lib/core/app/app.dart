import 'package:quill_ai/core/app/style.dart';
import 'package:quill_ai/core/navigation/router.dart';
import 'package:flutter/material.dart';

class AIBuddy extends StatelessWidget {
  const AIBuddy({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QUILL',
      theme: darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
