import 'package:africanmovies/features/auth/application/auth_controller.dart';
import 'package:africanmovies/features/auth/domain/auth_session.dart';
import 'package:africanmovies/features/profile/widgets/profile_avatar.dart';
import 'package:africanmovies/shared/widgets/app_button.dart';
import 'package:africanmovies/shared/widgets/app_screen_header.dart';
import 'package:africanmovies/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/app_scaffold.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _imagePicker = ImagePicker();

  String _initialUsername = '';
  bool _hasSeededUsername = false;
  bool _isSavingUsername = false;
  bool _isPickingImage = false;
  bool _isUploadingImage = false;
  bool _isDeletingImage = false;

  bool get _isBusy {
    return _isSavingUsername ||
        _isPickingImage ||
        _isUploadingImage ||
        _isDeletingImage;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _seedUsername(AuthUser user) {
    if (_hasSeededUsername) return;

    _initialUsername = user.username.trim();
    _usernameController.text = _initialUsername;
    _hasSeededUsername = true;
  }

  Future<void> _pickProfileImage() async {
    if (_isBusy) return;

    XFile? image;

    setState(() => _isPickingImage = true);

    try {
      image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1400,
        requestFullMetadata: false,
      );
    } on MissingPluginException {
      if (!mounted) return;
      _showMessage('Photo picker is not ready. Restart the app and try again.');
    } on PlatformException catch (error) {
      if (!mounted) return;
      _showMessage(_pickerErrorMessage(error));
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .uploadProfileImage(
            filePath: image.path,
            fileName: _fileNameFor(image),
          );

      if (!mounted) return;
      _showMessage('Profile picture updated');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _deleteProfileImage() async {
    if (_isBusy) return;

    final shouldDelete = await _confirmDeleteProfileImage();
    if (shouldDelete != true || !mounted) return;

    setState(() => _isDeletingImage = true);

    try {
      await ref.read(authControllerProvider.notifier).deleteProfileImage();

      if (!mounted) return;
      _showMessage('Profile picture removed');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isDeletingImage = false);
      }
    }
  }

  Future<bool?> _confirmDeleteProfileImage() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: Text(
            'Remove profile picture?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Your profile will use the default profile icon until you upload another picture.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14.sp,
              height: 1.4,
            ),
          ),
          actionsPadding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 14.h),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Remove',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveUsername() async {
    final username = _usernameController.text.trim();

    if (username.length < 2) {
      _showMessage('Username must be at least 2 characters');
      return;
    }

    if (username == _initialUsername) return;

    setState(() => _isSavingUsername = true);

    try {
      final session = await ref
          .read(authControllerProvider.notifier)
          .updateUsername(username);

      if (!mounted) return;

      _initialUsername = session.user.username.trim();
      _usernameController.text = _initialUsername;
      _showMessage('Username updated');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSavingUsername = false);
      }
    }
  }

  String _fileNameFor(XFile image) {
    final name = image.name.trim();
    if (name.isNotEmpty) return name;

    final pathName = image.path.split('/').last.trim();
    return pathName.isEmpty ? 'profile-image.jpg' : pathName;
  }

  String _pickerErrorMessage(PlatformException error) {
    return switch (error.code) {
      'already_active' => 'The photo picker is already open.',
      'photo_access_denied' || 'camera_access_denied' || 'permission_denied' =>
        'Allow photo access to update your profile picture.',
      'channel-error' =>
        'Photo picker is not ready. Restart the app and try again.',
      _ => 'Could not open photo picker. Please try again.',
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final session = authState.asData?.value;

    if (session == null) {
      return _EditProfileUnavailable(isLoading: authState.isLoading);
    }

    final user = session.user;
    _seedUsername(user);

    final username = _usernameController.text.trim();
    final canSaveUsername =
        username.isNotEmpty && username != _initialUsername && !_isBusy;

    return AppScaffold(
      usePadding: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 20.h),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.formMaxWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
                const AppScreenHeader(),
                SizedBox(height: 26.h),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Update your profile information.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 26.h),
                Text(
                  'Profile Picture',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 18.h),
                Center(
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ProfileAvatar(
                            profileUrl: user.profileUrl,
                            size: 146.w,
                            borderWidth: 2,
                            isBusy: _isUploadingImage || _isDeletingImage,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 10.h,
                            child: GestureDetector(
                              onTap: _isBusy ? null : _pickProfileImage,
                              child: Container(
                                width: 38.w,
                                height: 38.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.heroButton,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.heroButton.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 14.r,
                                      offset: Offset(0, 4.h),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 22.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Tap the camera icon to change\nyour profile picture.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (user.hasProfileImage) ...[
                        SizedBox(height: 10.h),
                        TextButton.icon(
                          onPressed: _isBusy ? null : _deleteProfileImage,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.danger,
                            size: 18.sp,
                          ),
                          label: Text(
                            _isDeletingImage ? 'Removing...' : 'Remove Photo',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Divider(color: AppColors.cardBorder),
                SizedBox(height: 8.h),
                Text(
                  'Username',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 14.h),
                AppTextField(
                  hintText: 'Username',
                  controller: _usernameController,
                  enabled: !_isSavingUsername,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.username],
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                SizedBox(height: 14.h),
                Text(
                  'This is the name other users will see on your profile.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 24.h),
                AppButton(
                  text: _isSavingUsername ? 'Saving...' : 'Save Changes',
                  height: 50.h,
                  borderRadius: AppRadius.sm,
                  backgroundColor: AppColors.heroButton,
                  borderColor: AppColors.heroButton,
                  fontSize: 18.sp,
                  icon: _isSavingUsername
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : null,
                  onPressed: canSaveUsername ? _saveUsername : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditProfileUnavailable extends StatelessWidget {
  final bool isLoading;

  const _EditProfileUnavailable({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: AppColors.primary)
            : Text(
                'Sign in to edit your profile.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14.sp,
                ),
              ),
      ),
    );
  }
}
