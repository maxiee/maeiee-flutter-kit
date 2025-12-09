import 'package:flutter/material.dart';
import 'dart:developer' as dev;

class ItemextendOptimisePage extends StatefulWidget {
  const ItemextendOptimisePage({super.key});

  @override
  State<ItemextendOptimisePage> createState() => _ItemextendOptimisePageState();
}

class _ItemextendOptimisePageState extends State<ItemextendOptimisePage> {
  bool openItemExtendOptimise = true;
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Extend Optimise Page')),
      body: Column(
        children: [
          Text('ItemExtend = $openItemExtendOptimise'),
          Row(
            children: [
              Switch(
                value: openItemExtendOptimise,
                onChanged: (value) {
                  setState(() {
                    openItemExtendOptimise = value;
                  });
                },
              ),
              OutlinedButton(
                onPressed: () {
                  dev.Timeline.timeSync('scroll to 1000th then back', () async {
                    await scrollController.animateTo(
                      1000 * 100,
                      duration: const Duration(seconds: 3),
                      curve: Curves.easeInOut,
                    );
                    await scrollController.animateTo(
                      0,
                      duration: const Duration(seconds: 3),
                      curve: Curves.easeInOut,
                    );
                  });
                },
                child: Text('scroll to 1000th then back'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: 1000,
              itemExtent: openItemExtendOptimise ? 100 : null,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(child: Text('$index')),
                  title: Text('Item $index' * 3),
                  subtitle: Text('Some description $index ' * 4),
                  trailing: const Icon(Icons.chevron_right),
                );
                ;
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }
}
