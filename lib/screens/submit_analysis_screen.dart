import 'package:flutter/material.dart';
import 'package:forrageira/services/forage_service.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_text_field.dart';
import '../widgets/new_analysis_card.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  final ImagePicker picker = ImagePicker();

  List<File> selectedImages = [];

  bool isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// LOCALIZAÇÃO
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

  /// GALERIA
  Future<void> pickImages() async {

    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        selectedImages.addAll(images.map((e) => File(e.path)));
      });
    }
  }

  /// CÂMERA
  Future<void> takePhoto() async {

    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() {
        selectedImages.add(File(photo.path));
      });
    }
  }

  /// REMOVER IMAGEM
  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  /// UPLOAD PARA SUPABASE
  Future<List<String>> uploadImages() async {

    final supabase = Supabase.instance.client;

    List<String> imageUrls = [];

    for (var image in selectedImages) {

      final fileName = DateTime.now().millisecondsSinceEpoch.toString();

      final path = "images/${user!.uid}/$fileName.jpg";

      await supabase.storage
          .from('forrageiras')
          .upload(path, image);

      final url = supabase.storage
          .from('forrageiras')
          .getPublicUrl(path);

      imageUrls.add(url);
    }

    return imageUrls;
  }

  /// ENVIO DO FORMULÁRIO
  Future<void> _submitForm() async {

    if (!_formKey.currentState!.validate()) return;

    if (selectedImages.length < 5) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Envie no mínimo 5 imagens da forrageira."),
        ),
      );

      return;
    }

    setState(() {
      isUploading = true;
    });

    final forageService = Provider.of<ForageService>(context, listen: false);

    try {

      Position position = await _getLocation();

      List<String> imageUrls = await uploadImages();

      await forageService.createAnalysisRequest(
        name: _nameController.text.trim(),
        notes: _notesController.text.trim(),
        latitude: position.latitude,
        longitude: position.longitude,
        imageUrls: imageUrls,
        userId: user!.uid,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Forrageira enviada com sucesso!"),
        ),
      );

      Navigator.pushReplacementNamed(context, '/home');

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao enviar: $e"),
        ),
      );

    } finally {

      setState(() {
        isUploading = false;
      });

    }
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.grass),
            SizedBox(width: 8),
            Text('Enviar Forrageira'),
          ],
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(

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

                  /// BOTÕES
                  Row(
                    children: [

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Câmera"),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: pickImages,
                          icon: const Icon(Icons.photo_library),
                          label: const Text("Galeria"),
                        ),
                      ),

                    ],
                  ),

                  const SizedBox(height: 16),

                  /// PREVIEW
                  if (selectedImages.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: selectedImages.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {

                        return GestureDetector(
                          onTap: () => removeImage(index),
                          child: Stack(
                            children: [

                              Positioned.fill(
                                child: Image.file(
                                  selectedImages[index],
                                  fit: BoxFit.cover,
                                ),
                              ),

                              const Positioned(
                                right: 4,
                                top: 4,
                                child: Icon(
                                  Icons.cancel,
                                  color: Colors.white,
                                ),
                              ),

                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isUploading ? null : _submitForm,
                      child: isUploading
                          ? const CircularProgressIndicator()
                          : const Text("Enviar"),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}