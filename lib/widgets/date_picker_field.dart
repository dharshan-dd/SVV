import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onDateSelected;
  final bool required;

  const DatePickerField({
    super.key,
    required this.label,
    this.date,
    required this.onDateSelected,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today_rounded),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(
          date != null ? dateFormat.format(date!) : 'Select date',
          style: TextStyle(
            color: date != null
                ? theme.colorScheme.onSurface
                : theme.hintColor,
          ),
        ),
      ),
    );
  }
}
