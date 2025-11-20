import 'package:d4rt/d4rt.dart';
import 'package:flutter/material.dart';

class D4rxPage extends StatefulWidget {
  const D4rxPage({super.key});

  @override
  State<D4rxPage> createState() => _D4rxPageState();
}

class _D4rxPageState extends State<D4rxPage> {
  final TextEditingController _codeController = TextEditingController();
  String _output = 'Ready to run...';

  final Map<String, String> _snippets = {
    'Fibonacci (Recursive)': '''
int fib(int n) {
  if (n <= 1) return n;
  return fib(n - 1) + fib(n - 2);
}
main() {
  return fib(10);
}
''',
    'Hello World': '''
main() {
  return "Hello, World!";
}
''',
    'Factorial': '''
int fact(int n) {
  if (n <= 1) return 1;
  return n * fact(n - 1);
}
main() {
  return fact(5);
}
''',
    'Sum 1 to 100': '''
int sum(int n) {
  int s = 0;
  int i = 1;
  while (i <= n) {
    s = s + i;
    i = i + 1;
  }
  return s;
}
main() {
  return sum(100);
}
''',
  };

  String? _selectedSnippetKey;

  @override
  void initState() {
    super.initState();
    _selectedSnippetKey = _snippets.keys.first;
    _codeController.text = _snippets[_selectedSnippetKey]!;
  }

  void _runCode() {
    setState(() {
      _output = 'Running...';
    });

    // Use a slight delay to allow UI to update "Running..."
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        final interpreter = D4rt();
        final stopwatch = Stopwatch()..start();
        final result = interpreter.execute(source: _codeController.text);
        final elapsed = stopwatch.elapsedMilliseconds;

        setState(() {
          _output = 'Result: $result\nTime: ${elapsed}ms';
        });
      } catch (e) {
        setState(() {
          _output = 'Error: $e';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('d4rx Playground')),
      body: Column(
        children: [
          // Top Bar: Dropdown and Run Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedSnippetKey,
                    items: _snippets.keys.map((String key) {
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Text(key),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedSnippetKey = newValue;
                          _codeController.text = _snippets[newValue]!;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _runCode,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run'),
                ),
              ],
            ),
          ),

          // Middle: Code Editor
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                controller: _codeController,
                maxLines: null,
                expands: true,
                style: const TextStyle(
                  fontFamily: 'Courier', // Monospace
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                  hintText: 'Enter Dart code here...',
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Bottom: Terminal Output
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TERMINAL',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.grey, height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _output,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'Courier',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
