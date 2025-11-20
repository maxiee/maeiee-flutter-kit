import 'package:d4rt/d4rt.dart';
import 'package:flutter/material.dart';

class D4rxPage extends StatelessWidget {
  const D4rxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final code = '''
    int fib(int n) {
      if (n <= 1) return n;
      return fib(n - 1) + fib(n - 2);
    }
    main() {
      return fib(6);
    }
  ''';

    final interpreter = D4rt();
    final stopwatch = Stopwatch()..start();
    final result = interpreter.execute(source: code);
    final elapsed = stopwatch.elapsedMilliseconds;
    return Scaffold(
      appBar: AppBar(title: const Text('d4rx Page')),
      body: Center(
        child: Text('d4rt Execution Result: $result, Time: ${elapsed} ms'),
      ),
    );
  }
}
