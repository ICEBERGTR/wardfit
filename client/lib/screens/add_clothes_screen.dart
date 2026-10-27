import 'package:flutter/material.dart';
import '../services/wardrobe_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav_shell.dart';
import '../widgets/clothing_illustration.dart';
import '../widgets/wardfit_logo.dart';

class AddClothesScreen extends StatefulWidget {
  const AddClothesScreen({super.key});

  @override
  State<AddClothesScreen> createState() => _AddClothesScreenState();
}

class _AddClothesScreenState extends State<AddClothesScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  static const List<String> _previewPresets = [
    'grey_jacket',
    'parachute_jacket',
    'villa_jacket',
    'gryphon_sweatshirt',
    'blue_jean',
    'yellow_shirt',
  ];

  int _previewIndex = 0;
  bool _saving = false;

  String get _currentImageKey => _previewPresets[_previewIndex];

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _cyclePreview(String sourceLabel) {
    setState(() {
      _previewIndex = (_previewIndex + 1) % _previewPresets.length;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$sourceLabel: garment preview updated.'),
        duration: const Duration(milliseconds: 1100),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name for the clothing item.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final state = WardrobeScope.of(context);
    final created = await state.addClothes(
      name: name,
      color: _colorController.text.trim().isEmpty
          ? 'Charcoal Grey'
          : _colorController.text.trim(),
      tags: _tagsController.text.trim().isEmpty
          ? 'casual, everyday'
          : _tagsController.text.trim(),
      imageKey: _currentImageKey,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${created.name}" (${created.category}) to My Clothes!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const WardFitBottomBar(activeIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 18, 32, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top header with lime double-chevron, title, and user avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(
                      Icons.keyboard_double_arrow_left_rounded,
                      color: AppColors.limeAccent,
                      size: 42,
                    ),
                  ),
                  const Text(
                    'Add New\nClothes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3E3A39),
                      height: 1.15,
                    ),
                  ),
                  const UserAvatarBadge(size: 46),
                ],
              ),
              const SizedBox(height: 28),

              // Bottom-bordered form fields: Name, Color, Tags
              _UnderlineFormField(
                controller: _nameController,
                hint: 'Name',
              ),
              const SizedBox(height: 16),
              _UnderlineFormField(
                controller: _colorController,
                hint: 'Color',
              ),
              const SizedBox(height: 16),
              _UnderlineFormField(
                controller: _tagsController,
                hint: 'Tags',
              ),
              const SizedBox(height: 26),

              // Circular action buttons: Take a pic & Upload a pic
              Row(
                children: [
                  _PhotoActionButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Take a pic',
                    onTap: () => _cyclePreview('Camera capture'),
                  ),
                  const SizedBox(width: 26),
                  _PhotoActionButton(
                    icon: Icons.upload_rounded,
                    label: 'Upload a pic',
                    onTap: () => _cyclePreview('Gallery upload'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Garment image preview box with bottom RETAKE PIC bar
              Container(
                width: double.infinity,
                height: 225,
                decoration: const BoxDecoration(
                  color: AppColors.previewGrey,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ClothingIllustration(
                          imageKey: _currentImageKey,
                          size: 165,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _cyclePreview('Retake photo'),
                      child: Container(
                        width: double.infinity,
                        height: 30,
                        color: const Color(0xFF3F403F),
                        alignment: Alignment.center,
                        child: const Text(
                          'RETAKE PIC',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Full-width dark grey SAVE button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saveButtonGrey,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _saving ? 'SAVING...' : 'SAVE',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnderlineFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _UnderlineFormField({
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 16, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 16.5,
          color: Color(0xFF8C8C8C),
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.only(bottom: 8, top: 8),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF555555), width: 1.1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 1.8),
        ),
      ),
    );
  }
}

class _PhotoActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFF7D7F7D),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF525252),
            ),
          ),
        ],
      ),
    );
  }
}
