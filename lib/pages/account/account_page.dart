import 'package:flutter/material.dart';

import '../../core/services/account_service.dart';
import '../../core/theme/app_theme.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    required this.service,
    required this.onAuthenticated,
    required this.hasLocalData,
    this.localName,
    this.initialError,
    this.onContinueLocally,
    this.onRetry,
  });

  final AccountService service;
  final ValueChanged<AccountUser> onAuthenticated;
  final bool hasLocalData;
  final String? localName;
  final String? initialError;
  final VoidCallback? onContinueLocally;
  final VoidCallback? onRetry;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = true;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.text = widget.localName ?? '';
    _error = widget.initialError;
  }

  @override
  void didUpdateWidget(covariant AccountPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialError != oldWidget.initialError) {
      _error = widget.initialError;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = _register
          ? await widget.service
              .register(_name.text, _email.text, _password.text)
          : await widget.service.login(_email.text, _password.text);
      if (mounted) widget.onAuthenticated(user);
    } on AccountException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Não foi possível concluir. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.service.isConfigured;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('METE MARCHA',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: AppColors.primaryLight)),
                    const SizedBox(height: 28),
                    Text(_register ? 'Crie sua conta' : 'Entre na sua conta',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                        widget.hasLocalData
                            ? 'Seus treinos neste aparelho continuam aqui. Ao entrar, eles não serão enviados automaticamente.'
                            : 'Registre seus treinos e participe dos Cohorts.',
                        style:
                            TextStyle(color: context.onSurface, height: 1.45)),
                    const SizedBox(height: 28),
                    if (_register) ...[
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(labelText: 'Nome'),
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Informe seu nome.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (v) => (v?.contains('@') ?? false)
                          ? null
                          : 'Informe um e-mail válido.',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: !_showPassword,
                      autofillHints: [
                        if (_register)
                          AutofillHints.newPassword
                        else
                          AutofillHints.password
                      ],
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        suffixIcon: IconButton(
                          tooltip:
                              _showPassword ? 'Ocultar senha' : 'Mostrar senha',
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icon(_showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                        ),
                      ),
                      validator: (v) => (v?.length ?? 0) < 8
                          ? 'Use pelo menos 8 caracteres.'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 18),
                      Text(_error!,
                          style:
                              const TextStyle(color: AppColors.primaryLight)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: !enabled || _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_register ? 'Criar conta' : 'Entrar'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _register = !_register;
                                _error = null;
                              }),
                      child: Text(
                          _register ? 'Já tenho conta' : 'Criar uma conta'),
                    ),
                    if (!enabled) ...[
                      const SizedBox(height: 12),
                      Text('O servidor ainda não foi configurado nesta versão.',
                          style: TextStyle(color: context.onSurface)),
                    ],
                    if (widget.onRetry != null)
                      TextButton(
                          onPressed: widget.onRetry,
                          child: const Text('Tentar conexão novamente')),
                    if (widget.onContinueLocally != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                          onPressed: widget.onContinueLocally,
                          child:
                              const Text('Continuar com meus treinos locais')),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
