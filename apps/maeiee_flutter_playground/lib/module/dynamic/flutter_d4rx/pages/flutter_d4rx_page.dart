import 'package:flutter/material.dart';
import 'package:flutter_d4rt/flutter_d4rt.dart';
import 'package:maeiee_flutter_playground/module/dynamic/flutter_d4rx/pages/snippets/flutter_d4rx_animated_container.dart';
import 'package:maeiee_flutter_playground/module/dynamic/flutter_d4rx/pages/snippets/flutter_d4rx_count_down_timer.dart';
import 'package:maeiee_flutter_playground/module/dynamic/flutter_d4rx/pages/snippets/flutter_d4rx_form.dart';
import 'package:maeiee_flutter_playground/module/dynamic/flutter_d4rx/pages/snippets/flutter_d4rx_future_builder.dart';
import 'package:maeiee_flutter_playground/module/dynamic/flutter_d4rx/pages/snippets/flutter_d4rx_snippet_hello_world.dart';
import 'package:maeiee_flutter_playground/module/dynamic/flutter_d4rx/pages/snippets/flutter_d4rx_snippet_list_view.dart';
import 'package:maeiee_flutter_playground/module/dynamic/flutter_d4rx/pages/snippets/flutter_d4rx_stream_builder.dart';

class FlutterD4rxPage extends StatefulWidget {
  const FlutterD4rxPage({super.key});

  @override
  State<FlutterD4rxPage> createState() => _FlutterD4rxPageState();
}

class _FlutterD4rxPageState extends State<FlutterD4rxPage> {
  final TextEditingController _codeController = TextEditingController();

  final Map<String, String> _snippets = {
    'hello_world': flutterD4rxSnippetHelloWorld,
    'listview': flutterD4rxListView,
    'form': flutterD4rxForm,
    'animated_container': flutterD4rxAnimatedContainer,
    'stream_builder': flutterD4rxStreamBuilder,
    'future_builder': flutterD4rxFutureBuilder,
    'count_down_timer': flutterD4rxCountDownTimer,
  };

  String code = '';

  String? _selectedSnippetKey;

  @override
  void initState() {
    super.initState();
    _selectedSnippetKey = _snippets.keys.first;
    _codeController.text = _snippets[_selectedSnippetKey]!;
  }

  @override
  void dispose() {
    super.dispose();
    _codeController.dispose();
  }

  void _runCode() {
    setState(() {
      code = _codeController.text;
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

          // Middle: Code Editor & Preview
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(8, 0, 4, 8),
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
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(4, 0, 8, 8),
                    width: double.infinity,
                    color: Colors.black,
                    padding: const EdgeInsets.all(12),
                    child: code.isNotEmpty
                        ? InterpretedWidget(
                            key: ValueKey(code),
                            code: code,
                            entryPoint: 'MyWidget',
                          )
                        : Placeholder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
