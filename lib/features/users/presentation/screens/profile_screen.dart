import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../models/app_user_model.dart';
import '../../services/user_service.dart';
import '../../../../widgets/erp_ui_components.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  bool _isLoading = false;
  String? _photoUrl;
  dynamic _newPhotoFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() => _newPhotoFile = bytes);
      } else {
        setState(() => _newPhotoFile = File(image.path));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String? updatedPhotoUrl = _photoUrl;

      if (_newPhotoFile != null) {
        updatedPhotoUrl = await _userService.uploadProfilePhoto(
          widget.uid,
          _newPhotoFile,
          fileName: _newPhotoFile is File
              ? (_newPhotoFile as File).path.split('/').last
              : 'profile.png',
        );
      }

      await _userService.updateProfile(
        uid: widget.uid,
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photoUrl: updatedPhotoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUserModel?>(
      stream: _userService.getUserProfile(widget.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data;
        if (user == null) {
          return const Center(child: Text('User profile not found'));
        }

        // Initialize controllers with user data if not already edited
        if (_nameController.text.isEmpty && !_isLoading) {
          _nameController.text = user.displayName;
          _phoneController.text = user.phoneNumber ?? '';
          _emailController.text = user.email;
          _photoUrl = user.photoUrl;
        }

        return ErpGlassModal(
          title: 'My Profile',
          isLoading: _isLoading,
          onSave: _saveProfile,
          onCancel: () => Navigator.pop(context),
          saveLabel: 'Update Profile',
          width: 500,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        backgroundImage: _newPhotoFile != null
                            ? (kIsWeb
                                  ? MemoryImage(_newPhotoFile as Uint8List)
                                        as ImageProvider
                                  : FileImage(_newPhotoFile as File)
                                        as ImageProvider)
                            : (_photoUrl != null
                                  ? NetworkImage(_photoUrl!)
                                  : null),
                        child: _newPhotoFile == null && _photoUrl == null
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.5),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.white,
                            ),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  style: ErpFormStyle.inputStyle(context),
                  decoration: ErpFormStyle.inputDecoration(
                    context,
                    'Full Name',
                    icon: Icons.person_outline,
                  ),
                  validator: (v) => v!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  enabled: false,
                  style: ErpFormStyle.inputStyle(
                    context,
                  ).copyWith(color: Colors.grey),
                  decoration: ErpFormStyle.inputDecoration(
                    context,
                    'Email Address',
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  style: ErpFormStyle.inputStyle(context),
                  decoration: ErpFormStyle.inputDecoration(
                    context,
                    'Mobile Number',
                    icon: Icons.phone_android_outlined,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your profile information is visible within your company workspace.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
