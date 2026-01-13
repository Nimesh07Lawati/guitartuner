import 'package:flutter/material.dart';

class TuningButton extends StatelessWidget {
  final bool isTuning;
  final VoidCallback onPressed;

  const TuningButton({
    super.key,
    required this.isTuning,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          isTuning ? 'Stop Tuning' : 'Start Tuning',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
