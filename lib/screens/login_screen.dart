import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _auth = AuthService();
  final _userService = UserService();

  bool _obscureSenha = true;
  bool loading = false;

  void _login() async {
    setState(() => loading = true);

    try {
      final user = await _auth.login(
        _email.text.trim(),
        _senha.text.trim(),
      );

      if (user == null) {
        throw Exception("Falha no login.");
      }

      // 🔥 Busca perfil no Firestore
      final profile = await _userService.getProfile(user.uid);
      final role = profile?['role'] ?? 'user';

      if (!mounted) return;

      // 🚫 Se for admin, bloqueia login no app
      if (role == 'admin') {
        await _auth.logout();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Essa conta é administrativa. Use o painel web."),
          ),
        );

        setState(() => loading = false);
        return;
      }

      // ✅ Usuário normal entra no app
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login realizado!")),
      );

      Navigator.pushReplacementNamed(context, '/home');

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String mensagem = "Erro ao fazer login.";

      switch (e.code) {
        case 'user-not-found':
          mensagem = "Usuário não encontrado.";
          break;
        case 'wrong-password':
          mensagem = "Senha incorreta.";
          break;
        case 'invalid-email':
          mensagem = "E-mail inválido.";
          break;
        default:
          mensagem = "Erro de autenticação.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro inesperado. Tente novamente.")),
      );
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.green.shade100,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),

                Text(
                  "Forrageira",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: _senha,
                  obscureText: _obscureSenha,
                  decoration: InputDecoration(
                    labelText: "Senha",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureSenha ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureSenha = !_obscureSenha;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white, // cor do texto
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Entrar"),
                  ),
                ),
                const SizedBox(height: 10),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgotpassword');
                  },
                  child: const Text(
                    "Esqueceu a senha?",
                    style: TextStyle(color: Colors.green),
                  ),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text(
                    "Criar conta",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
