import 'package:file_picker/file_picker.dart';
import '../../core/services/squad_invite_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'squad_editor.dart';
import 'workout_report.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/services/account_service.dart';
import '../../core/services/squad_service.dart';

class SquadsPage extends StatefulWidget {
  const SquadsPage({super.key});
  @override
  State<SquadsPage> createState() => _SquadsPageState();
}

class _SquadsPageState extends State<SquadsPage> {
  final api = SquadService();
  Map<String, dynamic>? group;
  List<dynamic> members = [], stories = [];
  Map<String, String> headers = {};
  String? error, cursor;
  bool loading = true, busy = false, canEdit = false;
  @override
  void initState() {
    super.initState();
    SquadInviteService.pending.addListener(inviteReceived);
    load().then((_) => inviteReceived());
  }

  bool inviteOpen = false;
  @override
  void dispose() {
    SquadInviteService.pending.removeListener(inviteReceived);
    super.dispose();
  }

  void inviteReceived() {
    if (SquadInviteService.pending.value == null || inviteOpen || !mounted)
      return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || inviteOpen) return;
      final code = SquadInviteService.pending.value;
      if (code == null) return;
      inviteOpen = true;
      final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Convite para um squad'),
                  content: const Text(
                      'Quer entrar no squad deste convite? Se você já participa de outro, será necessário sair dele primeiro.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Agora não')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Entrar no squad'))
                  ]));
      if (accepted == true && mounted)
        await action(() async {
          await api.request('POST', '/v1/groups/join', {'code': code});
          await SquadInviteService.clear();
          await load();
        });
      if (accepted == false) await SquadInviteService.clear();
      inviteOpen = false;
    });
  }

  void message(Object e) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      headers = await api.headers();
      final result = await api.request('GET', '/v1/groups/me');
      group = result['group'];
      canEdit = result['can_edit'] == true;
      members = result['members'] ?? [];
      final feed = await api.request('GET', '/v1/feed');
      stories = feed['stories'];
      cursor = feed['next_cursor'];
    } on AccountException catch (e) {
      if (e.code == 'not_in_group') {
        group = null;
        stories = [];
      } else {
        error = e.message;
      }
    } catch (_) {
      error = 'Não foi possível carregar os squads. Tente novamente.';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> action(Future<void> Function() task) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await task();
    } catch (e) {
      message(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> enter(bool create) async {
    if (create) {
      final style = await Navigator.push<Map<String, dynamic>>(
          context, MaterialPageRoute(builder: (_) => const SquadEditor()));
      if (style == null) return;
      await action(() async {
        await api.request('POST', '/v1/groups', {'name': style['name']});
        try {
          await api.request('PATCH', '/v1/groups/me', style);
        } finally {
          await load();
        }
      });
      return;
    }
    final controller = TextEditingController();
    final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(create ? 'Criar squad' : 'Entrar por convite'),
              content: TextField(
                  controller: controller,
                  maxLength: 300,
                  decoration: InputDecoration(
                      labelText:
                          create ? 'Nome do squad' : 'Código do convite')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty)
                        Navigator.pop(context, controller.text.trim());
                    },
                    child: const Text('Continuar'))
              ],
            ));
    if (value == null) return;
    await action(() async {
      await api.request('POST', create ? '/v1/groups' : '/v1/groups/join', {
        create ? 'name' : 'code':
            Uri.tryParse(value)?.queryParameters['code'] ?? value
      });
      await load();
    });
  }

  Future<void> invite() => action(() async {
        final result = await api.request('POST', '/v1/groups/me/invites');
        if (!mounted) return;
        final code = result['invite']['code'];
        await SharePlus.instance.share(ShareParams(
            text:
                'Bora treinar com a gente no ${group!['name']}! 💪\n${api.url('/invite').replace(queryParameters: {
                  'code': code
                })}\nToque no link para entrar no squad pelo Mete Marcha.\nSe precisar, entre por Squads → Tenho um convite e cole o código: $code\nO convite tem prazo e vale para uma pessoa.',
            subject: 'Convite para ${group!['name']}'));
      });
  Future<void> compose() async {
    final posted = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => StoryComposer(api: api)));
    if (posted == true) await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Squads'), actions: [
          IconButton(
              onPressed: loading ? null : load,
              tooltip: 'Atualizar',
              icon: const Icon(Icons.refresh))
        ]),
        floatingActionButton: group == null || loading
            ? null
            : FloatingActionButton.extended(
                onPressed: busy ? null : compose,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Story')),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                        padding: const EdgeInsets.all(24), child: Text(error!)),
                    FilledButton(
                        onPressed: load, child: const Text('Tentar novamente'))
                  ]))
                : group == null
                    ? Center(
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Seu treino, em boa companhia.',
                                      style: TextStyle(fontSize: 24)),
                                  const SizedBox(height: 12),
                                  const Text(
                                      'Crie um squad de até dez pessoas ou entre com um convite.'),
                                  const SizedBox(height: 24),
                                  FilledButton(
                                      onPressed:
                                          busy ? null : () => enter(true),
                                      child: const Text('Criar squad')),
                                  TextButton(
                                      onPressed:
                                          busy ? null : () => enter(false),
                                      child: const Text('Tenho um convite'))
                                ])))
                    : RefreshIndicator(
                        onRefresh: load,
                        child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            children: [
                              Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                      color: Color(int.parse(
                                                  (group!['color'] ?? '#7C6EF6')
                                                      .substring(1),
                                                  radix: 16) |
                                              0xff000000)
                                          .withValues(
                                              alpha: group!['theme'] == 'energy'
                                                  ? .32
                                                  : group!['theme'] == 'calm'
                                                      ? .08
                                                      : .16),
                                      borderRadius: BorderRadius.circular(24)),
                                  child: Column(children: [
                                    CircleAvatar(
                                        radius: 40,
                                        backgroundImage: (group!['avatar'] ??
                                                    '')
                                                .isEmpty
                                            ? null
                                            : MemoryImage(
                                                base64Decode(group!['avatar'])),
                                        child: (group!['avatar'] ?? '').isEmpty
                                            ? Text(
                                                (group!['name'] as String)
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                    fontSize: 32))
                                            : null),
                                    const SizedBox(height: 12),
                                    Text(group!['name'],
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium),
                                    TextButton.icon(
                                        icon: const Icon(Icons.people_outline),
                                        label: Text(
                                            '${members.length} de ${group!['max_members'] ?? 10} membros · ver todos'),
                                        onPressed: () => showModalBottomSheet<
                                                void>(
                                            context: context,
                                            isScrollControlled: true,
                                            showDragHandle: true,
                                            builder: (context) =>
                                                DraggableScrollableSheet(
                                                    expand: false,
                                                    initialChildSize: .5,
                                                    minChildSize: .3,
                                                    maxChildSize: .9,
                                                    builder: (context,
                                                            controller) =>
                                                        ListView(
                                                            controller:
                                                                controller,
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(20),
                                                            children: [
                                                              Text(
                                                                  'Quem treina junto',
                                                                  style: Theme.of(
                                                                          context)
                                                                      .textTheme
                                                                      .headlineSmall),
                                                              for (final m
                                                                  in members)
                                                                ListTile(
                                                                    leading: CircleAvatar(
                                                                        child: Text((m['display_name'] as String).substring(
                                                                            0,
                                                                            1))),
                                                                    title: Text(m[
                                                                        'display_name']),
                                                                    subtitle: Text(m['role'] ==
                                                                            'owner'
                                                                        ? 'Administrador'
                                                                        : 'Membro'))
                                                            ])))),
                                    if (canEdit)
                                      TextButton.icon(
                                          icon: const Icon(Icons.edit_outlined),
                                          label:
                                              const Text('Personalizar squad'),
                                          onPressed: busy
                                              ? null
                                              : () async {
                                                  final style =
                                                      await Navigator.push<
                                                              Map<String,
                                                                  dynamic>>(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (_) =>
                                                                  SquadEditor(
                                                                      group:
                                                                          group)));
                                                  if (style != null)
                                                    await action(() async {
                                                      await api.request(
                                                          'PATCH',
                                                          '/v1/groups/me',
                                                          style);
                                                      await load();
                                                    });
                                                }),
                                  ])),
                              Wrap(spacing: 8, children: [
                                TextButton(
                                    onPressed: busy ? null : invite,
                                    child: const Text('Convidar')),
                                TextButton(
                                    onPressed: busy
                                        ? null
                                        : () async {
                                            final leave = await showDialog<
                                                    bool>(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                        title: const Text(
                                                            'Sair do squad?'),
                                                        content: const Text(
                                                            'Você perderá o acesso às publicações deste squad.'),
                                                        actions: [
                                                          TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      false),
                                                              child: const Text(
                                                                  'Cancelar')),
                                                          TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      true),
                                                              child: const Text(
                                                                  'Sair'))
                                                        ]));
                                            if (leave == true)
                                              await action(() async {
                                                await api.request('POST',
                                                    '/v1/groups/me/leave');
                                                await load();
                                              });
                                          },
                                    child: const Text('Sair'))
                              ]),
                              const Text('Stories · disponíveis por 24 horas'),
                              const SizedBox(height: 16),
                              if (stories.isNotEmpty)
                                SizedBox(
                                    height: 92,
                                    child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        children: [
                                          for (final id in stories
                                              .map((s) => s['author']['id'])
                                              .toSet())
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 16),
                                                child: InkWell(
                                                    onTap: () => Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (_) => _Viewer(
                                                                api: api,
                                                                stories: stories
                                                                    .where((s) =>
                                                                        s['author']
                                                                            [
                                                                            'id'] ==
                                                                        id)
                                                                    .toList(),
                                                                headers:
                                                                    headers))),
                                                    child: Column(children: [
                                                      CircleAvatar(
                                                          radius: 28,
                                                          backgroundImage: NetworkImage(
                                                              api
                                                                  .url(stories.firstWhere((s) =>
                                                                      s['author']
                                                                          [
                                                                          'id'] ==
                                                                      id)['photo_url'])
                                                                  .toString(),
                                                              headers: headers)),
                                                      Text(stories.firstWhere(
                                                              (s) =>
                                                                  s['author']
                                                                      ['id'] ==
                                                                  id)['author']
                                                          ['display_name'])
                                                    ])))
                                        ])),
                              if (stories.isEmpty)
                                const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 48),
                                    child: Text(
                                        'Nenhum story por enquanto. Compartilhe seu primeiro treino.')),
                              for (final story in stories)
                                _StoryCard(
                                    api: api, story: story, headers: headers),
                              if (cursor != null)
                                TextButton(
                                    onPressed: busy
                                        ? null
                                        : () => action(() async {
                                              final result = await api.request(
                                                  'GET',
                                                  '/v1/feed?before=$cursor');
                                              if (mounted)
                                                setState(() {
                                                  stories.addAll(
                                                      result['stories']);
                                                  cursor =
                                                      result['next_cursor'];
                                                });
                                            }),
                                    child: const Text('Carregar mais')),
                            ])),
      );
}

