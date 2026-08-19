import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqeducaplay/topicos_page.dart';

void main() {
  testWidgets('exibe a trilha com etapas e tópico disponível', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: TopicosPage(
          ano: '2º Ano Fundamental',
          materia: 'Português',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Etapa 1'), findsOneWidget);
    expect(find.text('Disponível'), findsNWidgets(2));
  });
}
