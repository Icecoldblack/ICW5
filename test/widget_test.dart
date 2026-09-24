import 'package:flutter_test/flutter_test.dart';

import 'package:icw5/main.dart';

void main() {
  testWidgets('Counter increases and undo restores it', (tester) async {
    await tester.pumpWidget(const CounterApp());

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('Increase by 1'));
    await tester.pump();
    expect(find.text('History: 0'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
  });
}
