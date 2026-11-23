import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/media/social_video.dart';

void main() {
  test('link do usuário abre o player oficial YouTube', () {
    final video = SocialVideo.parse('https://youtu.be/jNo3GqP-d4I');
    expect(video?.provider, 'YouTube');
    expect(video?.player.path, '/embed/jNo3GqP-d4I');
    expect(video?.player.queryParameters['controls'], '1');
  });
  test('normaliza TikTok e Instagram públicos', () {
    expect(
        SocialVideo.parse(
                'https://www.tiktok.com/@user/video/6718335390845095173')
            ?.player
            .path,
        '/player/v1/6718335390845095173');
    expect(
        SocialVideo.parse('https://www.instagram.com/reel/ABCxyz_123/')
            ?.player
            .path,
        '/reel/ABCxyz_123/embed/');
  });
  test('não incorpora HTML ou domínio semelhante', () {
    expect(SocialVideo.parse('javascript:alert(1)'), isNull);
    expect(
        SocialVideo.parse(
            'https://youtube.com.attacker.test/watch?v=jNo3GqP-d4I'),
        isNull);
    expect(
        SocialVideo.parse('https://user:pass@youtube.com/watch?v=jNo3GqP-d4I'),
        isNull);
  });
}
