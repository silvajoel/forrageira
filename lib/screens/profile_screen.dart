import 'package:flutter/material.dart';
import 'package:forrageira/services/auth_service.dart';
import 'package:forrageira/widgets/profile_option.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controllers
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // States
  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    final username = user?.displayName ?? "Usuário";
    final email = user?.email ?? "Sem email";

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.person),
            SizedBox(width: 8),
            Text('Minha Conta'),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileCard(theme, username, email),
            const SizedBox(height: 16),
            const Text(
              "Configurações",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildOptionsCard(authService, email),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme, String username, String email) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : "U",
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Usuário", style: TextStyle(color: Colors.grey)),
                Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsCard(AuthService authService, String email) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        children: [
          ProfileOption(
            icon: Icons.edit,
            title: 'Atualizar nome de usuário',
            onTap: _updateUsername,
          ),
          const Divider(height: 1),
          ProfileOption(
            icon: Icons.lock_outline,
            title: 'Alterar senha',
            onTap: () => _showChangePasswordDialog(authService, email),
          ),
          const Divider(height: 1),
          ProfileOption(
            icon: Icons.delete_outline,
            title: 'Excluir minha conta',
            isDanger: true,
            onTap: () => _showDeleteAccountDialog(authService, email),
          ),
          const Divider(height: 1),
          ProfileOption(
            icon: Icons.info_outline,
            title: 'Sobre o aplicativo',
            onTap: _aboutApp,
          ),
          const Divider(height: 1),
          ProfileOption(
            icon: Icons.logout,
            title: 'Sair',
            isDanger: true,
            onTap: authService.logout,
          ),
        ],
      ),
    );
  }

  // =========================
  // ALTERAR SENHA
  // =========================
  void _showChangePasswordDialog(AuthService authService, String email) {
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title: const Text('Alterar senha'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _passwordField(
                    controller: _passwordController,
                    label: "Senha atual",
                    obscure: _obscurePassword,
                    toggle: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  const SizedBox(height: 12),
                  _passwordField(
                    controller: _newPasswordController,
                    label: "Nova senha",
                    obscure: _obscureNewPassword,
                    toggle: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                  ),
                  const SizedBox(height: 12),
                  _passwordField(
                    controller: _confirmPasswordController,
                    label: "Confirmar senha",
                    obscure: _obscureConfirmPassword,
                    toggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    if (_newPasswordController.text !=
                        _confirmPasswordController.text) {
                      _showError("As senhas não conferem");
                      return;
                    }

                    try {
                      setState(() => isLoading = true);
                      await authService.resetPasswordFromCurrentPassword(
                        email: email,
                        currentPassword: _passwordController.text,
                        newPassword: _newPasswordController.text,
                      );
                      Navigator.pop(context);
                      _showSuccess("Senha alterada com sucesso");
                    } catch (_) {
                      setState(() => isLoading = false);
                      _showError("Senha atual incorreta");
                    }
                  },
                  child: isLoading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text("Alterar", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================
  // EXCLUIR CONTA
  // =========================
  void _showDeleteAccountDialog(AuthService authService, String email) {
    final senhaController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title: const Text("Excluir conta"),
              content: TextField(
                controller: senhaController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Senha"),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    try {
                      setState(() => isLoading = true);
                      await authService.deleteAccount(email, senhaController.text);
                      Navigator.pop(context);
                      _showSuccess("Conta excluída com sucesso");
                    } catch (_) {
                      setState(() => isLoading = false);
                      _showError("Senha incorreta");
                    }
                  },
                  child: const Text("Excluir", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================
  // AUXILIARES
  // =========================
  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: toggle,
        ),
      ),
    );
  }

  void _updateUsername() =>
      _showSuccess("Atualizar nome (em desenvolvimento)");

  void _aboutApp() => showAboutDialog(
    context: context,
    applicationName: "Forrageira",
    applicationVersion: "1.0.0",
  );

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );

  void _showSuccess(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
}
