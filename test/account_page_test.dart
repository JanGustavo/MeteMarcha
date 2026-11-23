import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/services/account_service.dart';
import 'package:gym_tracker/pages/account/account_page.dart';

class FakeAccountService extends AccountService {
  FakeAccountService() : super(baseUrl: 'https://example.com');

  @override
  Future<AccountUser> register(
          String name, String email, String password) async =>
      AccountUser(id: 'ana', name: name, email: email);

  @override
  Future<AccountUser> login(String email, String password) async =>
      AccountUser(id: 'ana', name: 'Ana', email: email);
}

void main() {
  testWidgets(
      'usuário antigo pode cadastrar sem perder o aviso do histórico local',
      (tester) async {
    AccountUser? signedIn;
    await tester.pumpWidget(MaterialApp(
      home: AccountPage(
        service: FakeAccountService(),
        hasLocalData: true,
        localName: 'Ana',
        onAuthenticated: (user) => signedIn = user,
      ),
    ));
    expect(find.textContaining('Seus treinos neste aparelho continuam aqui'),
        findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'E-mail'), 'ana@example.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Senha'), 'senha-segura');
    await tester.tap(find.text('Criar conta'));
    await tester.pump();
    expect(signedIn?.id, 'ana');
  });

  testWidgets('quem já tem conta pode escolher login', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AccountPage(
        service: FakeAccountService(),
        hasLocalData: true,
        onAuthenticated: (_) {},
      ),
    ));
    await tester.tap(find.text('Já tenho conta'));
    await tester.pump();
    expect(find.text('Entre na sua conta'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Nome'), findsNothing);
  });
}
