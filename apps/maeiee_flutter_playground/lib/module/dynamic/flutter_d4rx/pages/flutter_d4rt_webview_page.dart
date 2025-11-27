import 'package:d4rt/d4rt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_d4rt/flutter_d4rt.dart';
import 'package:webview_flutter/webview_flutter.dart';

final webviewControllerBridge = BridgedClass(
  nativeType: WebViewController,
  name: 'WebViewController',
  constructors: {
    '':
        (
          InterpreterVisitor visitor,
          List<Object?> positionalArgs,
          Map<String, Object?> namedArgs,
        ) {
          final controller = WebViewController();
          // 启用 JavaScript，否则很多网页会显示白屏
          controller.setJavaScriptMode(JavaScriptMode.unrestricted);
          return controller;
        },
  },
  methods: {
    'loadRequest':
        (
          InterpreterVisitor visitor,
          Object target,
          List<Object?> positionalArgs,
          Map<String, Object?> namedArgs,
        ) async {
          if (target is! WebViewController) {
            throw TypeError();
          }
          final uri = positionalArgs[0] as Uri;
          print('Bridged loadRequest called with uri: $uri');
          await target.loadRequest(uri);
          return null;
        },
  },
);

final webViewWidgetBridge = BridgedClass(
  nativeType: WebViewWidget,
  name: 'WebViewWidget',
  constructors: {
    '':
        (
          InterpreterVisitor visitor,
          List<Object?> positionalArgs,
          Map<String, Object?> namedArgs,
        ) {
          WebViewController? controller =
              namedArgs['controller'] as WebViewController?;
          if (controller == null) {
            throw ArgumentError('controller is required for WebViewWidget');
          }
          return WebViewWidget(controller: controller);
        },
  },
);

const code = '''
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DynamicWebViewPage extends StatefulWidget {
  @override
  _DynamicWebViewPageState createState() => _DynamicWebViewPageState();
}

class _DynamicWebViewPageState extends State<DynamicWebViewPage> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    _controller.loadRequest(Uri.parse('https://baidu.com'));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
''';

class FlutterD4rtWebviewPage extends StatefulWidget {
  const FlutterD4rtWebviewPage({super.key});

  @override
  State<FlutterD4rtWebviewPage> createState() => _FlutterD4rtWebviewPageState();
}

class _FlutterD4rtWebviewPageState extends State<FlutterD4rtWebviewPage> {
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
        webviewControllerBridge,
        // uri 参数可以自己定义，用于区分不同模块的桥接类:
        'package:webview_flutter/webview_flutter.dart',
      );
      _interpreter.registerBridgedClass(
        webViewWidgetBridge,
        // uri 参数可以自己定义，用于区分不同模块的桥接类:
        'package:webview_flutter/webview_flutter.dart',
      );

      // 执行代码，返回一个 Widget，setState 更新 UI
      final result = _interpreter.execute(code, 'DynamicWebViewPage');

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
      appBar: AppBar(title: const Text('D4RT WebView Example')),
      body: Center(
        child: _interpretedWidget ?? Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
