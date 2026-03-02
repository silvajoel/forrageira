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
  bool loading = false;
  String? error;

  final _auth = AuthService();
  final _userService = UserService();

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
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
        throw Exception('Falha no login.');
      }

      final profile = await _userService.getProfile(user.uid);
      final role = profile?['role'];

      if (!mounted) return;

      // 🚫 Bloqueia se não for admin
      if (role != 'admin') {
        await _auth.logout();
        setState(() {
          loading = false;
          error = 'Acesso negado. Essa conta não é administradora.';
        });
        return;
      }

      setState(() => loading = false);
      Navigator.pushReplacementNamed(context, '/admin');

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
        default:
          msg = 'Erro de autenticação.';
      }

      setState(() {
        loading = false;
        error = msg;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Erro inesperado. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      body: Center(
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
              ),
              const SizedBox(height: 12),

              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(error!, style: const TextStyle(color: Colors.red)),
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
            ],
          ),
        ),
      ),
    );
  }
}