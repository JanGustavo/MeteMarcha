import 'package:flutter/material.dart';

import '../../../core/services/account_service.dart';
import '../../account/account_gate.dart';

class ProfileAccountCard extends StatefulWidget {
  const ProfileAccountCard({super.key});

  @override
  State<ProfileAccountCard> createState() => _ProfileAccountCardState();
}

class _ProfileAccountCardState extends State<ProfileAccountCard> {
  final _service = AccountService();
  late final Future<AccountUser?> _user = _service.restore();
  bool _busy = false;

  Future<void> _leave() async {
    setState(() => _busy = true);
    try {
      await _service.logout();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AccountGate()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível sair da conta. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AccountUser?>(
      future: _user,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CONTA', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(user == null
                    ? 'Treinos salvos neste aparelho'
                    : '${user.name} · ${user.email}'),
                const SizedBox(height: 8),
                const Text(
                    'O histórico local ainda não é sincronizado entre aparelhos.'),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator()
                else if (user == null)
                  TextButton(
                    onPressed: () => Navigator.of(context, rootNavigator: true)
                        .pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AccountGate()),
                      (_) => false,
                    ),
                    child: const Text('Entrar ou criar conta'),
                  )
                else
                  TextButton(
                    onPressed: _busy ? null : _leave,
                    child: const Text('Sair da conta'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
