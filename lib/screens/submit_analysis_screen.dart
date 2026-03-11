import 'package:flutter/material.dart';
import 'package:forrageira/services/forage_service.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/app_text_field.dart';
import '../widgets/new_analysis_card.dart';

class SubmitAnalysisScreen extends StatefulWidget {
  const SubmitAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<SubmitAnalysisScreen> createState() => _SubmitAnalysisScreenState();
}

class _SubmitAnalysisScreenState extends State<SubmitAnalysisScreen> {

  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser;
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<Position> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("GPS desativado");
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Permissão de localização negada");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _submitForm() async {

    if (!_formKey.currentState!.validate()) return;
    print("Teste");
    final forageService = Provider.of<ForageService>(context, listen: false);

    try {
      print("Teste");
      Position position = await _getLocation();

      await forageService.createAnalysisRequest(
        name: _nameController.text.trim(),
        notes: _notesController.text.trim(),
        latitude: position.latitude,
        longitude: position.longitude,
        imageUrl: null, // preparado para Firebase Storage
        userId: user!.uid,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Forrageira enviada com sucesso!"),
        ),
      );

      Navigator.pushReplacementNamed(context, '/home');

      _formKey.currentState!.reset();
      _nameController.clear();
      _notesController.clear();

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao enviar: $e"),
        ),
      );

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
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(
                        "Envie suas Forrageiras",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 24),

                      AppTextField(
                        controller: _nameController,
                        label: "Nome da Forrageira",
                        icon: Icons.grass,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Informe o nome";
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