// Activity 05 widget tests. Each test drives the real CounterApp.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:icw5/main.dart';

// The large centered counter display (the increment field can hold the same
// digits, so a plain find.text would match both).
final Finder _counter = find.byWidgetPredicate(
    (w) => w is Text && w.textAlign == TextAlign.center && w.data != null);

Finder _counterText(int value) => find.byWidgetPredicate((w) =>
    w is Text && w.textAlign == TextAlign.center && w.data == '$value');

double _sliderValue(WidgetTester tester) =>
    tester.widget<Slider>(find.byType(Slider)).value;

Future<void> _setIncrement(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

Future<void> _tapText(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 750)); // SnackBar animates in
}

Finder _snackBarWith(String text) => find.descendant(
      of: find.byType(SnackBar),
      matching: find.textContaining(text),
    );

/// Presses the slider, moves the thumb until the live (previewed) value equals
/// [target], then releases so onChangeEnd fires exactly once.
Future<void> _dragSliderTo(WidgetTester tester, int target) async {
  final slider = find.byType(Slider);
  final gesture = await tester.startGesture(tester.getCenter(slider));
  await tester.pump();
  // Move past the drag slop so the horizontal drag is recognized.
  await gesture.moveBy(const Offset(-30, 0));
  await tester.pump();
  final double a = _sliderValue(tester);
  await gesture.moveBy(const Offset(-40, 0));
  await tester.pump();
  final double b = _sliderValue(tester);
  final double pxPerUnit = -40 / (b - a);

  for (var i = 0; i < 20; i++) {
    final double current = _sliderValue(tester);
    if (current.round() == target) break;
    await gesture.moveBy(Offset((target - current) * pxPerUnit, 0));
    await tester.pump();
  }
  expect(_sliderValue(tester).round(), target,
      reason: 'drag helper could not land on $target');
  await gesture.up();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 750));
}

void main() {
  testWidgets('1. Lower boundary: Decrease at 0 is rejected', (tester) async {
    await tester.pumpWidget(const CounterApp());

    await _tapText(tester, 'Decrease by 1');

    expect(_counterText(0), findsOneWidget);
    expect(find.text('History: none'), findsOneWidget);
    expect(
        _snackBarWith('Decrease by 1 blocked: already at the min of 0. '
            'You can Increase or move the slider.'),
        findsOneWidget);
  });

  testWidgets('2. Upper boundary: slider to 100, Increase by 1 is rejected',
      (tester) async {
    await tester.pumpWidget(const CounterApp());

    await _dragSliderTo(tester, 100);
    expect(_counterText(100), findsOneWidget);
    expect(find.text('History: 0'), findsOneWidget);

    await _tapText(tester, 'Increase by 1');

    expect(_counterText(100), findsOneWidget);
    expect(find.text('History: 0'), findsOneWidget);
    expect(
        _snackBarWith('Increase by 1 blocked: already at the max of 100. '
            'You can Decrease, Undo, or Reset.'),
        findsOneWidget);
  });

  testWidgets('3. Overshoot: 80 + 30 is rejected, history unchanged',
      (tester) async {
    await tester.pumpWidget(const CounterApp());

    await _setIncrement(tester, '80');
    await _tapText(tester, 'Increase by 80');
    expect(_counterText(80), findsOneWidget);
    expect(find.text('History: 0'), findsOneWidget);

    await _setIncrement(tester, '30');
    await _tapText(tester, 'Increase by 30');

    expect(_counterText(80), findsOneWidget);
    expect(find.text('History: 0'), findsOneWidget);
    expect(
        _snackBarWith('Increase by 30 blocked: 110 is above the max of 100. '
            'Still at 80. Use an increment of 20 or less.'),
        findsOneWidget);
  });

  testWidgets('4. Invalid input keeps the last valid increment (5)',
      (tester) async {
    await tester.pumpWidget(const CounterApp());
    await _setIncrement(tester, '5');
    expect(find.text('Increase by 5'), findsOneWidget);

    const expectedErrors = {
      '': 'Empty. Enter a whole number from 1 to 100. Still using 5.',
      '-2': 'Must be at least 1. Enter a whole number from 1 to 100. '
          'Still using 5.',
      '2.5': 'No decimals. Enter a whole number from 1 to 100. '
          'Still using 5.',
      'hello': '"hello" is not a number. Use digits only, 1 to 100. '
          'Still using 5.',
    };

    for (final entry in expectedErrors.entries) {
      await _setIncrement(tester, entry.key);
      final reason = 'input "${entry.key}"';
      expect(find.text(entry.value), findsOneWidget, reason: reason);
      expect(find.text('Increase by 5'), findsOneWidget, reason: reason);
      expect(_counterText(0), findsOneWidget, reason: reason);
      expect(find.text('History: none'), findsOneWidget, reason: reason);
    }

    // The kept increment is really used by the button.
    await _tapText(tester, 'Increase by 5');
    expect(_counterText(5), findsOneWidget);
  });

  testWidgets('5. Undo chain after buttons and slider: 10, 5, 0, 0',
      (tester) async {
    await tester.pumpWidget(const CounterApp());
    await _setIncrement(tester, '5');
    await _tapText(tester, 'Increase by 5');
    await _tapText(tester, 'Increase by 5');
    expect(_counterText(10), findsOneWidget);

    await _dragSliderTo(tester, 40);
    expect(_counterText(40), findsOneWidget);
    expect(find.text('History: 0, 5, 10'), findsOneWidget);

    const expectedHistory = [
      'History: 0, 5',
      'History: 0',
      'History: none',
      'History: none',
    ];
    final observed = <int>[];
    for (var i = 0; i < 4; i++) {
      await _tapText(tester, 'Undo');
      observed.add(int.parse(tester.widget<Text>(_counter).data!));
      expect(find.text(expectedHistory[i]), findsOneWidget,
          reason: 'after Undo ${i + 1}');
    }
    expect(observed, [10, 5, 0, 0]);
    expect(_snackBarWith('Nothing to undo. 0 is the earliest value.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('6. Slider drag = one history entry; Undo syncs slider',
      (tester) async {
    await tester.pumpWidget(const CounterApp());
    await _setIncrement(tester, '5');
    await _tapText(tester, 'Increase by 5');
    await _tapText(tester, 'Increase by 5');
    expect(_counterText(10), findsOneWidget);
    expect(find.text('History: 0, 5'), findsOneWidget);

    await _dragSliderTo(tester, 40);
    expect(_counterText(40), findsOneWidget);
    expect(find.text('History: 0, 5, 10'), findsOneWidget); // exactly one new

    await _tapText(tester, 'Undo');
    expect(_counterText(10), findsOneWidget);
    expect(_sliderValue(tester), 10.0);
    expect(find.text('History: 0, 5'), findsOneWidget); // 10 removed
  });

  testWidgets('7. Colors: red at 0, black at 30 and 50, green at 51',
      (tester) async {
    await tester.pumpWidget(const CounterApp());
    Color? colorOf(int v) => tester.widget<Text>(_counterText(v)).style?.color;

    expect(colorOf(0), Colors.red);

    await _setIncrement(tester, '30');
    await _tapText(tester, 'Increase by 30');
    expect(colorOf(30), Colors.black);

    await _setIncrement(tester, '20');
    await _tapText(tester, 'Increase by 20');
    expect(colorOf(50), Colors.black);

    await _setIncrement(tester, '1');
    await _tapText(tester, 'Increase by 1');
    expect(colorOf(51), Colors.green);
  });
}
