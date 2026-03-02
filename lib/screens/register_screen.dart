import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmarSenha = TextEditingController();

  final _auth = AuthService();
  final _userService = UserService();

  bool loading = false;
  bool _obscureSenha = true;
  bool _obscureConfirmar = true;

  void _register() async {
    if (_nome.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _senha.text.trim().isEmpty ||
        _confirmarSenha.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos!")),
      );
      return;
    }

    if (_senha.text.trim() != _confirmarSenha.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("As senhas não são iguais!")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final user = await _auth.register(
        _email.text.trim(),
        _senha.text.trim(),
      );

      if (user == null) {
        throw Exception("Falha ao criar usuário.");
      }

      await _userService.createUserProfile(
        uid: user.uid,
        name: _nome.text.trim(),
        email: _email.text.trim(),
        role: 'user',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Conta criada com sucesso!")),
      );

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String mensagem = "Erro ao cadastrar.";

      switch (e.code) {
        case 'email-already-in-use':
          mensagem = "Este e-mail já está cadastrado.";
          break;
        case 'weak-password':
          mensagem = "Senha muito fraca. Use pelo menos 6 caracteres.";
          break;
        case 'invalid-email':
          mensagem = "E-mail inválido.";
          break;
        case 'operation-not-allowed':
          mensagem = "Cadastro por e-mail não está habilitado.";
          break;
        default:
          mensagem = "Erro de autenticação: ${e.code}";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );

    } on FirebaseException catch (e) {
      debugPrint('ERRO FIRESTORE: ${e.code} - ${e.message}');
      String msg = "Erro ao salvar dados no sistema.";

      if (e.code == 'permission-denied') {
        msg = "Sem permissão para salvar dados. Verifique as regras do Firestore.";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e, s) {
      debugPrint('ERRO REGISTER (geral): $e');
      debugPrintStack(stackTrace: s);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro inesperado. Tente novamente.")),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmarSenha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Cadastrar",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),

              // NOME
              TextField(
                controller: _nome,
                decoration: const InputDecoration(
                  labelText: "Nome",
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 10),

              // EMAIL
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 10),

              // SENHA
              TextField(
                controller: _senha,
                obscureText: _obscureSenha,
                decoration: InputDecoration(
                  labelText: "Senha",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureSenha ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureSenha = !_obscureSenha),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // CONFIRMAR SENHA
              TextField(
                controller: _confirmarSenha,
                obscureText: _obscureConfirmar,
                decoration: InputDecoration(
                  labelText: "Repita a senha",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmar ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmar = !_obscureConfirmar),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Cadastrar"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}