import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/media/social_video_card.dart';
import 'package:gym_tracker/core/media/embedded_video_native.dart';
import 'package:gym_tracker/core/services/squad_service.dart';
import 'package:gym_tracker/pages/squads/squads_page.dart';

void main() {
  testWidgets('vídeo ocupa a mídia do story sem repetir capa acima',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.physicalSize = const Size(390,844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: StoryViewer(api: SquadService(), headers: const {}, stories: [
      {
        'id': 'story-video',
        'author': {'display_name': 'Anderson'},
        'visible_until': '2026-11-23T12:00:00Z',
        'photo_url': '/cover-must-not-render.jpg',
        'caption': '',
        'video_url': 'https://youtu.be/jNo3GqP-d4I',
        'track': null,
        'workout_report': null,
        'reactions': {
          'mine': null,
          'counts': {'fire': 0, 'muscle': 0, 'clap': 0, 'heart': 0}
        },
      }
    ])));
    await tester.pumpAndSettle();
    expect(find.byType(SocialVideoCard), findsOneWidget);
    final images = tester.widgetList<Image>(find.byType(Image));
    expect(
        images.any((image) =>
            image.image is NetworkImage &&
            (image.image as NetworkImage)
                .url
                .contains('cover-must-not-render')),
        isFalse);
    expect(find.text('Assista ao vídeo compartilhado'), findsNothing);
    final button = find
        .descendant(
            of: find.byType(SocialVideoCard), matching: find.byType(InkWell))
        .first;
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(EmbeddedVideo), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
