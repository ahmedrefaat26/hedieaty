import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedieaty/EventcreationPage.dart';
import 'package:hedieaty/home_page.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hedieaty/main.dart'as app;
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
  });

  group("End-to-End Testing", () {
    testWidgets('SignUp', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify splash screen appears first
      await tester.pumpAndSettle();

      // Verify StartScreen
      expect(find.byKey(const Key('startScreen')), findsOneWidget);

      // Tap the Signup button on the start screen
      await tester.tap(find.byKey(const Key('SignupButton')));
      await tester.pumpAndSettle();

      // Verify signup page
      expect(find.byKey(const Key('SignupPage')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('Name')), 'cactus');
      await tester.enterText(find.byKey(const Key('Email')), 'cactus@gmail.com');
      await tester.enterText(find.byKey(const Key('Password')), '12345678');
      await tester.enterText(find.byKey(const Key('Confirm Password')), '12345678');

      await tester.tap(find.byKey(const Key('signupButton')));
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Check if HomePage is present
      expect(find.byType(HomePage), findsOneWidget);
      await tester.pumpAndSettle(Duration(seconds: 3));

      await tester.tap(find.byKey(const Key('myevent')));
      await tester.pumpAndSettle(Duration(seconds: 3));

      expect(find.byKey(const Key('eventpage')), findsOneWidget);
      await tester.pumpAndSettle(Duration(seconds: 3));

      await tester.tap(find.byKey(const Key('createevent')));
      await tester.pumpAndSettle(Duration(seconds: 3));


      await tester.enterText(find.byKey(const Key('name')), 'graduation');
      await tester.enterText(find.byKey(const Key('description')),'finals');

      final eventDateField = find.byKey(const Key('date'));
      await tester.tap(eventDateField);
      await tester.pumpAndSettle();

      // Open the Year Selector (if available)
      final openYearSelector = find.textContaining(RegExp(r'\d{4}')); // Matches any 4-digit year
      if (openYearSelector.evaluate().isNotEmpty) {
        await tester.tap(openYearSelector);
        await tester.pumpAndSettle();
      }

      // Scroll to the Desired Year and Select
      final date = find.byKey(const Key('date'));
      await tester.tap(eventDateField);
      await tester.pumpAndSettle();

      // Open the Year Selector (if available)
      if (openYearSelector.evaluate().isNotEmpty) {
        await tester.tap(openYearSelector);
        await tester.pumpAndSettle();
      }

      // Scroll to the Desired Year and Select
      final yearOption = find.text('2024');
      if (yearOption.evaluate().isNotEmpty) {
        await tester.tap(yearOption);
        await tester.pumpAndSettle();
      } else {
        throw TestFailure('The year 2024 was not found.');
      }

      final monthOption = find.text('DEC');
      if (monthOption.evaluate().isNotEmpty) {
        await tester.tap(monthOption);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('25'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('location')), 'abdobasha');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('createdevent')));
      await tester.pumpAndSettle();




    });
  });
}
