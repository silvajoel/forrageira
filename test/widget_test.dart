import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forrageira/widgets/app_text_field.dart';

void main() {
  testWidgets('AppTextField displays the popular name label', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTextField(
            controller: controller,
            label: 'Nome popular',
            icon: Icons.grass,
          ),
        ),
      ),
    );

    expect(find.text('Nome popular'), findsOneWidget);
    expect(find.byIcon(Icons.grass), findsOneWidget);
  });
}
