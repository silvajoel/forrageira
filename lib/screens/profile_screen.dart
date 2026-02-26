import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  String username = "Usuário";
  String email = "usuario@email.com";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        child: CustomScrollView(
          slivers: [

            /// PERFIL
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [

                        CircleAvatar(
                          radius: 35,
                          backgroundColor: theme.colorScheme.primary,
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Usuário',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                username,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            /// TÍTULO
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(left: 20, bottom: 8),
                child: Text(
                  "Configurações",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            /// CONFIGURAÇÕES
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                        onTap: _changePassword,
                      ),

                      const Divider(height: 1),

                      ProfileOption(
                        icon: Icons.delete_outline,
                        title: 'Excluir minha conta',
                        isDanger: true,
                        onTap: _deleteAccount,
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
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AÇÕES

  void _updateUsername() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Atualizar nome clicado")),
    );
  }

  void _changePassword() {
    Navigator.pushReplacementNamed(context, '/resetpassword');
  }

  void _deleteAccount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Excluir conta clicado")),
    );
  }

  void _aboutApp() {
    showAboutDialog(
      context: context,
      applicationName: "Seu App",
      applicationVersion: "1.0.0",
    );
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/login');
  }
}

/// =======================================
/// WIDGET SEPARADO (FORA DA CLASSE)
/// =======================================

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDanger;

  const ProfileOption({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDanger = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDanger ? Colors.red : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}