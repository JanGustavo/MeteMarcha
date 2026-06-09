class NotificationService {
  /// Solicita permissão para exibir notificações (stub para plataformas não-web)
  static void requestPermission() {}

  /// Exibe uma notificação nativa (stub para plataformas não-web)
  static void showNotification(String title, String body) {}

  Future<void> showMusicNotification(String channelName, bool isPlaying) async {}
  Future<void> cancelMusicNotification() async {}
}
