import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techy_trashker/app.dart';
import 'package:techy_trashker/core/widgets/app_bottom_nav.dart';

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

  testWidgets('login opens home and bottom navigation switches tabs', (
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

    expect(find.text('Hot News'), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);

    final historyTab = find.descendant(
      of: find.byType(AppBottomNav),
      matching: find.text('Riwayat'),
    );
    await tester.tap(historyTab);
    await tester.pumpAndSettle();

    expect(find.text('Total Poin'), findsOneWidget);
    expect(find.text('Mulai'), findsNothing);
  });
}
