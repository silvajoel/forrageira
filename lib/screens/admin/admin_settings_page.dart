import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/admin/admin_shell.dart';

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

    return AdminShell(
      selectedMenu: 'config',
      child: ListView(
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
                final email = (data['email'] ?? '') as String;

                if (!_filledOnce) {
                  nomeCtrl.text = name;
                  emailCtrl.text =
                  email.isNotEmpty ? email : (_auth.currentUser?.email ?? '');
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
                            onPressed: () => setState(
                                    () => obscureCurrent = !obscureCurrent),
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
                            onPressed: () => setState(
                                    () => obscureConfirm = !obscureConfirm),
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
                        'Obs: alterar e-mail/senha pode exigir login recente.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _save(String uid) async {
    final nome = nomeCtrl.text.trim();
    final email = emailCtrl.text.trim();

    final currentPass = currentPassCtrl.text.trim();
    final newPass = newPassCtrl.text.trim();
    final confirmNewPass = confirmNewPassCtrl.text.trim();

    if (nome.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe nome e e-mail.')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      // 1) Atualiza Firestore (perfil principal)
      await _userService.updateProfile(uid: uid, name: nome, email: email);

      // 2) Atualiza e-mail no Auth se mudou (pode exigir re-login)
      final authEmail = _auth.currentUser?.email;
      if (authEmail != null && authEmail != email) {
        await _auth.currentUser!.updateEmail(email);
      }

      // 3) Troca senha (se usuário preencheu qualquer campo de senha)
      final wantsChangePassword = currentPass.isNotEmpty ||
          newPass.isNotEmpty ||
          confirmNewPass.isNotEmpty;

      if (wantsChangePassword) {
        // validações
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
            const SnackBar(content: Text('Nova senha muito curta (mínimo 6).')),
          );
          return;
        }

        if (newPass != confirmNewPass) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('A nova senha e a confirmação não são iguais.')),
          );
          return;
        }

        // reautentica e troca senha
        await _authService.resetPasswordFromCurrentPassword(
          currentPassword: currentPass,
          newPassword: newPass,
          email: email,
        );

        currentPassCtrl.clear();
        newPassCtrl.clear();
        confirmNewPassCtrl.clear();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados atualizados com sucesso!')),
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Dados salvos, mas não foi possível atualizar e-mail/senha.';

      if (e.code == 'requires-recent-login') {
        msg =
        'Salvo no sistema. Para mudar e-mail/senha, faça login novamente e tente de novo.';
      } else if (e.code == 'wrong-password') {
        msg = 'Senha atual incorreta.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar. Tente novamente.')),
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
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, 6)),
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