import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../services/i_forage_service.dart';
import '../services/i_image_storage_service.dart';
import '../services/i_location_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/new_analysis_card.dart';

// DIP: a screen recebe abstrações — não sabe nada sobre Supabase/Geolocator
class SubmitAnalysisScreen extends StatefulWidget {
  final ILocationService locationService;
  final IImageStorageService imageStorageService;

  const SubmitAnalysisScreen({
    Key? key,
    required this.locationService,
    required this.imageStorageService,
  }) : super(key: key);

  @override
  State<SubmitAnalysisScreen> createState() => _SubmitAnalysisScreenState();
}

class _SubmitAnalysisScreenState extends State<SubmitAnalysisScreen> {
  static const int _minImages = 5;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _picker = ImagePicker();

  final List<File> _selectedImages = [];
  bool _isUploading = false;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- Imagens ---

  Future<void> _pickFromGallery() async {
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images.map((e) => File(e.path))));
    }
  }

  Future<void> _takePhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo != null) {
      setState(() => _selectedImages.add(File(photo.path)));
    }
  }

  void _removeImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  // --- Submit ---

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.length < _minImages) {
      _showSnack("Envie no mínimo $_minImages imagens da forrageira.");
      return;
    }

    final uid = _userId;
    if (uid == null) {
      _showSnack("Usuário não autenticado.");
      return;
    }

    setState(() => _isUploading = true);

    // ForageService vem do Provider (continua como ChangeNotifier)
    final forageService = context.read<IForageService>();

    try {
      final location = await widget.locationService.getCurrentLocation();
      final imageUrls = await widget.imageStorageService
          .uploadImages(_selectedImages, uid);

      await forageService.createAnalysisRequest(
        name: _nameController.text.trim(),
        notes: _notesController.text.trim(),
        latitude: location.latitude,
        longitude: location.longitude,
        imageUrls: imageUrls,
        userId: uid,
      );

      _showSnack("Forrageira enviada com sucesso!");
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _showSnack("Erro ao enviar: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.grass),
          SizedBox(width: 8),
          Text('Enviar Forrageira'),
        ]),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Envie suas Forrageiras",
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _nameController,
                  label: "Nome da Forrageira",
                  icon: Icons.grass,
                  validator: (v) =>
                  (v == null || v.isEmpty) ? "Informe o nome" : null,
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
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Câmera"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Galeria"),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                if (_selectedImages.isNotEmpty) _buildImageGrid(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _submitForm,
                    child: _isUploading
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
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedImages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (_, index) => GestureDetector(
        onTap: () => _removeImage(index),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.file(_selectedImages[index], fit: BoxFit.cover),
            ),
            const Positioned(
              right: 4,
              top: 4,
              child: Icon(Icons.cancel, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}