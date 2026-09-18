import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class NumericInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final double? value;
  final ValueChanged<double> onChanged;
  final IconData? prefixIcon;
  final Color? color;
  final bool required;

  const NumericInputField({
    super.key,
    required this.label,
    this.hint,
    this.value,
    required this.onChanged,
    this.prefixIcon,
    this.color,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          hintText: hint ?? '0.00',
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
          prefixIconColor: color ?? theme.primaryColor,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
        ),
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        initialValue: value != null && value! > 0
            ? currencyFormat.format(value)
            : null,
        onChanged: (text) {
          final parsed = double.tryParse(text.replaceAll(',', '')) ?? 0.0;
          onChanged(parsed);
        },
        validator: (value) {
          if (value == null || value.isEmpty) return null;
          if (double.tryParse(value.replaceAll(',', '')) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }
}
