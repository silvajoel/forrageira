import 'package:flutter/material.dart';
import '../widgets/app_text_field.dart';
import '../widgets/new_analysis_card.dart';
import '../widgets/bottom_nav_custom.dart';

class SubmitAnalysisScreen extends StatefulWidget {
  const SubmitAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<SubmitAnalysisScreen> createState() =>
      _SubmitAnalysisScreenState();
}

class _SubmitAnalysisScreenState
    extends State<SubmitAnalysisScreen> {

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {

      // Aqui você poderá integrar com Firebase depois
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Forrageira enviada com sucesso!"),
        ),
      );
      Navigator.pushReplacementNamed(context, '/home');
      _formKey.currentState!.reset();
      _nameController.clear();
      _locationController.clear();
      _notesController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.grass),
            SizedBox(width: 8),
            Text('Enviar Forrageira'),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.person_outline),
          ),
        ],
      ),

      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      Text(
                        "Envie suas Forrageiras",
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 24),

                      AppTextField(
                        controller: _nameController,
                        label: "Nome da Forrageira",
                        icon: Icons.grass,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return "Informe o nome";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _locationController,
                        label: "Local da Coleta",
                        icon: Icons.location_on_outlined,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return "Informe o local";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      AppTextField(
                        controller: _notesController,
                        label: "Observações",
                        icon: Icons.note_alt_outlined,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 24),

                      const NewAnalysisCard(),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          child: const Text("Enviar"),
                        ),
                      ),


                      const SizedBox(height: 40),
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
}