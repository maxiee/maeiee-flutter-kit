const String flutterD4rxListView = '''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('ListView Example'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: ListView.builder(
          itemCount: 20,
          itemBuilder: (context, index) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: Text('\${index + 1}'),
              ),
              title: Text('Item \${index + 1}'),
              subtitle: Text('This is item number \${index + 1}'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Handle tap
              },
            );
          },
        ),
      ),
    );
  }
}
''';
