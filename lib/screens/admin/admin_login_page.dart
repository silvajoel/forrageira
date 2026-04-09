import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final _auth = AuthService();
  final _userService = UserService();

  bool loading = false;
  String? error;
  bool _redirecting = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (loading) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final email = emailCtrl.text.trim();
      final senha = passCtrl.text;

      if (email.isEmpty || senha.isEmpty) {
        setState(() {
          loading = false;
          error = 'Informe e-mail e senha.';
        });
        return;
      }

      final user = await _auth.login(email, senha);

      if (user == null) {
        if (!mounted) return;
        setState(() {
          loading = false;
          error = 'Falha no login.';
        });
        return;
      }

      final profile = await _userService.getProfile(user.uid);

      if (!mounted) return;

      if (profile == null) {
        await _auth.logout();
        setState(() {
          loading = false;
          error = 'Seu usuário foi autenticado, mas não possui cadastro no banco.';
        });
        return;
      }

      final role = (profile['role'] ?? '').toString().toLowerCase();
      final active = profile['active'] == true;

      if (!active) {
        await _auth.logout();
        if (!mounted) return;
        setState(() {
          loading = false;
          error = 'Conta desativada.';
        });
        return;
      }

      if (role != 'admin') {
        await _auth.logout();
        if (!mounted) return;
        setState(() {
          loading = false;
          error = 'Acesso negado. Essa conta não é administradora.';
        });
        return;
      }

      setState(() {
        loading = false;
        _redirecting = true;
      });

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/admin',
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String msg = 'Erro ao fazer login.';

      switch (e.code) {
        case 'user-not-found':
          msg = 'Usuário não encontrado.';
          break;
        case 'wrong-password':
          msg = 'Senha incorreta.';
          break;
        case 'invalid-email':
          msg = 'E-mail inválido.';
          break;
        case 'invalid-credential':
          msg = 'E-mail ou senha incorretos.';
          break;
        default:
          msg = 'Erro de autenticação.';
      }

      setState(() {
        loading = false;
        error = msg;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'Erro inesperado. Tente novamente.';
      });
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailCtrl = TextEditingController(text: emailCtrl.text.trim());
    bool sending = false;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Recuperar senha'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Informe seu e-mail para receber o link de recuperação.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: resetEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.mail_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      dialogError!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: sending
                      ? null
                      : () async {
                    final email = resetEmailCtrl.text.trim().toLowerCase();

                    if (email.isEmpty) {
                      setLocalState(() {
                        dialogError = 'Informe o e-mail.';
                      });
                      return;
                    }

                    setLocalState(() {
                      sending = true;
                      dialogError = null;
                    });

                    try {
                      final canReset = await _auth.canSendAdminResetPassword(email);

                      if (!canReset) {
                        setLocalState(() {
                          sending = false;
                          dialogError = 'Não existe conta administradora ativa com esse e-mail.';
                        });
                        return;
                      }

                      await _auth.sendPasswordResetForWeb(email);

                      if (!mounted) return;
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'O link de recuperação foi enviado para o e-mail informado.',
                          ),
                        ),
                      );
                    } on FirebaseAuthException catch (e) {
                      String msg = 'Erro ao enviar link de recuperação.';

                      switch (e.code) {
                        case 'invalid-email':
                          msg = 'E-mail inválido.';
                          break;
                        default:
                          msg = 'Não foi possível enviar o e-mail.';
                      }

                      setLocalState(() {
                        sending = false;
                        dialogError = msg;
                      });
                    } catch (_) {
                      setLocalState(() {
                        sending = false;
                        dialogError = 'Erro inesperado. Tente novamente.';
                      });
                    }
                  },
                  child: sending
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Enviar link'),
                ),
              ],
            );
          },
        );
      },
    );

    resetEmailCtrl.dispose();
  }

  Widget _buildLoginForm() {
    return Center(
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco, size: 44, color: Color(0xFF1F5B3F)),
            const SizedBox(height: 10),
            const Text(
              'Admin • Forrageira',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.mail_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                if (!loading) _login();
              },
            ),
            const SizedBox(height: 12),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F5B3F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: loading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Entrar'),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: loading ? null : _showForgotPasswordDialog,
              child: const Text(
                'Esqueci a senha',
                style: TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_redirecting) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F4F6),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF2F4F6),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF2F4F6),
            body: _buildLoginForm(),
          );
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: _userService.getProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFFF2F4F6),
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final profile = profileSnapshot.data;
            final isAdmin =
                (profile?['role'] ?? '').toString().toLowerCase() == 'admin';
            final isActive = profile?['active'] == true;

            if (profile != null && isAdmin && isActive) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _redirecting) return;

                setState(() => _redirecting = true);

                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/admin',
                      (route) => false,
                );
              });

              return const Scaffold(
                backgroundColor: Color(0xFFF2F4F6),
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profile == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted) return;
                await _auth.logout();
              });
            } else if (!isActive || !isAdmin) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted) return;
                await _auth.logout();
              });
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF2F4F6),
              body: _buildLoginForm(),
            );
          },
        );
      },
    );
  }
}