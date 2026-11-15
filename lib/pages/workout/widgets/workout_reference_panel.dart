import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class WorkoutReferencePanel extends StatefulWidget {
  final Exercise exercise;
  final Function(String) onSaved;

  const WorkoutReferencePanel({
    super.key,
    required this.exercise,
    required this.onSaved,
  });

  @override
  State<WorkoutReferencePanel> createState() => _AddReferencePanelState();
}

class _AddReferencePanelState extends State<WorkoutReferencePanel>
    with WidgetsBindingObserver {
  final _linkController = TextEditingController();
  String? _detectedClipboardLink;
  bool _checkingClipboard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkClipboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    if (_checkingClipboard) return;
    if (!mounted) return;
    setState(() => _checkingClipboard = true);
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text != null &&
          (text.contains('youtube.com') ||
              text.contains('youtu.be') ||
              text.contains('tiktok.com'))) {
        if (mounted) {
          setState(() {
            _detectedClipboardLink = text.trim();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _detectedClipboardLink = null;
          });
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _checkingClipboard = false);
    }
  }

  void _searchYouTube() async {
    final query = 'como fazer ${widget.exercise.nome}';
    final url =
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}';
    final uri = Uri.parse(url);
    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o YouTube')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao abrir o YouTube: $e')));
      }
    }
  }

  void _searchTikTok() async {
    final query = 'como fazer ${widget.exercise.nome}';
    final appUrl = 'tiktok://search?keyword=${Uri.encodeComponent(query)}';
    final webUrl =
        'https://www.tiktok.com/search?q=${Uri.encodeComponent(query)}';

    // Tenta abrir direto no app do TikTok
    try {
      final success = await launchUrl(
        Uri.parse(appUrl),
        mode: LaunchMode.externalApplication,
      );
      if (success) return;
    } catch (_) {
      // Ignora erro e tenta o fallback web
    }

    // Fallback: abre no browser (ou no app caso o Android resolva o link HTTPS)
    try {
      final success = await launchUrl(
        Uri.parse(webUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o TikTok')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao abrir o TikTok: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Execução: ${widget.exercise.nome}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.onBackground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Busque a execução no YouTube ou TikTok. Ao copiar o link do vídeo e retornar para o app, você poderá colar e salvar o link abaixo como referência definitiva para este exercício.',
            style: TextStyle(fontSize: 13, color: context.onSurface),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _searchYouTube,
                  icon: const Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text('YouTube'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0000),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.white10, width: 1),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _searchTikTok,
                  icon: const Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text('TikTok'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF010101),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.white10, width: 1),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_detectedClipboardLink != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.content_paste_go_rounded,
                        color: AppColors.primaryLight,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Link detectado na Área de Transferência:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _detectedClipboardLink!,
                    style: TextStyle(fontSize: 12, color: context.onBackground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSaved(_detectedClipboardLink!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Usar Link Copiado & Salvar'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              labelText: 'Link de referência manual',
              hintText: 'https://www.youtube.com/watch?...',
              labelStyle: TextStyle(color: context.onSurface),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: context.divider),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.paste_rounded,
                  color: AppColors.primaryLight,
                ),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    _linkController.text = data!.text!.trim();
                  }
                },
              ),
            ),
            style: TextStyle(color: context.onBackground),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final link = _linkController.text.trim();
              if (link.isNotEmpty) {
                widget.onSaved(link);
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Salvar Referência'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
