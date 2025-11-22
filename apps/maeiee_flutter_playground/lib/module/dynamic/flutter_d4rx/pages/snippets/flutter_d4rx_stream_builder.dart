const String flutterD4rxStreamBuilder = '''
import 'package:flutter/material.dart';
import 'dart:async';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late StreamController<int> _streamController;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<int>();
    
    // Emit a new value every second
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_streamController.isClosed) {
        _streamController.add(_counter++);
      }
    });
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('StreamBuilder Example'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Real-time Counter:',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 16),
              StreamBuilder<int>(
                stream: _streamController.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Error: \${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    );
                  }
                  
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }
                  
                  return Text(
                    '\${snapshot.data}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
''';
