import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/cart_provider.dart';
import '../../modal/cart_summary_modal.dart';

Future<void> showSelectSlotBottomSheet(
  BuildContext context,
  CartSummaryModal summary,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SelectSlotSheet(summary: summary),
  );
}

class _SelectSlotSheet extends ConsumerStatefulWidget {
  const _SelectSlotSheet({required this.summary});

  final CartSummaryModal summary;

  @override
  ConsumerState<_SelectSlotSheet> createState() => _SelectSlotSheetState();
}

class _SelectSlotSheetState extends ConsumerState<_SelectSlotSheet> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;
  String? _selectedTime;

  static const List<String> _timeSlots = <String>[
    '06:00 AM',
    '07:00 AM',
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
    '07:00 PM',
    '08:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    final preselectedDate = _tryParseApiDate(widget.summary.slot.date);
    final preselectedTime = _toDisplayTime(widget.summary.slot.time);

    if (preselectedDate != null) {
      _focusedMonth = DateTime(preselectedDate.year, preselectedDate.month);
      _selectedDate = preselectedDate;
      _selectedTime = preselectedTime;
      return;
    }

    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final isMutating = ref.watch(cartProvider).isMutating;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F3F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 12),
              child: Column(
                children: [
                  _DateSelectorCard(
                    focusedMonth: _focusedMonth,
                    selectedDate: _selectedDate,
                    today: DateTime.now(),
                    onMonthChange: (month) {
                      setState(() {
                        _focusedMonth = month;
                      });
                    },
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                        if (_selectedTime != null &&
                            !_isTimeSlotAvailable(
                              date,
                              _selectedTime!,
                              DateTime.now(),
                            )) {
                          _selectedTime = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _TimeSelectorCard(
                    selectedDate: _selectedDate,
                    selectedTime: _selectedTime,
                    isSlotEnabled: (time) {
                      if (_selectedDate == null) {
                        return false;
                      }
                      return _isTimeSlotAvailable(_selectedDate!, time, DateTime.now());
                    },
                    onTimeSelected: (time) {
                      setState(() {
                        _selectedTime = time;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            bottom: false,
            minimum: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: _selectedDate == null || _selectedTime == null
                        || isMutating
                    ? null
                    : () async {
                        final date = _selectedDate!;
                        final time = _selectedTime!;

                        await ref
                            .read(cartProvider.notifier)
                            .updateSlot(
                              date: _toApiDate(date),
                              time: _toApiTime(time),
                            );

                        if (!mounted) {
                          return;
                        }

                        final hasError = ref.read(cartProvider).errorMessage != null;
                        if (hasError) {
                          return;
                        }

                        Navigator.of(context).pop();
                      },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF0B1F3A),
                  disabledBackgroundColor: const Color(0xFF8C98A8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isMutating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isTimeSlotAvailable(DateTime date, String slot, DateTime now) {
    final selectedDay = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);

    if (selectedDay.isBefore(today)) {
      return false;
    }

    if (selectedDay.isAfter(today)) {
      return true;
    }

    final slotMinutes = _slotToMinutes(slot);
    final nowMinutes = now.hour * 60 + now.minute;
    return slotMinutes > nowMinutes;
  }

  int _slotToMinutes(String slot) {
    final pieces = slot.split(' ');
    if (pieces.length != 2) {
      return 0;
    }

    final timeParts = pieces[0].split(':');
    if (timeParts.length != 2) {
      return 0;
    }

    var hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;
    final period = pieces[1].toUpperCase();

    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return hour * 60 + minute;
  }
}

DateTime? _tryParseApiDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return null;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

String _toApiDate(DateTime date) {
  final yyyy = date.year.toString().padLeft(4, '0');
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd';
}

String _toApiTime(String displayTime) {
  final totalMinutes = _displaySlotToMinutes(displayTime);
  final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
  final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
  return '$hours:$minutes';
}

int _displaySlotToMinutes(String slot) {
  final pieces = slot.split(' ');
  if (pieces.length != 2) {
    return 0;
  }

  final timeParts = pieces[0].split(':');
  if (timeParts.length != 2) {
    return 0;
  }

  var hour = int.tryParse(timeParts[0]) ?? 0;
  final minute = int.tryParse(timeParts[1]) ?? 0;
  final period = pieces[1].toUpperCase();

  if (period == 'PM' && hour != 12) {
    hour += 12;
  } else if (period == 'AM' && hour == 12) {
    hour = 0;
  }

  return hour * 60 + minute;
}

String? _toDisplayTime(String? apiTime) {
  if (apiTime == null || apiTime.trim().isEmpty) {
    return null;
  }

  final parts = apiTime.split(':');
  if (parts.length < 2) {
    return null;
  }

  final hour24 = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour24 == null || minute == null) {
    return null;
  }

  var hour12 = hour24 % 12;
  if (hour12 == 0) {
    hour12 = 12;
  }
  final period = hour24 >= 12 ? 'PM' : 'AM';
  return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
}

class _DateSelectorCard extends StatelessWidget {
  const _DateSelectorCard({
    required this.focusedMonth,
    required this.selectedDate,
    required this.today,
    required this.onMonthChange,
    required this.onDateSelected,
  });

  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final DateTime today;
  final ValueChanged<DateTime> onMonthChange;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final monthName = _monthName(focusedMonth.month);
    final gridDays = _calendarGridDays(focusedMonth);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9DEE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF111827),
              ),
              SizedBox(width: 8),
              Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MonthArrow(
                icon: Icons.chevron_left,
                onTap: () {
                  onMonthChange(
                    DateTime(focusedMonth.year, focusedMonth.month - 1),
                  );
                },
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$monthName ${focusedMonth.year}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ),
              _MonthArrow(
                icon: Icons.chevron_right,
                onTap: () {
                  onMonthChange(
                    DateTime(focusedMonth.year, focusedMonth.month + 1),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _WeekDayLabel('Su'),
              _WeekDayLabel('Mo'),
              _WeekDayLabel('Tu'),
              _WeekDayLabel('We'),
              _WeekDayLabel('Th'),
              _WeekDayLabel('Fr'),
              _WeekDayLabel('Sa'),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            itemCount: gridDays.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 33,
            ),
            itemBuilder: (context, index) {
              final day = gridDays[index];
              final dayOnly = DateTime(day.year, day.month, day.day);
              final todayOnly = DateTime(today.year, today.month, today.day);
              final isSelected =
                  selectedDate != null &&
                  selectedDate!.year == day.year &&
                  selectedDate!.month == day.month &&
                  selectedDate!.day == day.day;
              final isCurrentMonth = day.month == focusedMonth.month;
              final isPast = dayOnly.isBefore(todayOnly);
              final isDisabled = !isCurrentMonth || isPast;

              return GestureDetector(
                onTap: isDisabled ? null : () => onDateSelected(day),
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected && !isDisabled
                          ? const Color(0xFF0B1F3A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 12,
                            fontWeight: isSelected && !isDisabled
                              ? FontWeight.w600
                              : FontWeight.w500,
                            color: isSelected && !isDisabled
                              ? Colors.white
                              : isDisabled
                              ? const Color(0xFFB7BEC9)
                              : isCurrentMonth
                              ? const Color(0xFF111827)
                              : const Color(0xFFA0A7B2),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TimeSelectorCard extends StatelessWidget {
  const _TimeSelectorCard({
    required this.selectedDate,
    required this.selectedTime,
    required this.isSlotEnabled,
    required this.onTimeSelected,
  });

  final DateTime? selectedDate;
  final String? selectedTime;
  final bool Function(String time) isSlotEnabled;
  final ValueChanged<String> onTimeSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9DEE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Color(0xFF111827)),
              SizedBox(width: 8),
              Text(
                'Select Arriving Time',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _SelectSlotSheetState._timeSlots
                .map((time) {
                  final isEnabled = selectedDate != null && isSlotEnabled(time);
                  final isSelected = selectedTime == time && isEnabled;
                  return GestureDetector(
                    onTap: isEnabled ? () => onTimeSelected(time) : null,
                    child: Container(
                      width: 71,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0B1F3A)
                            : isEnabled
                            ? const Color(0xFFE8EBEF)
                            : const Color(0xFFF0F3F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white
                                : isEnabled
                                ? const Color(0xFF111827)
                                : const Color(0xFFB7BEC9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _WeekDayLabel extends StatelessWidget {
  const _WeekDayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF8B93A0),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE0E5EB)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF9AA3AF)),
      ),
    );
  }
}

List<DateTime> _calendarGridDays(DateTime focusedMonth) {
  final firstOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
  final startOffset = firstOfMonth.weekday % 7;
  final startDate = firstOfMonth.subtract(Duration(days: startOffset));

  return List<DateTime>.generate(
    42,
    (index) => DateTime(startDate.year, startDate.month, startDate.day + index),
    growable: false,
  );
}

String _monthName(int month) {
  const names = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return names[month - 1];
}
