import 'package:flutter/material.dart';
import 'package:tourism_app/utils/colors.dart';

class DurationDropdown extends StatelessWidget {
  final String selectedDuration;
  final Function(String) onChanged;

  const DurationDropdown({
    super.key,
    required this.selectedDuration,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final List<String> durations = [
      '2 Hours',
      '4 Hours',
      '8 Hours',
      '12 Hours',
      '1 Day',
      '2 Day',
      '3 Day',
      '5 Day',
    ];

    return Container(
      height: size.height * 0.055,
      width: size.width * 0.3,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.whiteBar, width: 1.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          itemHeight: 50,
          borderRadius: BorderRadius.circular(15),
          value: selectedDuration,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.whiteBar,
            weight: 2,
          ),
          style: const TextStyle(
            color: AppColors.whiteBar,
            fontSize: 16,
          ),
          dropdownColor: AppColors.mutedElements.withValues(alpha: 0.6),
          items: durations.map((String duration) {
            return DropdownMenuItem<String>(
              value: duration,
              child: Text(
                duration,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}
