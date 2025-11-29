import 'package:d4rt/d4rt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_d4rt/flutter_d4rt.dart';

class ASimpleWidget extends StatelessWidget {
  const ASimpleWidget({super.key, this.wordsToShow = ''});

  final String wordsToShow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        wordsToShow.isEmpty ? '✨ D4RT 动态化' : wordsToShow,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

final aSimpleWidgetBridge = BridgedClass(
  nativeType: ASimpleWidget,
  name: 'ASimpleWidget',
  constructors: {
    '':
        (
          InterpreterVisitor visitor,
          List<Object?> positionalArgs,
          Map<String, Object?> namedArgs,
        ) {
          final wordsToShow = namedArgs['wordsToShow'] as String? ?? '';
          return ASimpleWidget(wordsToShow: wordsToShow);
        },
  },
);

const code = '''
import 'package:flutter/material.dart';
import 'package:example/flutter_d4rx_bridge.dart';

Widget build(BuildContext context) {
  return Column(
    children: [
      ASimpleWidget(wordsToShow: 'Hello from D4RT!'),
      SizedBox(height: 24),
      ASimpleWidget(wordsToShow: 'This is a bridged widget.'),
      SizedBox(height: 24),
      ASimpleWidget(wordsToShow: 'Enjoy dynamic Flutter!'),
      SizedBox(height: 24),
    ],
  );
}
''';

class FlutterD4rtCustomSimplePage extends StatefulWidget {
  const FlutterD4rtCustomSimplePage({super.key});

  @override
  State<FlutterD4rtCustomSimplePage> createState() =>
      _FlutterD4rtCustomSimplePageState();
}

class _FlutterD4rtCustomSimplePageState
    extends State<FlutterD4rtCustomSimplePage> {
  final FlutterRunInterpreter _interpreter = FlutterRunInterpreter();
  Widget? _interpretedWidget;

  @override
  void initState() {
    super.initState();
    _initializeAndExecute();
  }

  Future<void> _initializeAndExecute() async {
    try {
      _interpreter.initialize();

      _interpreter.registerBridgedClass(
        aSimpleWidgetBridge,
        // uri 参数可以自己定义，用于区分不同模块的桥接类:
        'package:example/flutter_d4rx_bridge.dart',
      );

      // 执行代码，返回一个 Widget，setState 更新 UI
      final result = await _interpreter.execute(code, 'build', args: [context]);

      setState(() {
        _interpretedWidget = result;
      });
    } catch (e) {
      print('Initialization Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter D4RT Custom Simple Page')),
      body: Center(
        child: _interpretedWidget ?? Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