class _StoryCard extends StatefulWidget {
  const _StoryCard(
      {required this.api, required this.story, required this.headers});
  final SquadService api;
  final dynamic story;
  final Map<String, String> headers;
  @override
  State<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<_StoryCard> {
  final player = AudioPlayer();
  Timer? stopTimer;
  bool busy = false, playing = false;
  @override
  void dispose() {
    stopTimer?.cancel();
    player.dispose();
    super.dispose();
  }

  Future<void> music() async {
    try {
      if (playing) {
        await player.stop();
      } else {
        final track = widget.story['track'];
        final audio = await widget.api.client
            .get(widget.api.url(track['audio_url']), headers: widget.headers)
            .timeout(const Duration(seconds: 30));
        if (audio.statusCode != 200) throw Exception('Áudio indisponível');
        await player.play(BytesSource(audio.bodyBytes),
            position: Duration(milliseconds: track['start_ms']));
        stopTimer?.cancel();
        stopTimer =
            Timer(Duration(milliseconds: track['duration_ms']), () async {
          await player.stop();
          if (mounted) setState(() => playing = false);
        });
      }
      if (mounted) setState(() => playing = !playing);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível reproduzir a música.')));
    }
  }

  Future<void> react(String kind) async {
    setState(() => busy = true);
    try {
      final mine = widget.story['reactions']['mine'];
      final result = await widget.api.request(
          mine == kind ? 'DELETE' : 'PUT',
          '/v1/stories/${widget.story['id']}/reaction',
          mine == kind ? null : {'kind': kind});
      if (mounted)
        setState(() => widget.story['reactions'] = result['reactions']);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.story;
    return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s['author']['display_name']),
              subtitle: Text(
                  'Até ${DateTime.parse(s['visible_until']).toLocal().toString().substring(0, 16)}')),
          InkWell(
              onTap: s['workout_report'] == null
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => WorkoutReportPage(
                              report: Map<String, dynamic>.from(
                                  s['workout_report'])))),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.network(
                          widget.api.url(s['photo_url']).toString(),
                          headers: widget.headers,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                              child: Text('Foto indisponível')))))),
          if (s['workout_report'] != null)
            TextButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => WorkoutReportPage(
                            report: Map<String, dynamic>.from(
                                s['workout_report'])))),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Ver treino completo')),
          if ((s['caption'] as String).isNotEmpty)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(s['caption'])),
          if (s['track'] != null)
            TextButton.icon(
                onPressed: music,
                icon: Icon(playing ? Icons.stop : Icons.play_arrow),
                label:
                    Text('${s['track']['title']} · ${s['track']['artist']}')),
          Wrap(children: [
            for (final entry in {
              'fire': '🔥',
              'muscle': '💪',
              'clap': '👏',
              'heart': '❤️'
            }.entries)
              Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                      selected: s['reactions']['mine'] == entry.key,
                      onSelected: busy ? null : (_) => react(entry.key),
                      label: Text(
                          '${entry.value} ${s['reactions']['counts'][entry.key] ?? 0}')))
          ]),
        ]));
  }
}

