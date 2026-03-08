import 'package:flutter/material.dart';

class LayoutBuilderPage extends StatelessWidget {
  final String title;

  LayoutBuilderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Simple responsive UI based on constraints width.
          if (constraints.maxWidth > 600) {
            return Center(child: Text('Large screen layout for $title'));
          } else {
            return Center(child: Text('Small screen layout for $title'));
          }
        },
      ),
    );
  }
}
