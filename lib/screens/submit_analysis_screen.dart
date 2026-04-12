import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/i_forage_service.dart';
import '../services/i_image_storage_service.dart';
import '../services/i_location_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/image_viewer_dialog.dart';

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
  static const int _maxImages = 5;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _picker = ImagePicker();

  final List<File> _selectedImages = [];

  bool _isUploading = false;
  bool _isCheckingFirstSubmission = true;
  bool _isFirstSubmission = false;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  int get _remainingImages => _maxImages - _selectedImages.length;

  @override
  void initState() {
    super.initState();
    _loadFirstSubmissionState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadFirstSubmissionState() async {
    final uid = _userId;
    if (uid == null) {
      if (mounted) {
        setState(() => _isCheckingFirstSubmission = false);
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('analysis_requests')
          .where('user_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (!mounted) return;
      setState(() {
        _isFirstSubmission = snapshot.docs.isEmpty;
        _isCheckingFirstSubmission = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCheckingFirstSubmission = false);
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedImages.length >= _maxImages) {
      _showSnack('Voce ja concluiu as $_maxImages fotos obrigatorias.');
      return;
    }

    final photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() => _selectedImages.add(File(photo.path)));

    final remaining = _remainingImages;
    _showSnack(
      remaining == 0
          ? '5/5 fotos capturadas. Voce ja pode enviar a analise.'
          : '${_selectedImages.length}/$_maxImages fotos capturadas. Faltam $remaining.',
    );
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.length < _minImages) {
      _showSnack('Envie no minimo $_minImages imagens.');
      return;
    }

    if (_selectedImages.length > _maxImages) {
      _showSnack('Envie no maximo $_maxImages imagens.');
      return;
    }

    final uid = _userId;
    if (uid == null) {
      _showSnack('Usuario nao autenticado.');
      return;
    }

    setState(() => _isUploading = true);

    final forageService = context.read<IForageService>();

    try {
      final location = await widget.locationService.getCurrentLocation();
      final imageUrls = await widget.imageStorageService.uploadImages(
        _selectedImages,
        uid,
      );

      await forageService.createAnalysisRequest(
        name: _nameController.text.trim(),
        notes: _notesController.text.trim(),
        latitude: location.latitude,
        longitude: location.longitude,
        imageUrls: imageUrls,
        userId: uid,
      );

      _showSnack('Forrageira enviada com sucesso!');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showSnack('Erro ao enviar: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final captured = _selectedImages.length;
    final isCaptureComplete = captured >= _maxImages;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.grass),
            SizedBox(width: 8),
            Text('Nova analise'),
          ],
        ),
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
                  'Nova analise',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tire 5 fotos obrigatorias da forrageira para enviar a solicitacao.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _nameController,
                  label: 'Nome da forrageira',
                  icon: Icons.grass,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _notesController,
                  label: 'Observacoes',
                  icon: Icons.note_alt_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                _buildCaptureStatus(theme),
                const SizedBox(height: 16),
                if (_isCheckingFirstSubmission)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_isFirstSubmission) ...[
                  _buildFirstSubmissionTutorial(theme),
                  const SizedBox(height: 16),
                ],
                _buildPhotoChecklist(theme),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isUploading || isCaptureComplete ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      isCaptureComplete
                          ? '5 fotos concluidas'
                          : 'Tirar foto ($captured/$_maxImages)',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Toque em uma foto para ampliar. Use o X para remover e refazer.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                if (_selectedImages.isNotEmpty) _buildImageGrid(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _submitForm,
                    child: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text('Enviar'),
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

  Widget _buildCaptureStatus(ThemeData theme) {
    final captured = _selectedImages.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_camera_back_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Fotos obrigatorias',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$captured/$_maxImages',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            captured == _maxImages
                ? 'Todas as fotos foram capturadas.'
                : 'Faltam $_remainingImages foto(s) para concluir o envio.',
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: captured / _maxImages),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstSubmissionTutorial(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAF2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB7D49A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFDDECCB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guia rapido do primeiro envio',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use estas referencias para capturar fotos mais nitidas e ajudar na identificacao.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 242,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _TutorialPhotoCard(
                  number: '1',
                  title: 'Folha e colmo',
                  subtitle:
                      'Aproxime o caule e as folhas, com foco no detalhe.',
                  hint: 'Evite folhas na frente do ponto principal.',
                  icon: Icons.grass,
                  imagePath: 'assets/images/tutorial_folha_colmo.png',
                ),
                SizedBox(width: 12),
                _TutorialPhotoCard(
                  number: '2',
                  title: 'Vista lateral',
                  subtitle: 'Mostre a espiga ou inflorescencia de lado.',
                  hint: 'Tente enquadrar sem cortar a ponta.',
                  icon: Icons.rotate_90_degrees_ccw,
                  imagePath: 'assets/images/tutorial_vista_lateral.png',
                ),
                SizedBox(width: 12),
                _TutorialPhotoCard(
                  number: '3',
                  title: 'Vista frontal',
                  subtitle: 'Registre a parte frontal da espiga com boa luz.',
                  hint: 'Centralize o detalhe principal na foto.',
                  icon: Icons.center_focus_strong,
                  imagePath: 'assets/images/tutorial_vista_frontal.png',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'As outras 2 fotos podem complementar com planta inteira e base da forrageira.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoChecklist(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legenda das 5 fotos',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildGuidelineItem(
            icon: Icons.wb_sunny_outlined,
            title: 'Dica geral',
            description: 'Use luz natural e mantenha a camera firme.',
          ),
          _buildGuidelineItem(
            icon: Icons.filter_1_outlined,
            title: 'Foto 1',
            description: 'Planta inteira no ambiente.',
          ),
          _buildGuidelineItem(
            icon: Icons.filter_2_outlined,
            title: 'Foto 2',
            description: 'Vista frontal da espiga, flor ou fruto.',
          ),
          _buildGuidelineItem(
            icon: Icons.filter_3_outlined,
            title: 'Foto 3',
            description: 'Vista lateral da espiga, flor ou fruto.',
          ),
          _buildGuidelineItem(
            icon: Icons.filter_4_outlined,
            title: 'Foto 4',
            description: 'Folha e colmo com foco.',
          ),
          _buildGuidelineItem(
            icon: Icons.filter_5_outlined,
            title: 'Foto 5',
            description: 'Base, nos ou outro detalhe importante.',
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
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
        onTap: () => showImageViewerDialog(
          context: context,
          title: 'Foto ${index + 1}',
          child: Image.file(_selectedImages[index], fit: BoxFit.contain),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_selectedImages[index], fit: BoxFit.cover),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Foto ${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Material(
                color: Colors.black45,
                shape: const CircleBorder(),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _removeImage(index),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialPhotoCard extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final String hint;
  final IconData icon;
  final String imagePath;

  const _TutorialPhotoCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.icon,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F5D8), Color(0xFFCFE7AD)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF9FBE7F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Icon(icon, size: 26, color: const Color(0xFF37541D)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF37541D),
            ),
          ),
        ],
      ),
    );
  }
}
