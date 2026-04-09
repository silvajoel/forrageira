import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _auth = AuthService();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool loading = false;
  bool validating = true;
  bool validCode = false;

  String? error;
  String? email;
  String? oobCode;

  @override
  void initState() {
    super.initState();
    _validateLink();
  }

  Future<void> _validateLink() async {
    try {
      final uri = Uri.base;
      final code = uri.queryParameters['oobCode'];

      if (code == null || code.isEmpty) {
        setState(() {
          validating = false;
          validCode = false;
          error = 'Link inválido ou expirado.';
        });
        return;
      }

      final linkedEmail = await _auth.verifyResetCode(code);

      setState(() {
        oobCode = code;
        email = linkedEmail;
        validating = false;
        validCode = true;
      });
    } on FirebaseAuthException {
      setState(() {
        validating = false;
        validCode = false;
        error = 'Este link é inválido ou já expirou.';
      });
    } catch (_) {
      setState(() {
        validating = false;
        validCode = false;
        error = 'Erro ao validar o link.';
      });
    }
  }

  Future<void> _submit() async {
    final newPass = newPassCtrl.text.trim();
    final confirmPass = confirmPassCtrl.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      setState(() {
        error = 'Preencha os dois campos de senha.';
      });
      return;
    }

    if (newPass.length < 6) {
      setState(() {
        error = 'A senha deve ter pelo menos 6 caracteres.';
      });
      return;
    }

    if (newPass != confirmPass) {
      setState(() {
        error = 'As senhas informadas não coincidem.';
      });
      return;
    }

    if (oobCode == null) {
      setState(() {
        error = 'Código inválido.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await _auth.confirmNewPassword(
        oobCode: oobCode!,
        newPassword: newPass,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Senha redefinida'),
          content: const Text(
            'Sua senha foi alterada com sucesso. Agora você já pode fazer login.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/admin-login',
                      (route) => false,
                );
              },
              child: const Text('Ir para login'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException {
      setState(() {
        loading = false;
        error = 'Não foi possível redefinir a senha. O link pode ter expirado.';
      });
    } catch (_) {
      setState(() {
        loading = false;
        error = 'Erro inesperado. Tente novamente.';
      });
    }
  }

  @override
  void dispose() {
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      body: Center(
        child: Container(
          width: 430,
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
          child: validating
              ? const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text('Validando link de recuperação...'),
            ],
          )
              : !validCode
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                error ?? 'Link inválido.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/admin-login',
                        (route) => false,
                  );
                },
                child: const Text('Voltar ao login'),
              ),
            ],
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_reset,
                size: 44,
                color: Color(0xFF1F5B3F),
              ),
              const SizedBox(height: 10),
              const Text(
                'Redefinir senha',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (email != null) ...[
                const SizedBox(height: 6),
                Text(
                  email!,
                  style: const TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 18),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nova senha',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Repita a nova senha',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  if (!loading) _submit();
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
                  onPressed: loading ? null : _submit,
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Salvar nova senha'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}