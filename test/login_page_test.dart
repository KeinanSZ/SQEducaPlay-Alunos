import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqeducaplay/login_page.dart';

void main() {
  Future<void> pumpLoginPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(audience: LoginAudience.student),
      ),
    );
  }

  testWidgets('mostra aviso ao tentar entrar sem usuário', (tester) async {
    await pumpLoginPage(tester);

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Digite seu usuário para continuar.'), findsOneWidget);
  });

  testWidgets('mostra aviso ao tentar entrar sem senha', (tester) async {
    await pumpLoginPage(tester);

    final usernameField = find.byType(TextField).first;
    await tester.enterText(usernameField, 'aluno_teste');
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Digite sua senha para continuar.'), findsOneWidget);
  });
}
