import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';
import '../theme/app_theme.dart';

class OtaUpdateService {
  static final OtaUpdateService _instance = OtaUpdateService._internal();
  factory OtaUpdateService() => _instance;
  OtaUpdateService._internal();

  bool _isChecking = false;

  /// Verifica se há atualizações no GitHub e mostra um diálogo se houver.
  Future<void> checkForUpdates(BuildContext context, {bool forceShowNoUpdate = false}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (_isChecking) return;
    _isChecking = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(Uri.parse('https://api.github.com/repos/JanGustavo/MeteMachaFit/releases/latest'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tagName = data['tag_name'] as String? ?? 'latest';
        
        String cleanLatestVersion = '0.0.0';
        
        // Se a tag for 'latest' (release automático do CI), extraímos a maior versão semver do nome dos arquivos apk nas assets
        if (tagName == 'latest') {
          final assets = data['assets'] as List<dynamic>? ?? [];
          final regex = RegExp(r'mete-marcha-v(\d+\.\d+\.\d+)');
          for (final asset in assets) {
            final assetName = asset['name'] as String? ?? '';
            final match = regex.firstMatch(assetName);
            if (match != null) {
              final versionStr = match.group(1)!;
              if (_isNewerVersion(cleanLatestVersion, versionStr)) {
                cleanLatestVersion = versionStr;
              }
            }
          }
        } else {
          cleanLatestVersion = tagName.replaceAll('v', '').trim();
        }

        if (_isNewerVersion(currentVersion, cleanLatestVersion)) {
          if (context.mounted) {
            _showUpdateDialog(context, cleanLatestVersion);
          }
        } else if (forceShowNoUpdate) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('O Mete Marcha já está na versão mais recente! ✓'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao verificar atualizações: $e');
      if (forceShowNoUpdate && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao verificar atualizações: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      _isChecking = false;
    }
  }

  /// Compara as versões semver simples (ex: 1.0.0 vs 1.1.0)
  bool _isNewerVersion(String current, String latest) {
    try {
      final currentClean = current.split('+')[0];
      final latestClean = latest.split('+')[0];
      
      final currentParts = currentClean.split('.').map(int.parse).toList();
      final latestParts = latestClean.split('.').map(int.parse).toList();
      
      for (int i = 0; i < min(currentParts.length, latestParts.length); i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return latestParts.length > currentParts.length;
    } catch (_) {
      return false;
    }
  }

  void _showUpdateDialog(BuildContext context, String latestVersion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.system_update_rounded, color: AppColors.primaryLight),
            SizedBox(width: 10),
            Text('Nova Versão!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Uma nova versão do Mete Marcha (v$latestVersion) está disponível. Deseja atualizar agora?',
          style: const TextStyle(color: AppColors.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mais Tarde', style: TextStyle(color: AppColors.onSurface)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startDownload(context, latestVersion);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Atualizar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _startDownload(BuildContext context, String latestVersion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return _DownloadProgressDialog(latestVersion: latestVersion);
      },
    );
  }
}

class _DownloadProgressDialog extends StatefulWidget {
  final String latestVersion;
  const _DownloadProgressDialog({required this.latestVersion});

  @override
  State<_DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  String _progress = '0';
  String _statusMessage = 'Iniciando download...';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _executeOtaUpdate();
  }

  void _executeOtaUpdate() {
    try {
      OtaUpdate()
          .execute(
        'https://github.com/JanGustavo/MeteMachaFit/releases/latest/download/mete-marcha.apk',
        destinationFilename: 'mete-marcha.apk',
      )
          .listen(
        (OtaEvent event) {
          setState(() {
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                _statusMessage = 'Baixando atualização...';
                _progress = event.value ?? '0';
                break;
              case OtaStatus.INSTALLING:
                _statusMessage = 'Iniciando instalação...';
                _progress = '100';
                break;
              case OtaStatus.INSTALLATION_DONE:
                _statusMessage = 'Instalação concluída.';
                break;
              case OtaStatus.CANCELED:
                _statusMessage = 'Download cancelado.';
                break;
              default:
                _isError = true;
                _statusMessage = 'Erro no download. Verifique sua conexão.';
                break;
            }
          });

          if (event.status == OtaStatus.INSTALLING || event.status == OtaStatus.INSTALLATION_DONE) {
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) Navigator.pop(context);
            });
          }
        },
        onError: (err) {
          setState(() {
            _isError = true;
            _statusMessage = 'Erro: $err';
          });
        },
      );
    } catch (e) {
      setState(() {
        _isError = true;
        _statusMessage = 'Exceção: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double percent = double.tryParse(_progress) ?? 0.0;
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Baixando Atualização', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          if (!_isError) ...[
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 6,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                  ),
                ),
                Text(
                  '${percent.toInt()}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          Text(_statusMessage, style: const TextStyle(color: AppColors.onSurface, fontSize: 14)),
        ],
      ),
      actions: _isError
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar', style: TextStyle(color: AppColors.primaryLight)),
              ),
            ]
          : [],
    );
  }
}
