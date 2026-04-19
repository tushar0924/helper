import 'package:flutter/material.dart';

Future<void> showSelectSlotBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SelectSlotSheet(),
  );
}

class _SelectSlotSheet extends StatefulWidget {
  const _SelectSlotSheet();

  @override
  State<_SelectSlotSheet> createState() => _SelectSlotSheetState();
}

class _SelectSlotSheetState extends State<_SelectSlotSheet> {
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
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F3F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Column(
                children: [
                  _DateSelectorCard(
                    focusedMonth: _focusedMonth,
                    selectedDate: _selectedDate,
                    onMonthChange: (month) {
                      setState(() {
                        _focusedMonth = month;
                      });
                    },
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  _TimeSelectorCard(
                    selectedTime: _selectedTime,
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
            minimum: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: _selectedDate == null || _selectedTime == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Slot selected: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} $_selectedTime',
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF7B8796),
                  disabledBackgroundColor: const Color(0xFF8C98A8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
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
}

class _DateSelectorCard extends StatelessWidget {
  const _DateSelectorCard({
    required this.focusedMonth,
    required this.selectedDate,
    required this.onMonthChange,
    required this.onDateSelected,
  });

  final DateTime focusedMonth;
  final DateTime? selectedDate;
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
              final isSelected =
                  selectedDate != null &&
                  selectedDate!.year == day.year &&
                  selectedDate!.month == day.month &&
                  selectedDate!.day == day.day;
              final isCurrentMonth = day.month == focusedMonth.month;

              return GestureDetector(
                onTap: () => onDateSelected(day),
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0B1F3A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
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
    required this.selectedTime,
    required this.onTimeSelected,
  });

  final String? selectedTime;
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
                  final isSelected = selectedTime == time;
                  return GestureDetector(
                    onTap: () => onTimeSelected(time),
                    child: Container(
                      width: 71,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0B1F3A)
                            : const Color(0xFFE8EBEF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          time,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF111827),
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
