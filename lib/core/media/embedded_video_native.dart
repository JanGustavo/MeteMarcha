import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'social_video.dart';

class EmbeddedVideo extends StatefulWidget {
  const EmbeddedVideo({super.key, required this.video});
  final SocialVideo video;
  @override
  State<EmbeddedVideo> createState() => _EmbeddedVideoState();
}

class _EmbeddedVideoState extends State<EmbeddedVideo> {
  WebViewController? controller;
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    if (![TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS]
        .contains(defaultTargetPlatform)) {
      error = 'Abra o link original para assistir neste dispositivo.';
      return;
    }
    final c = WebViewController();
    controller = c;
    c.setJavaScriptMode(JavaScriptMode.unrestricted);
    c.setNavigationDelegate(NavigationDelegate(onPageFinished: (_) {
      if (mounted) setState(() => loading = false);
    }, onWebResourceError: (e) {
      if (e.isForMainFrame == true && mounted)
        setState(() =>
            error = 'Não foi possível carregar o vídeo. Use o link original.');
    }, onNavigationRequest: (request) {
      final uri = Uri.tryParse(request.url);
      return uri != null && ['https', 'about'].contains(uri.scheme)
          ? NavigationDecision.navigate
          : NavigationDecision.prevent;
    }));
    if (widget.video.isFrame) {
      final src = const HtmlEscape(HtmlEscapeMode.attribute)
          .convert(widget.video.player.toString());
      c.loadHtmlString(
          '<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body style="margin:0;background:#000"><iframe title="Vídeo de referência" src="$src" style="position:fixed;inset:0;width:100%;height:100%;border:0" allow="autoplay; encrypted-media; fullscreen; picture-in-picture" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe></body></html>',
          baseUrl: 'https://api.metemarcha.jangustavo.me/');
    } else {
      c.loadRequest(widget.video.player);
    }
  }

  @override
  Widget build(BuildContext context) => error != null
      ? Center(
          child:
              Padding(padding: const EdgeInsets.all(20), child: Text(error!)))
      : Stack(children: [
          if (controller != null) WebViewWidget(controller: controller!),
          if (loading)
            const Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator())
        ]);
}
