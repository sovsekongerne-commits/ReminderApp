import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_reminder/core/constants/app_strings.dart';
import 'package:location_reminder/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _startApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ProviderScope(child: LocationReminderApp()));
  await tester.pumpAndSettle();
}

Future<void> _createNote(WidgetTester tester, String title,
    {List<String> extraPlaces = const []}) async {
  await tester.tap(find.text(AppStrings.newReminder));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, title);
  await tester.pumpAndSettle();
  for (final p in extraPlaces) {
    final chip = find.textContaining(p).last;
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }
  final save = find.text(AppStrings.saveReminder);
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Forsiden viser hilsen, steder nederst og tom tilstand',
      (tester) async {
    await _startApp(tester);

    expect(
      find.textContaining(RegExp('Godmorgen|Goddag|Godaften|Godnat')),
      findsOneWidget,
    );
    expect(find.text('Hjem'), findsWidgets);
    expect(find.text('Arbejde'), findsWidgets);
    expect(find.byKey(const Key('add_place_button')), findsOneWidget);
    expect(find.text(AppStrings.noActiveReminders), findsOneWidget);
    expect(find.text(AppStrings.newReminder), findsOneWidget);
  });

  testWidgets('Opret en seddel – den vises under sit sted', (tester) async {
    await _startApp(tester);
    await _createNote(tester, 'Husk cykelhjelm');

    expect(find.text('Husk cykelhjelm'), findsOneWidget);
    expect(find.text('HJEM'), findsOneWidget);
  });

  testWidgets('Tilføj punkt direkte på kortet og kryds det af',
      (tester) async {
    await _startApp(tester);
    await _createNote(tester, 'Indkøb');

    final addField = find.widgetWithText(TextField, '+ Tilføj…');
    await tester.enterText(addField, 'Mælk');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Mælk'), findsOneWidget);
    expect(find.text('0 af 1'), findsOneWidget);

    await tester.tap(find.text('Mælk'));
    await tester.pumpAndSettle();
    // Sidste punkt krydset af → engangs-sedlen flyttes til udførte
    await _scrollTo(tester, find.textContaining('Udførte (1)'));
    expect(find.textContaining('Udførte (1)'), findsOneWidget);
  });

  testWidgets('Udført via cirklen flytter sedlen til udførte',
      (tester) async {
    await _startApp(tester);
    await _createNote(tester, 'Husk paraply');

    await tester.tap(find.byKey(const Key('completion_checkbox')).first);
    await tester.pumpAndSettle();

    expect(find.text('Husk paraply'), findsNothing);
    await _scrollTo(tester, find.textContaining('Udførte (1)'));
    expect(find.textContaining('Udførte (1)'), findsOneWidget);
  });

  testWidgets('En seddel kan have flere steder', (tester) async {
    await _startApp(tester);
    await _createNote(tester, 'Pant flasker', extraPlaces: ['Arbejde']);

    // Under "Alle" står sedlen kun én gang, under et samlet afsnit
    expect(find.text('Pant flasker'), findsOneWidget);
    expect(find.text('HJEM · ARBEJDE'), findsOneWidget);

    // Vent til bekræftelsen nederst er væk, så stedvalget kan nås
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Vælger man ét sted, står der hvor den ellers hører til
    await tester.ensureVisible(find.text('Arbejde').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arbejde').first);
    await tester.pumpAndSettle();
    expect(find.text('Pant flasker'), findsOneWidget);
    expect(find.text('Også ved Hjem'), findsOneWidget);
  });

  testWidgets('Vejledningen laver en prøve-seddel', (tester) async {
    await _startApp(tester);

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nem vejledning'));
    await tester.pumpAndSettle();

    expect(find.text('Velkommen til din hjælper'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Næste trin 🌸'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Lav en nem prøve-påmindelse for mig 🌸'));
    await tester.pumpAndSettle();

    expect(find.text('Tag posten ind 📬'), findsOneWidget);
  });
}
