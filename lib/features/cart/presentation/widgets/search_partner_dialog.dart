import 'package:flutter/material.dart';

Future<void> showSearchPartnerDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => const _SearchPartnerDialog(),
  );
}

class _SearchPartnerDialog extends StatelessWidget {
  const _SearchPartnerDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF1F3F6),
              ),
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE5E7EB),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 26,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0097D5)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sending requests to nearby helpers...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please wait while we connect you with the\nbest helper',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 18),
            const _GhostPartnerRow(distance: '0.5 km'),
            const SizedBox(height: 10),
            const _GhostPartnerRow(distance: '1.1 km'),
            const SizedBox(height: 10),
            const _GhostPartnerRow(distance: '1.5 km'),
          ],
        ),
      ),
    );
  }
}

class _GhostPartnerRow extends StatelessWidget {
  const _GhostPartnerRow({required this.distance});

  final String distance;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              size: 15,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            distance,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
