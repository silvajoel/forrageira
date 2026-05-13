import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../services/i_forage_service.dart';
import '../services/i_image_storage_service.dart';
import '../services/i_location_service.dart';
import '../services/navigation_service.dart';
import '../services/pending_analysis_queue_service.dart';
import '../services/plesk_image_storage_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/image_viewer_dialog.dart';
import '../widgets/notification_bell_button.dart';

class SubmitAnalysisScreen extends StatefulWidget {
  final ILocationService locationService;
  final IImageStorageService imageStorageService;

  const SubmitAnalysisScreen({
    super.key,
    required this.locationService,
    required this.imageStorageService,
  });

  @override
  State<SubmitAnalysisScreen> createState() => _SubmitAnalysisScreenState();
}

class _SubmitAnalysisScreenState extends State<SubmitAnalysisScreen> {
  static const int _minImages = 5;
  static const int _maxImages = 5;
  static const int _maxUploadBytes = 5 * 1024 * 1024;
  static const double _bottomActionBarHeight = 96;

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
  String get _resolvedForageName {
    final value = _nameController.text.trim();
    return value.isEmpty ? 'Sem nome informado' : value;
  }

  @override
  void initState() {
    super.initState();
    _loadFirstSubmissionState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncPendingAnalyses();
      context.read<PendingAnalysisQueueService>().ensureLoaded();
    });
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
      _showSnack(
          'Voc\u00ea j\u00e1 concluiu as $_maxImages fotos obrigat\u00f3rias.');
      return;
    }

    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 82,
      maxWidth: 1800,
      maxHeight: 1800,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (photo == null) return;

    final imageFile = File(photo.path);
    final size = await imageFile.length();
    if (size > _maxUploadBytes) {
      _showSnack(
        'A foto ficou acima de 5 MB mesmo apos a compactacao. Tire novamente com mais distancia ou menos zoom.',
      );
      return;
    }

    setState(() => _selectedImages.add(imageFile));

    final remaining = _remainingImages;
    _showSnack(
      remaining == 0
          ? '5/5 fotos capturadas. Voc\u00ea j\u00e1 pode enviar a an\u00e1lise.'
          : '${_selectedImages.length}/$_maxImages fotos capturadas. Faltam $remaining.',
    );
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _syncPendingAnalyses() async {
    final queueService = context.read<PendingAnalysisQueueService>();
    await queueService.syncPendingAnalyses(
      forageService: context.read<IForageService>(),
      imageStorageService: widget.imageStorageService,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.length < _minImages) {
      _showSnack('Envie no m\u00ednimo $_minImages imagens.');
      return;
    }

    if (_selectedImages.length > _maxImages) {
      _showSnack('Envie no m\u00e1ximo $_maxImages imagens.');
      return;
    }

    final uid = _userId;
    if (uid == null) {
      _showSnack('Usu\u00e1rio n\u00e3o autenticado.');
      return;
    }

    setState(() => _isUploading = true);

    final forageService = context.read<IForageService>();
    final queueService = context.read<PendingAnalysisQueueService>();

    try {
      final location = await widget.locationService.getCurrentLocation();
      try {
        final imageUrls = await widget.imageStorageService.uploadImages(
          _selectedImages,
          uid,
        );

        await forageService.createAnalysisRequest(
          name: _resolvedForageName,
          notes: _notesController.text.trim(),
          latitude: location.latitude,
          longitude: location.longitude,
          imageUrls: imageUrls,
          userId: uid,
        );

        _showSnack('Forrageira enviada com sucesso!');
      } on ImageUploadException catch (e) {
        if (!e.isRetryable) {
          _showSnack(e.message);
          return;
        }

        await queueService.enqueue(
          name: _resolvedForageName,
          notes: _notesController.text.trim(),
          userId: uid,
          latitude: location.latitude,
          longitude: location.longitude,
          images: _selectedImages,
        );

        _showSnack(
          'An\u00e1lise salva offline. Ela ser\u00e1 encaminhada assim que houver internet.',
        );
      } catch (_) {
        await queueService.enqueue(
          name: _resolvedForageName,
          notes: _notesController.text.trim(),
          userId: uid,
          latitude: location.latitude,
          longitude: location.longitude,
          images: _selectedImages,
        );

        _showSnack(
          'An\u00e1lise salva offline. Ela ser\u00e1 encaminhada assim que houver internet.',
        );
      }

      if (mounted) {
        _clearSubmissionState();
        _returnToHome();
      }
    } catch (e) {
      _showSnack('Erro ao enviar: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _clearSubmissionState() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _notesController.clear();
    setState(() {
      _selectedImages.clear();
      _isFirstSubmission = false;
    });
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    final mediaQuery = MediaQuery.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            mediaQuery.padding.bottom + _bottomActionBarHeight,
          ),
        ),
      );
  }

  void _returnToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      mainScreenKey.currentState?.setIndex(0);
    });
  }

  double _contentBottomPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return _bottomActionBarHeight + mediaQuery.padding.bottom + 32;
  }

  String _photoHelperText() {
    final remaining = _remainingImages;
    if (remaining == 0) {
      return 'As 5 fotos foram capturadas. Revise as imagens abaixo e toque em Enviar.';
    }

    return 'Cada foto e compactada automaticamente para facilitar o envio. Faltam $remaining foto(s).';
  }

  Widget _buildSelectedPhotosHeader(ThemeData theme) {
    final captured = _selectedImages.length;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Fotos capturadas',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$captured/$_maxImages',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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
            Text('Nova an\u00e1lise'),
          ],
        ),
        actions: [
          if (_userId != null) NotificationBellButton(userId: _userId!),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _isUploading || isCaptureComplete ? null : _takePhoto,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(
                    isCaptureComplete
                        ? '5 fotos conclu\u00eddas'
                        : 'Tirar foto ($captured/$_maxImages)',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            _contentBottomPadding(context),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nova an\u00e1lise',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tire 5 fotos obrigat\u00f3rias da forrageira para enviar a solicita\u00e7\u00e3o.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _nameController,
                  label: 'Voc\u00ea conhece essa forrageira por algum nome?',
                  icon: Icons.grass,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _notesController,
                  label: 'Observa\u00e7\u00f5es',
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
                const SizedBox(height: 10),
                Text(
                  'Toque em uma foto para ampliar. Use o X para remover e refazer.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Text(
                  _photoHelperText(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPhotoChecklist(theme),
                const SizedBox(height: 16),
                if (_selectedImages.isNotEmpty) ...[
                  _buildSelectedPhotosHeader(theme),
                  const SizedBox(height: 12),
                  _buildImageGrid(),
                ],
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
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
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
                  'Fotos obrigat\u00f3rias',
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
                : 'Voc\u00ea precisa tirar $_maxImages foto(s). J\u00e1 tirou $captured de $_maxImages.',
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
                      'Guia r\u00e1pido do primeiro envio',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use estas refer\u00eancias para capturar fotos mais n\u00edtidas e ajudar na identifica\u00e7\u00e3o.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 370,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _TutorialPhotoCard(
                  number: '1',
                  title: 'Planta no ambiente',
                  subtitle: 'Tire uma foto da planta no ambiente.',
                  hint:
                      'Mostre o porte e o local onde ela est\u00e1 crescendo.',
                  icon: Icons.grass,
                  imagePath: 'assets/images/planta_inteira.png',
                ),
                SizedBox(width: 12),
                _TutorialPhotoCard(
                  number: '2',
                  title: 'Detalhe da planta',
                  subtitle: 'Fotografe um detalhe da planta.',
                  hint: 'Inclua folhas e colmos com boa nitidez.',
                  icon: Icons.center_focus_strong,
                  imagePath: 'assets/images/tutorial_vista_frontal.png',
                ),
                SizedBox(width: 12),
                _TutorialPhotoCard(
                  number: '3',
                  title: 'Infloresc\u00eancia',
                  subtitle: 'Tire uma foto da infloresc\u00eancia.',
                  hint: 'Enquadre a estrutura inteira, sem cortar a ponta.',
                  icon: Icons.local_florist_outlined,
                  imagePath: 'assets/images/tutorial_inflorescencia.png',
                ),
                SizedBox(width: 12),
                _TutorialPhotoCard(
                  number: '4',
                  title: 'Detalhe pr\u00f3ximo',
                  subtitle: 'Fa\u00e7a uma foto de detalhe mais pr\u00f3ximo.',
                  hint: 'Aproxime sem perder o foco do ponto principal.',
                  icon: Icons.zoom_in,
                  imagePath: 'assets/images/tutorial_detalhe.png',
                ),
                SizedBox(width: 12),
                _TutorialPhotoCard(
                  number: '5',
                  title: 'Outro detalhe \u00fatil',
                  subtitle:
                      'Registre algum outro detalhe que possa ser \u00fatil.',
                  hint:
                      'Pode ser base, n\u00f3s, pelos, manchas ou outra pista.',
                  icon: Icons.add_photo_alternate_outlined,
                  imagePath: 'assets/images/tutorial_outro.png',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Siga a ordem das fotos para facilitar a identifica\u00e7\u00e3o da forrageira.',
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
            description: 'Use luz natural e mantenha a c\u00e2mera firme.',
          ),
          _buildGuidelineItem(
            icon: Icons.filter_1_outlined,
            title: 'Foto 1',
            description: 'Tire uma foto da planta no ambiente.',
          ),
          _buildGuidelineItem(
            icon: Icons.filter_2_outlined,
            title: 'Foto 2',
            description: 'Detalhe da planta.',
          ),
          _buildGuidelineItem(
            icon: Icons.filter_3_outlined,
            title: 'Foto 3',
            description: 'Foto da infloresc\u00eancia.',
          ),
          _buildGuidelineItem(
            icon: Icons.filter_4_outlined,
            title: 'Foto 4',
            description: 'Foto de detalhe mais pr\u00f3ximo.',
          ),
          _buildGuidelineItem(
            icon: Icons.filter_5_outlined,
            title: 'Foto 5',
            description: 'Algum outro detalhe que possa ser \u00fatil.',
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
      width: 260,
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
          SizedBox(
            height: 178,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                height: double.infinity,
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
