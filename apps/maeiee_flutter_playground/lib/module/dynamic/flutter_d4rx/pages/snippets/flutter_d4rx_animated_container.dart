const String flutterD4rxAnimatedContainer = '''
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Animated Container'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 500),
                width: _isExpanded ? 200 : 100,
                height: _isExpanded ? 200 : 100,
                decoration: BoxDecoration(
                  color: _isExpanded ? Colors.red : Colors.blue,
                  borderRadius: BorderRadius.circular(_isExpanded ? 50 : 10),
                ),
                child: Icon(
                  _isExpanded ? Icons.favorite : Icons.star,
                  color: Colors.white,
                  size: _isExpanded ? 50 : 30,
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Text(_isExpanded ? 'Shrink' : 'Expand'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
''';
