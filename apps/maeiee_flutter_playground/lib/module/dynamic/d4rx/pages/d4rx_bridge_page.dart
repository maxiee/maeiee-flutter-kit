import 'package:d4rt/d4rt.dart';
import 'package:flutter/material.dart';

enum Gender { male, female }

class People {
  People(this.name, this.gender);

  final String name;
  final Gender gender;

  String sayHello() {
    String ret = 'Hello, my name is $name, I am a ${gender.name}.';
    print(ret);
    return ret;
  }
}

final gendarEnumBridge = BridgedEnumDefinition<Gender>(
  name: 'Gender',
  values: Gender.values,
);

final peopleClassBridge = BridgedClass(
  nativeType: People,
  name: 'People',
  constructors: {
    '':
        (
          InterpreterVisitor visitor,
          List<Object?> positionalArgs,
          Map<String, Object?> namedArgs,
        ) {
          if (positionalArgs.length != 2) {
            throw ArgumentError(
              'Expected 2 positional arguments, got ${positionalArgs.length}',
            );
          }
          final name = positionalArgs[0] as String;
          final gender = positionalArgs[1] as Gender;
          return People(name, gender);
        },
  },
  getters: {
    'name': (InterpreterVisitor? visitor, Object target) {
      if (target is! People) {
        throw TypeError();
      }
      return target.name;
    },
    'gender': (InterpreterVisitor? visitor, Object target) {
      if (target is! People) {
        throw TypeError();
      }
      return target.gender;
    },
  },
  methods: {
    'sayHello':
        (
          InterpreterVisitor? visitor,
          Object target,
          List<Object?> positionalArgs,
          Map<String, Object?> namedArgs,
        ) {
          if (target is! People) {
            throw TypeError();
          }
          return target.sayHello();
        },
  },
);

class D4rxBridgePage extends StatelessWidget {
  const D4rxBridgePage({super.key});

  @override
  Widget build(BuildContext context) {
    final interpreter = D4rt();
    interpreter.registerBridgedClass(
      peopleClassBridge,
      'package:example/d4rx_bridge.dart',
    );
    interpreter.registerBridgedEnum(
      gendarEnumBridge,
      'package:example/d4rx_bridge.dart',
    );

    final code = '''
      import 'package:example/d4rx_bridge.dart';

      main() {
        var p = People("Maeiee", Gender.male);
        return p.sayHello();
      }
    ''';
    return Scaffold(
      appBar: AppBar(title: const Text('D4rx Bridge Example')),
      body: Center(child: Text(interpreter.execute(source: code).toString())),
    );
  }
}
