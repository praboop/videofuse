import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:videofuse/main.dart';

void main() {
  testWidgets('home shows the two MVP utilities', (tester) async {
    await tester.pumpWidget(const VideoFuseApp());

    expect(find.text('VideoFuse'), findsAtLeastNWidgets(1));
    expect(find.text('Extract a frame'), findsOneWidget);
    expect(find.text('Stitch videos'), findsOneWidget);
  });

  testWidgets('utility tiles open their setup screens', (tester) async {
    await tester.pumpWidget(const VideoFuseApp());

    await tester.tap(find.text('Extract a frame'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a video'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stitch videos'));
    await tester.pumpAndSettle();

    expect(find.text('Choose videos'), findsOneWidget);
  });
}
