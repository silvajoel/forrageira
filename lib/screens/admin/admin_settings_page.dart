import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _userService = UserService();
  final _auth = FirebaseAuth.instance;
  final _authService = AuthService();

  late final TextEditingController nomeCtrl;
  late final TextEditingController emailCtrl;

  final currentPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmNewPassCtrl = TextEditingController();

  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  bool saving = false;
  bool _filledOnce = false;

  @override
  void initState() {
    super.initState();
    nomeCtrl = TextEditingController();
    emailCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _authService.syncCurrentUserEmailToFirestore();
      if (mounted) {
        setState(() {
          _filledOnce = false;
        });
      }
    });
  }

  @override
  void dispose() {
    nomeCtrl.dispose();
    emailCtrl.dispose();
    currentPassCtrl.dispose();
    newPassCtrl.dispose();
    confirmNewPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return ListView(
        children: [
          const Text(
            'Configurações',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          if (uid == null)
            _card(
              title: 'Minha conta',
              child: const Text('Usuário não autenticado. Faça login novamente.'),
            )
          else
            StreamBuilder(
              stream: _userService.streamProfile(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _card(
                    title: 'Minha conta',
                    child: const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _card(
                    title: 'Minha conta',
                    child: const Text('Perfil não encontrado no Firestore.'),
                  );
                }

                final data = snapshot.data!.data() ?? {};
                final name = (data['name'] ?? '') as String;
                final firestoreEmail = (data['email'] ?? '') as String;
                final authEmail = (_auth.currentUser?.email ?? '').trim().toLowerCase();

                final emailToShow = authEmail.isNotEmpty ? authEmail : firestoreEmail;

                if (!_filledOnce) {
                  nomeCtrl.text = name;
                  emailCtrl.text = emailToShow;
                  _filledOnce = true;
                }

                return _card(
                  title: 'Minha conta',
                  child: Column(
                    children: [
                      TextField(
                        controller: nomeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 18),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Alterar senha',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: currentPassCtrl,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          labelText: 'Senha atual',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(obscureCurrent
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () =>
                                setState(() => obscureCurrent = !obscureCurrent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: newPassCtrl,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'Nova senha',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () =>
                                setState(() => obscureNew = !obscureNew),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: confirmNewPassCtrl,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirmar nova senha',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () =>
                                setState(() => obscureConfirm = !obscureConfirm),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: saving ? null : () => _save(uid),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F5B3F),
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: saving
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                              : const Text('Salvar'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Obs: ao alterar o e-mail, um link de verificação será enviado ao novo endereço.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      );
  }

  Future<void> _save(String uid) async {
    final nome = nomeCtrl.text.trim();
    final email = emailCtrl.text.trim().toLowerCase();

    final currentPass = currentPassCtrl.text.trim();
    final newPass = newPassCtrl.text.trim();
    final confirmNewPass = confirmNewPassCtrl.text.trim();

    final authEmail = (_auth.currentUser?.email ?? '').trim().toLowerCase();
    final emailChanged = authEmail != email;

    final wantsChangePassword = currentPass.isNotEmpty ||
        newPass.isNotEmpty ||
        confirmNewPass.isNotEmpty;

    if (nome.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe nome e e-mail.')),
      );
      return;
    }

    if (emailChanged && currentPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Para alterar o e-mail, informe sua senha atual.'),
        ),
      );
      return;
    }

    if (emailChanged && (newPass.isNotEmpty || confirmNewPass.isNotEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Altere o e-mail e a senha separadamente para evitar inconsistências.',
          ),
        ),
      );
      return;
    }

    if (wantsChangePassword && !emailChanged) {
      if (currentPass.isEmpty || newPass.isEmpty || confirmNewPass.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preencha senha atual, nova senha e confirmação.'),
          ),
        );
        return;
      }

      if (newPass.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nova senha muito curta (mínimo 6).'),
          ),
        );
        return;
      }

      if (newPass != confirmNewPass) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A nova senha e a confirmação não são iguais.'),
          ),
        );
        return;
      }
    }

    setState(() => saving = true);

    try {
      await _userService.updateProfile(
        uid: uid,
        name: nome,
        email: authEmail.isNotEmpty ? authEmail : email,
      );

      if (emailChanged) {
        await _authService.updateLoginEmail(
          currentPassword: currentPass,
          newEmail: email,
        );
      }

      if (wantsChangePassword && !emailChanged) {
        await _authService.resetPasswordFromCurrentPassword(
          currentPassword: currentPass,
          newPassword: newPass,
          email: authEmail,
        );

        currentPassCtrl.clear();
        newPassCtrl.clear();
        confirmNewPassCtrl.clear();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            emailChanged
                ? 'Nome atualizado. Verifique o novo e-mail para confirmar a troca.'
                : 'Dados atualizados com sucesso!',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Não foi possível salvar as alterações.';

      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Esse e-mail já está sendo usado por outra conta.';
          break;
        case 'wrong-password':
          msg = 'Senha atual incorreta.';
          break;
        case 'invalid-email':
          msg = 'E-mail inválido.';
          break;
        case 'same-email':
          msg = 'Informe um e-mail diferente do atual.';
          break;
        case 'requires-recent-login':
          msg = 'Faça login novamente antes de alterar e-mail ou senha.';
          break;
        default:
          msg = e.message ?? 'Erro ao atualizar os dados.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}