import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/widgets/global_rest_timer_overlay.dart';
import 'pages/splash/splash_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late final ProviderContainer globalProviderContainer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  globalProviderContainer = ProviderContainer();

  // Inicializa o serviço de notificações
  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final ProviderContainer? container;
  const MyApp({super.key, this.container});

  @override
  Widget build(BuildContext context) {
    ProviderContainer activeContainer;
    try {
      activeContainer = container ?? globalProviderContainer;
    } catch (_) {
      activeContainer = ProviderContainer();
    }

    return UncontrolledProviderScope(
      container: activeContainer,
      child: MaterialApp(
        title: 'MeteMacha',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        navigatorKey: navigatorKey,
        home: const SplashPage(),
        builder: (context, child) {
          return Stack(
            children: [
              if (child != null) child,
              const GlobalRestTimerOverlay(),
            ],
          );
        },
      ),
    );
  }
}