class _Viewer extends StatelessWidget {
  const _Viewer(
      {required this.api, required this.stories, required this.headers});
  final SquadService api;
  final List<dynamic> stories;
  final Map<String, String> headers;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Stories')),
      body: PageView(children: [
        for (final story in stories)
          SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _StoryCard(api: api, story: story, headers: headers))
      ]));
}

class StoryComposer extends StatefulWidget {
  const StoryComposer(
      {super.key, required this.api, this.initialPhoto, this.report});
  final XFile? initialPhoto;
  final Map<String, dynamic>? report;
  final SquadService api;
  @override
  State<StoryComposer> createState() => StoryComposerState();
}

class StoryComposerState extends State<StoryComposer> {
  final caption = TextEditingController();
  final keyValue = 'story-${DateTime.now().microsecondsSinceEpoch}';
  XFile? photo;
  List<dynamic> tracks = [];
  Map<String, dynamic>? track;
  bool busy = false;
  String? catalogError;
  @override
  void initState() {
    super.initState();
    photo = widget.initialPhoto;
    catalog();
  }

  Future<void> catalog() async {
    try {
      final result = await widget.api.request('GET', '/v1/tracks');
      if (mounted)
        setState(() {
          tracks = result['tracks'] ?? [];
          catalogError = null;
        });
    } catch (_) {
      if (mounted)
        setState(() => catalogError = 'Não foi possível carregar o catálogo.');
    }
  }

