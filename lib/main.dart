import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'core/theme/app_theme.dart';
import 'core/providers/providers.dart';
import 'core/services/notification_service.dart';
import 'core/services/foreground_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/widgets/global_rest_timer_overlay.dart';
import 'pages/splash/splash_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late final ProviderContainer globalProviderContainer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  
  globalProviderContainer = ProviderContainer();

  // Inicializa o serviço de notificações, o foreground service e os links de widgets
  await NotificationService().init();
  ForegroundTaskService.init();
  DeepLinkService.init();

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
      child: Consumer(
        builder: (context, ref, child) {
          final themeMode = ref.watch(themeModeProvider);
          return MaterialApp(
            title: 'Mete Marcha',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
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
          );
        },
      ),
    );
  }
}
