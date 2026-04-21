import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/user_profile_provider.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isEditing = false;
  bool _initializedFromProfile = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userProfileControllerProvider.notifier).loadProfile(
            forceRefresh: true,
          );
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProfileControllerProvider);
    final profile = state.profile;

    if (profile != null && !_initializedFromProfile && !_isEditing) {
      _syncControllers(profile.fullName, profile.email ?? '');
      _initializedFromProfile = true;
    }

    if (profile != null && !_isEditing) {
      _syncControllers(profile.fullName, profile.email ?? '');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B2A4A),
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
        ),
        titleSpacing: 0,
        title: Text(
          _isEditing ? 'Edit Profile' : 'Profile',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: profile == null ? null : _startEditing,
              icon: const Icon(
                Icons.edit_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(userProfileControllerProvider.notifier)
                  .loadProfile(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _AvatarCircle(name: _fullNameController.text),
                      const SizedBox(height: 22),
                      _ProfileField(
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        controller: _fullNameController,
                        hintText: 'Enter full name',
                        readOnly: !_isEditing,
                      ),
                      const SizedBox(height: 14),
                      _ProfileField(
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        initialValue: profile?.phone ?? '',
                        helperText: 'Phone number cannot be changed',
                        readOnly: true,
                      ),
                      const SizedBox(height: 14),
                      _ProfileField(
                        label: 'Email Address (Optional)',
                        icon: Icons.mail_outline,
                        controller: _emailController,
                        hintText: 'Enter your email',
                        readOnly: !_isEditing,
                      ),
                      if (state.errorMessage != null &&
                          state.errorMessage!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (_isEditing) ...[
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: state.isSaving ? null : _saveChanges,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0B2A4A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: state.isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: state.isSaving ? null : _cancelEditing,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFC3CAD4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              foregroundColor: const Color(0xFF111827),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    final profile = ref.read(userProfileControllerProvider).profile;
    if (profile != null) {
      _syncControllers(profile.fullName, profile.email ?? '');
    }

    setState(() {
      _isEditing = false;
    });
  }

  Future<void> _saveChanges() async {
    if (!(_formKey.currentState?.validate() ?? true)) {
      return;
    }

    await ref.read(userProfileControllerProvider.notifier).completeProfile(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    final state = ref.read(userProfileControllerProvider);
    if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
      return;
    }

    setState(() {
      _isEditing = false;
      _initializedFromProfile = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  void _syncControllers(String fullName, String email) {
    if (_fullNameController.text != fullName) {
      _fullNameController.text = fullName;
    }
    if (_emailController.text != email) {
      _emailController.text = email;
    }
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF0B2A4A),
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: 2,
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFFF97316),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit, size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }

  String _initials(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'P';
    }
    final parts = text.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.isNotEmpty
          ? parts.first.substring(0, 1).toUpperCase()
          : 'P';
    }
    final first = parts.first.isNotEmpty ? parts.first.substring(0, 1) : 'P';
    final last = parts.last.isNotEmpty ? parts.last.substring(0, 1) : 'P';
    return '$first$last'.toUpperCase();
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.icon,
    this.controller,
    this.initialValue,
    this.hintText,
    this.helperText,
    this.readOnly = false,
  });

  final String label;
  final IconData icon;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? helperText;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE3EA)),
          ),
          child: TextFormField(
            controller: controller,
            initialValue: controller == null ? initialValue : null,
            readOnly: readOnly,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
              hintText: hintText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w500,
            ),
            validator: (value) {
              if (!readOnly && label == 'Full Name' && (value ?? '').trim().isEmpty) {
                return 'Full name is required';
              }
              return null;
            },
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ],
    );
  }
}