import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/services/account_service.dart';
import '../home/home_page.dart';
import 'account_page.dart';

class AccountGate extends ConsumerStatefulWidget {
  const AccountGate({super.key});

  @override
  ConsumerState<AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends ConsumerState<AccountGate> {
  final _service = AccountService();
  bool _loading = true;
  bool _hasLocalData = false;
  String? _localName;
  String? _error;
  AccountUser? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await ref.read(profileDaoProvider).getProfile();
      final splits = await ref.read(workoutDaoProvider).watchSplits().first;
      if (!mounted) return;
      setState(() {
        _hasLocalData = profile != null || splits.isNotEmpty;
        _localName = profile?.nome;
      });
      final user = await _service.restore();
      if (!mounted) return;
      setState(() {
        _user = user;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AccountException
            ? error.message
            : 'Não foi possível abrir a conta.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_user != null) return const HomePage();
    return AccountPage(
      hasLocalData: _hasLocalData,
      localName: _localName,
      initialError: _error,
      service: _service,
      onAuthenticated: (user) => setState(() => _user = user),
      onContinueLocally: _hasLocalData || apiBaseUrl.isEmpty
          ? () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomePage()),
              )
          : null,
      onRetry: _error == null
          ? null
          : () {
              setState(() => _loading = true);
              _load();
            },
    );
  }
}
