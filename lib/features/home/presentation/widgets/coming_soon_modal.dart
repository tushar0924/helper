import 'package:flutter/material.dart';

class ComingSoonModal extends StatelessWidget {
  const ComingSoonModal({
    super.key,
    this.onChangeLocation,
  });

  final VoidCallback? onChangeLocation;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'We Are\nComing Soon',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 28,
                height: 1.05,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We are currently living in select areas and expanding quickly. Services are not available in your location yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onChangeLocation,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1F3A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Change Location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Dismiss',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showComingSoonModal(
  BuildContext context, {
  VoidCallback? onChangeLocation,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => ComingSoonModal(
      onChangeLocation: onChangeLocation != null
          ? () {
              Navigator.of(dialogContext).pop();
              onChangeLocation();
            }
          : null,
    ),
  );
}
