import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/utils/app_toast.dart';
import '../../../routes/app_router.dart';
import '../application/auth_provider.dart';
import '../data/auth_models.dart';
import 'widgets/auth_top_banner.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedGender = 'Female';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _prefillFromUser(AuthUser? user) {
    if (user == null) {
      return;
    }

    if (_nameController.text.trim().isEmpty &&
        user.fullName.trim().isNotEmpty) {
      _nameController.text = user.fullName.trim();
    }

    if (_emailController.text.trim().isEmpty && user.email.trim().isNotEmpty) {
      _emailController.text = user.email.trim();
    }

    if (user.gender.trim().isNotEmpty) {
      final normalized = user.gender.trim().toLowerCase();
      if (normalized == 'male') {
        _selectedGender = 'Male';
      } else if (normalized == 'female') {
        _selectedGender = 'Female';
      } else {
        _selectedGender = 'Other';
      }
    }
  }

  bool _isValidEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return true;
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(trimmed);
  }

  Future<void> _onContinueTap() async {
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (fullName.isEmpty) {
      AppToast.error('Please enter your full name');
      return;
    }

    if (!_isValidEmail(email)) {
      AppToast.error('Please enter a valid email address');
      return;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .completeProfile(
            fullName: fullName,
            gender: _selectedGender,
            email: email,
          );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRouter.home, (route) => false);
    } catch (error) {
      if (!mounted) {
        return;
      }

      AppToast.error(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final args = ModalRoute.of(context)?.settings.arguments;
    final authUser = args is AuthUser ? args : null;
    _prefillFromUser(authUser);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0F2A47),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F2A47),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              Container(child: const AuthTopBanner()),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 22,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PERSONAL INFO',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "What's your name?",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Help us personalize your experience.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Full Name',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'Enter your full name',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFE9EDF1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Email (Optional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.mail_outline,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFE9EDF1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _GenderChip(
                              label: 'Male',
                              selected: _selectedGender == 'Male',
                              icon: Icons.male,
                              onTap: () {
                                setState(() {
                                  _selectedGender = 'Male';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _GenderChip(
                              label: 'Female',
                              selected: _selectedGender == 'Female',
                              icon: Icons.female,
                              onTap: () {
                                setState(() {
                                  _selectedGender = 'Female';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            _GenderChip(
                              label: 'Other',
                              selected: _selectedGender == 'Other',
                              icon: Icons.circle_outlined,
                              onTap: () {
                                setState(() {
                                  _selectedGender = 'Other';
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: authState.isLoading
                                ? null
                                : _onContinueTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F2A47),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: authState.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Continue  >',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Enter your name & email to continue',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'By continuing, you agree to our ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                TextSpan(
                                  text: 'Trust & Safety Policy',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                    decoration: TextDecoration.underline,
                                    decorationColor: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
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

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0F2A47) : const Color(0xFFDCE3EB),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
