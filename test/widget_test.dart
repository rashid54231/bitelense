import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitelens_app/core/widgets/empty_state.dart';
import 'package:bitelens_app/core/widgets/glass_card.dart';
import 'package:bitelens_app/core/widgets/macro_chip.dart';

void main() {
  testWidgets('EmptyState displays icon, title and description', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.dinner_dining_rounded,
            title: 'No meals logged yet',
            description: 'Snap your food to start tracking',
          ),
        ),
      ),
    );

    expect(find.text('No meals logged yet'), findsOneWidget);
    expect(find.text('Snap your food to start tracking'), findsOneWidget);
    expect(find.byIcon(Icons.dinner_dining_rounded), findsOneWidget);
  });

  testWidgets('MacroChip renders label and formatted grams', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MacroChip.protein(35.5),
        ),
      ),
    );

    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('35.5g'), findsOneWidget);
  });

  testWidgets('GlassCard renders child with border decoration', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            child: Text('Card Content'),
          ),
        ),
      ),
    );

    expect(find.text('Card Content'), findsOneWidget);
  });
}
