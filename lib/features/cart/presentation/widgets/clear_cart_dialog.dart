import 'package:flutter/material.dart';

Future<bool> showClearCartDialog(
  BuildContext context, {
  required Future<void> Function() onConfirm,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      var isClearing = false;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Clear cart?',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Are you sure you want to clear your cart?',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: FilledButton(
                            onPressed: isClearing
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isClearing = true;
                                    });
                                    await onConfirm();
                                    if (!dialogContext.mounted) {
                                      return;
                                    }
                                    Navigator.of(dialogContext).pop(true);
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF071B33),
                              disabledBackgroundColor:
                                  const Color(0xFF071B33),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: isClearing
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Yes',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: FilledButton(
                            onPressed: isClearing
                                ? null
                                : () {
                                    Navigator.of(dialogContext).pop(false);
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFD7D7D7),
                              foregroundColor: const Color(0xFF111827),
                              disabledBackgroundColor:
                                  const Color(0xFFD7D7D7),
                              disabledForegroundColor:
                                  const Color(0xFF111827),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: const Text(
                              'No',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );

  return result == true;
}