  @override
  void dispose() {
    caption.dispose();
    super.dispose();
  }

  Future<void> pick(ImageSource source) async {
    try {
      final selected = await ImagePicker()
          .pickImage(source: source, maxWidth: 1920, imageQuality: 85);
      if (selected != null && mounted) setState(() => photo = selected);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Não foi possível abrir a câmera ou galeria.')));
    }
  }

  Future<void> localAudio() async {
    try {
      final picked = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['mp3', 'm4a', 'ogg', 'wav'],
          withData: true);
      if (picked == null || !mounted) return;
      final file = picked.files.single;
      if (file.size > 15 * 1024 * 1024)
        throw const AccountException('Escolha um áudio de até 15 MB.');
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Áudio do celular'),
                  content: Text(
                      'Usar “${file.name}” neste story? Escolha apenas músicas de licença aberta ou de sua autoria. O arquivo ficará disponível para você e para quem puder ver o story.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Usar este áudio'))
                  ]));
      if (confirmed != true || !mounted) return;
      setState(() => busy = true);
      final selected = await widget.api
          .uploadAudio(XFile.fromData(file.bytes!, name: file.name));
      if (mounted)
        setState(() {
          tracks.removeWhere((t) => t['id'] == selected['id']);
          tracks.add(selected);
          track = selected;
        });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> chooseMusic() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _MusicPicker(tracks: tracks, api: widget.api));
    if (selected != null && mounted)
      setState(() => track = selected.isEmpty ? null : selected);
  }

  Future<void> publish() async {
    setState(() => busy = true);
    try {
      await widget.api.publish(photo!, caption.text.trim(), track, keyValue,
          report: widget.report);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !busy,
      child: Scaffold(
          appBar: AppBar(title: const Text('Publicar story')),
          body: ListView(padding: const EdgeInsets.all(20), children: [
            Text('Um momento do seu treino.',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
                'Foto, legenda e uma música para acompanhar. Disponível no squad por 24 horas.'),
            const SizedBox(height: 24),
            Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                child: Column(children: [
                  ListTile(
                      enabled: !busy,
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(Icons.camera_alt_outlined),
                      title: const Text('Registrar agora'),
                      subtitle: const Text('Abra a câmera e capture o treino'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => pick(ImageSource.camera)),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                      enabled: !busy,
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(Icons.photo_library_outlined),
                      title: const Text('Escolher da galeria'),
                      subtitle: const Text('Use uma foto que você já tirou'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => pick(ImageSource.gallery)),
                ])),
            if (widget.report != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: const Text('Relatório completo anexado'),
                subtitle: const Text(
                    'O squad poderá ver suas séries, cargas e observações. Toque para revisar.'),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            WorkoutReportPage(report: widget.report!))),
              ),
            if (photo != null)
              FutureBuilder(
                  future: photo!.readAsBytes(),
                  builder: (context, snapshot) => snapshot.hasData
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Image.memory(snapshot.data!,
                              height: 260, fit: BoxFit.contain))
                      : const LinearProgressIndicator()),
            TextField(
                controller: caption,
                enabled: !busy,
                maxLength: 300,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Legenda')),
            const SizedBox(height: 20),
            ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.music_note_outlined),
                title:
                    Text(track == null ? 'Escolher música' : track!['title']),
                subtitle: Text(track == null
                    ? 'Catálogo aberto ou áudios já enviados'
                    : track!['artist']),
                trailing: const Icon(Icons.chevron_right),
                onTap: busy ? null : chooseMusic),
            OutlinedButton.icon(
                onPressed: busy ? null : localAudio,
                icon: const Icon(Icons.audio_file_outlined),
                label: const Text('Escolher áudio do celular')),
            if (tracks.isEmpty && catalogError == null)
              const Text('O catálogo ainda não tem músicas disponíveis.'),
            if (catalogError != null)
              TextButton(
                  onPressed: catalog,
                  child: Text('$catalogError Tentar novamente')),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: busy || photo == null ? null : publish,
                child: Text(busy ? 'Publicando…' : 'Publicar no squad')),
          ])));
}

