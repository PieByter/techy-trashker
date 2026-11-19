import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techy_trashker/app.dart';

void main() {
  testWidgets('app starts on the onboarding screen', (tester) async {
    await tester.pumpWidget(const TechyTrashkerApp());
    await tester.pumpAndSettle();

    expect(find.text('Techy Trashker'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);
    expect(find.text('Sampah jadi\nberkah'), findsOneWidget);
  });

  testWidgets('skip onboarding opens the login screen', (tester) async {
    await tester.pumpWidget(const TechyTrashkerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke akunmu'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('login form validates before calling the backend', (
    tester,
  ) async {
    await tester.pumpWidget(const TechyTrashkerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();

    final loginButton = find.widgetWithText(FilledButton, 'Masuk');
    await tester.ensureVisible(loginButton);
    await tester.pumpAndSettle();
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text('Email tidak boleh kosong'), findsOneWidget);
    expect(find.text('Masuk ke akunmu'), findsOneWidget);
    expect(find.text('Hot News'), findsNothing);
  });
}
