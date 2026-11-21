import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool loading = true, busy = false;
  @override
  void initState() {
    super.initState();
    load();
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
    final controller = TextEditingController();
    final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(create ? 'Criar squad' : 'Entrar por convite'),
              content: TextField(
                  controller: controller,
                  maxLength: create ? 80 : 100,
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
      await api.request('POST', create ? '/v1/groups' : '/v1/groups/join',
          {create ? 'name' : 'code': value});
      await load();
    });
  }

  Future<void> invite() => action(() async {
        final result = await api.request('POST', '/v1/groups/me/invites');
        if (!mounted) return;
        await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
                    title: const Text('Convide para o squad'),
                    content: SelectableText(result['invite']['code']),
                    actions: [
                      TextButton(
                          onPressed: () async {
                            await Clipboard.setData(
                                ClipboardData(text: result['invite']['code']));
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Copiar código'))
                    ]));
      });
  Future<void> compose() async {
    final posted = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => _Composer(api: api)));
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
                              Text(group!['name'],
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium),
                              Wrap(spacing: 8, children: [
                                TextButton(
                                    onPressed: () => showDialog<void>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                                title: const Text('Membros'),
                                                content:
                                                    Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                      for (final m in members)
                                                        ListTile(
                                                            title: Text(m[
                                                                'display_name']),
                                                            subtitle: Text(m[
                                                                        'role'] ==
                                                                    'owner'
                                                                ? 'Administrador'
                                                                : 'Membro'))
                                                    ]),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child:
                                                          const Text('Fechar'))
                                                ])),
                                    child: Text(
                                        '${members.length}/${group!['max_members'] ?? 10} membros')),
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
          ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(widget.api.url(s['photo_url']).toString(),
                  headers: widget.headers,
                  width: double.infinity,
                  height: 320,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                      height: 160,
                      child: Center(child: Text('Foto indisponível'))))),
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

class _Composer extends StatefulWidget {
  const _Composer({required this.api});
  final SquadService api;
  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
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

  Future<void> publish() async {
    setState(() => busy = true);
    try {
      await widget.api.publish(photo!, caption.text.trim(), track, keyValue);
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
            const Text(
                'Compartilhe um momento do treino. O story fica no squad por 24 horas.'),
            const SizedBox(height: 20),
            Wrap(spacing: 12, children: [
              OutlinedButton.icon(
                  onPressed: busy ? null : () => pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Câmera')),
              OutlinedButton.icon(
                  onPressed: busy ? null : () => pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeria'))
            ]),
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
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Legenda')),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
                initialValue: track?['id'],
                isExpanded: true,
                decoration:
                    const InputDecoration(labelText: 'Música (opcional)'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Sem música')),
                  for (final t in tracks)
                    DropdownMenuItem(
                        value: t['id'] as String,
                        child: Text('${t['title']} · ${t['artist']}',
                            overflow: TextOverflow.ellipsis))
                ],
                onChanged: busy
                    ? null
                    : (id) => setState(() => track = id == null || id.isEmpty
                        ? null
                        : Map<String, dynamic>.from(
                            tracks.firstWhere((t) => t['id'] == id)))),
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