class _MusicPicker extends StatefulWidget {
  const _MusicPicker({required this.tracks, required this.api});
  final List<dynamic> tracks;
  final SquadService api;
  @override
  State<_MusicPicker> createState() => _MusicPickerState();
}

class _MusicPickerState extends State<_MusicPicker> {
  String search = '';
  String? playing;
  String? loading;
  final player = AudioPlayer();
  Timer? timer;
  int sequence = 0;
  @override
  void dispose() {
    sequence++;
    timer?.cancel();
    player.dispose();
    super.dispose();
  }

  Future<void> preview(dynamic track) async {
    final current = ++sequence;
    try {
      timer?.cancel();
      await player.stop();
      if (playing == track['id']) {
        if (mounted) setState(() => playing = null);
        return;
      }
      setState(() {
        playing = null;
        loading = track['id'];
      });
      final response = await widget.api.client
          .get(widget.api.url(track['audio_url']),
              headers: await widget.api.headers())
          .timeout(const Duration(seconds: 30));
      if (!mounted || current != sequence) return;
      if (response.statusCode != 200) throw Exception('Áudio indisponível');
      await player.play(BytesSource(response.bodyBytes));
      if (!mounted || current != sequence) return;
      setState(() {
        playing = track['id'];
        loading = null;
      });
      timer = Timer(const Duration(seconds: 15), () async {
        await player.stop();
        if (mounted) setState(() => playing = null);
      });
    } catch (_) {
      if (mounted && current == sequence) {
        setState(() => loading = null);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível tocar a prévia.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .8,
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                    decoration: const InputDecoration(
                        labelText: 'Buscar título ou artista',
                        prefixIcon: Icon(Icons.search)),
                    onChanged: (v) =>
                        setState(() => search = v.toLowerCase()))),
            ListTile(
                title: const Text('Sem música'),
                onTap: () => Navigator.pop(context, <String, dynamic>{})),
            Expanded(
                child: ListView(children: [
              for (final t in widget.tracks.where((t) =>
                  ('${t['title']} ${t['artist']}')
                      .toLowerCase()
                      .contains(search)))
                ListTile(
                    title: Text(t['title']),
                    subtitle: Text(t['artist']),
                    onTap: () =>
                        Navigator.pop(context, Map<String, dynamic>.from(t)),
                    trailing: IconButton(
                        tooltip: 'Ouvir prévia',
                        onPressed: () => preview(t),
                        icon: loading == t['id']
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Icon(playing == t['id']
                                ? Icons.stop
                                : Icons.play_arrow))),
              if (widget.tracks.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                        'Ainda não há faixas no catálogo. Você pode escolher um áudio do celular.'))
            ])),
          ])));
}
