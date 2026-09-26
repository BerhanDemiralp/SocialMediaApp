import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moment_app/core/widgets/app_notice.dart';

void main() {
  testWidgets('notice allows taps through it and preserves input focus', (
    tester,
  ) async {
    late BuildContext pageContext;
    var taps = 0;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            pageContext = context;
            return Scaffold(
              body: Column(
                children: [
                  SizedBox(
                    height: 72,
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => taps++,
                      child: const Text('Underlying action'),
                    ),
                  ),
                  TextField(focusNode: focus),
                ],
              ),
            );
          },
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    showAppNotice(pageContext, 'Saved successfully');
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    final noticeCenter = tester.getCenter(find.text('Saved successfully'));
    expect(
      tester.getRect(find.byType(TextButton)).contains(noticeCenter),
      isTrue,
    );
    await tester.tapAt(noticeCenter);
    await tester.pump();
    expect(taps, 1);
    expect(find.text('Saved successfully'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Saved successfully'), findsNothing);
  });

  testWidgets('new feedback replaces the old message and resets expiry', (
    tester,
  ) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const Scaffold();
          },
        ),
      ),
    );
    showAppNotice(pageContext, 'First');
    await tester.pump(const Duration(seconds: 3));
    showAppNotice(pageContext, 'Latest');
    await tester.pump();
    expect(find.text('First'), findsNothing);
    expect(find.text('Latest'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Latest'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Latest'), findsNothing);
  });

  testWidgets('disposing the overlay cancels the notice timer', (tester) async {
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const Scaffold();
          },
        ),
      ),
    );
    showAppNotice(pageContext, 'Saved');
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
