import 'package:flutter/material.dart';
import 'package:gym_tracker/core/services/audio_service.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';

class ProfileAudioSettingsCard extends StatefulWidget {
  const ProfileAudioSettingsCard({super.key});

  @override
  State<ProfileAudioSettingsCard> createState() => _AudioSettingsCardState();
}

class _AudioSettingsCardState extends State<ProfileAudioSettingsCard> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = AudioService().clickSoundsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.divider.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    color: AppColors.primaryLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Efeitos Sonoros',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Configurações de som e feedback tátil do aplicativo',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Som de Clique nos Botões',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Tocar feedback sonoro nativo ao pressionar botões principais',
                style: TextStyle(fontSize: 12),
              ),
              value: _enabled,
              activeThumbColor: AppColors.primaryLight,
              onChanged: (val) async {
                setState(() {
                  _enabled = val;
                });
                await AudioService().setClickSoundsEnabled(val);
                if (val) {
                  await AudioService().playClick();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
