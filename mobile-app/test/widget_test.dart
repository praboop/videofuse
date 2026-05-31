import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:videofuse/main.dart';

void main() {
  testWidgets('home shows the two MVP utilities', (tester) async {
    await tester.pumpWidget(const VideoFuseApp());

    expect(find.text('VideoFuse'), findsOneWidget);
    expect(find.text('Extract Last Frame'), findsOneWidget);
    expect(find.text('Stitch Videos'), findsOneWidget);
  });

  testWidgets('utility tiles open their setup screens', (tester) async {
    await tester.pumpWidget(const VideoFuseApp());

    await tester.tap(find.text('Extract Last Frame'));
    await tester.pumpAndSettle();

    expect(find.text('Select Video'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stitch Videos'));
    await tester.pumpAndSettle();

    expect(find.text('Select Clips'), findsOneWidget);
  });
}
