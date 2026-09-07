import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tara_travel/core/widgets/privacy_invite_code_widget.dart';

void main() {
  testWidgets('PrivacyInviteCodeWidget conceals by default and reveals on toggle', (tester) async {
    const code = 'ABC123';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PrivacyInviteCodeWidget(code: code),
        ),
      ),
    );

    // Initial state: masked with bullets and status badge PROTECTED
    expect(find.text('PROTECTED'), findsOneWidget);
    expect(find.text('••••••'), findsOneWidget);
    expect(find.text(code), findsNothing);

    // Tap code to reveal
    await tester.tap(find.text('••••••'));
    await tester.pumpAndSettle();

    // Revealed state: shows raw code and REVEALED badge
    expect(find.text('REVEALED'), findsOneWidget);
    expect(find.text(code), findsOneWidget);
  });
}
