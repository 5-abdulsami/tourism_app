import 'package:flutter/material.dart';
import 'package:tourism_app/utils/colors.dart';

class DurationDropdown extends StatelessWidget {
  final String selectedDuration;
  final Function(String) onChanged;

  const DurationDropdown({
    Key? key,
    required this.selectedDuration,
    required this.onChanged,
  }) : super(key: key);

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
        border: Border.all(color: whiteColor, width: 1.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          itemHeight: 50,
          borderRadius: BorderRadius.circular(15),
          value: selectedDuration,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white,
            weight: 2,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          dropdownColor: skyBlueColor.withOpacity(0.6),
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
