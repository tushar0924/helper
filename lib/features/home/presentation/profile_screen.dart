import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../../../routes/app_router.dart';
import 'user_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameFuture = ref.read(sessionManagerProvider).fullName;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B2A4A),
        elevation: 0,
        toolbarHeight: 68,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        ),
        titleSpacing: 0,
        title: FutureBuilder<String?>(
          future: nameFuture,
          builder: (context, snapshot) {
            final name = snapshot.data?.trim().isNotEmpty == true
                ? snapshot.data!.trim()
                : 'Profile';
            return Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _ProfileMenuTile(
                    icon: Icons.person_outline,
                    iconBg: const Color(0xFFFF5E14),
                    title: 'Profile',
                    subtitle: 'Manage your profile',
                    onTap: () => _openProfile(context),
                  ),
                  const _MenuDivider(),
                  _ProfileMenuTile(
                    icon: Icons.home_outlined,
                    iconBg: const Color(0xFFC78100),
                    title: 'Addresses',
                    subtitle: 'Manage saved addresses',
                    onTap: _noop,
                  ),
                  const _MenuDivider(),
                  _ProfileMenuTile(
                    icon: Icons.menu_book_outlined,
                    iconBg: const Color(0xFF0A8A2A),
                    title: 'Booking & Orders',
                    subtitle: 'View your past booking & orders',
                    onTap: _noop,
                  ),
                  const _MenuDivider(),
                  _ProfileMenuTile(
                    icon: Icons.description_outlined,
                    iconBg: const Color(0xFF1D58E5),
                    title: 'Policies',
                    subtitle: 'Terms of use, Privacy policy and others',
                    onTap: _noop,
                  ),
                  const _MenuDivider(),
                  _ProfileMenuTile(
                    icon: Icons.chat_bubble_outline,
                    iconBg: const Color(0xFFA855F7),
                    title: 'Help & support',
                    subtitle: 'Reach out to us in case you have\na question',
                    onTap: _noop,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRouter.login,
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(vertical: 15),
                side: const BorderSide(color: Color(0xFFC3CAD4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: const Color(0xFF111827),
              ),
              icon: const Icon(Icons.logout, size: 19),
              label: const Text(
                'Log out',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF94A3B8),
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFEAECEF)),
    );
  }
}

void _noop() {}

void _openProfile(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const UserProfileScreen(),
    ),
  );
}
