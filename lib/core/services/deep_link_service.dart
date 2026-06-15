import 'package:home_widget/home_widget.dart';
import '../../main.dart';
import '../providers/providers.dart';
import '../providers/rest_timer_provider.dart';
import 'notification_service.dart';

class DeepLinkService {
  static void init() {
    // Escuta cliques enquanto o app está rodando
    HomeWidget.widgetClicked.listen((Uri? uri) {
      _handleUri(uri);
    });

    // Checa se o app foi aberto via clique no widget
    HomeWidget.initiallyLaunchedFromHomeWidget().then((Uri? uri) {
      _handleUri(uri);
    });
  }

  static void _handleUri(Uri? uri) {
    if (uri == null) return;
    if (uri.scheme == 'metemarcha' || uri.scheme == 'metemachafit') {
      if (uri.host == 'workout' || uri.path == 'workout') {
        final state = globalProviderContainer.read(restTimerProvider);
        if (state.dayId != null && state.sessionId != null) {
          NotificationService.openActiveWorkout();
        } else {
          globalProviderContainer.read(homeTabProvider.notifier).state = 0; // Aba de Treino
        }
      } else if (uri.host == 'streak' || uri.path == 'streak') {
        globalProviderContainer.read(homeTabProvider.notifier).state = 2; // Aba de Perfil
      }
    }
  }
}
