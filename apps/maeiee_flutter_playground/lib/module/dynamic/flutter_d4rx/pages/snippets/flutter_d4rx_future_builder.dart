const String flutterD4rxFutureBuilder = '''
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late Future<String> _futureData;

  Future<String> _fetchData() async {
    // Simulate network delay
    await Future.delayed(Duration(seconds: 3));
    
    // Simulate random success/failure
    if (DateTime.now().millisecond % 2 == 0) {
      return 'Data loaded successfully!';
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    super.initState();
    _futureData = _fetchData();
  }

  void _refreshData() {
    setState(() {
      _futureData = _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('FutureBuilder Example'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder<String>(
                future: _futureData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading data...'),
                      ],
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'Error: \${snapshot.error}',
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  }
                  
                  return Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 64),
                      SizedBox(height: 16),
                      Text(
                        snapshot.data ?? 'No data',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _refreshData,
                child: Text('Refresh Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
''';
