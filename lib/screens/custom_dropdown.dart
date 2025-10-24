import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isLoading;

  const CustomDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
      margin: EdgeInsets.symmetric(vertical: isTablet ? 10 : 6),
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12), // Curved corners
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: isTablet ? 6 : 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        hint: Text(
          hint,
          style: TextStyle(fontSize: isTablet ? 18 : 14),
        ),
        onChanged: isLoading ? null : onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: isTablet ? 20 : 16,
          ),
        ),
        style: TextStyle(
          fontSize: isTablet ? 16 : 14,
          color: Colors.black87,
        ),
        dropdownColor: Colors.white,
        icon: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.keyboard_arrow_down),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12), // Curved corners for dropdown menu
      ),
    );
  }
}