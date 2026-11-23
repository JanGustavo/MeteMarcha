import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SquadEditor extends StatefulWidget {
  const SquadEditor({super.key, this.group});
  final Map<String, dynamic>? group;
  @override
  State<SquadEditor> createState() => _SquadEditorState();
}

class _SquadEditorState extends State<SquadEditor> {
  late final name = TextEditingController(text: widget.group?['name'] ?? '');
  late String color = widget.group?['color'] ?? '#7C6EF6';
  late String theme = widget.group?['theme'] ?? 'classic';
  late String avatar = widget.group?['avatar'] ?? '';
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> photo() async {
    try {
      final file = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 75);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 256 * 1024)
        throw Exception('Escolha uma foto menor que 256 KB.');
      if (mounted) setState(() => avatar = base64Encode(bytes));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(int.parse(color.substring(1), radix: 16) | 0xff000000);
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.group == null
                ? 'Seu novo squad'
                : 'Personalizar squad')),
        body: Form(
            key: form,
            child: ListView(padding: const EdgeInsets.all(24), children: [
              Text('Dê a cara do grupo.',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Nome, foto e estilo aparecem para todos os membros.'),
              const SizedBox(height: 28),
              Center(
                  child: InkWell(
                      onTap: photo,
                      borderRadius: BorderRadius.circular(60),
                      child: CircleAvatar(
                          radius: 52,
                          backgroundColor: accent,
                          backgroundImage: avatar.isEmpty
                              ? null
                              : MemoryImage(base64Decode(avatar)),
                          child: avatar.isEmpty
                              ? const Icon(Icons.add_a_photo_outlined,
                                  size: 32, color: Colors.white)
                              : null))),
              Center(
                  child: TextButton(
                      onPressed: photo,
                      child: const Text('Escolher foto do squad'))),
              if (avatar.isNotEmpty)
                Center(
                    child: TextButton(
                        onPressed: () => setState(() => avatar = ''),
                        child: const Text('Remover foto'))),
              TextFormField(
                  controller: name,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Nome do squad',
                      hintText: 'Ex.: Os Treinamole'),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Dê um nome ao squad'
                      : null),
              const SizedBox(height: 24),
              const Text('Cor do squad'),
              const SizedBox(height: 12),
              Wrap(spacing: 12, runSpacing: 12, children: [
                for (final c in [
                  '#7C6EF6',
                  '#E85954',
                  '#E5A83B',
                  '#279E83',
                  '#388BC9',
                  '#CC65A0'
                ])
                  Semantics(
                      label: 'Cor $c',
                      selected: color == c,
                      child: InkWell(
                          onTap: () => setState(() => color = c),
                          borderRadius: BorderRadius.circular(24),
                          child: CircleAvatar(
                              backgroundColor: Color(
                                  int.parse(c.substring(1), radix: 16) |
                                      0xff000000),
                              child: color == c
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : const SizedBox(width: 48, height: 48))))
              ]),
              const SizedBox(height: 28),
              const Text('Estilo do cabeçalho'),
              for (final t in {
                'classic': 'Clássico',
                'energy': 'Energia',
                'calm': 'Calmo'
              }.entries)
                RadioListTile<String>(
                    value: t.key,
                    groupValue: theme,
                    onChanged: (v) => setState(() => theme = v!),
                    title: Text(t.value)),
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: () {
                    if (form.currentState!.validate())
                      Navigator.pop(context, {
                        'name': name.text.trim(),
                        'color': color,
                        'theme': theme,
                        'avatar': avatar
                      });
                  },
                  child: Text(widget.group == null
                      ? 'Criar meu squad'
                      : 'Salvar alterações')),
            ])));
  }
}
