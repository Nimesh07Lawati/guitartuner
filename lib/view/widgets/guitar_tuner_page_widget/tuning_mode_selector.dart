import 'package:flutter/material.dart';
import '../../../../models/tuning_mode.dart';

/// Bottom sheet listing every tuning in [TuningMode.allModes].
///
/// Presented as a sheet rather than a dropdown in the header because the
/// list is long enough to need scrolling on small screens, and each row
/// carries two lines (name + string layout) that a dropdown item cramps.
class TuningModeSelector extends StatelessWidget {
  final TuningMode current;
  final ValueChanged<TuningMode> onSelect;

  const TuningModeSelector({
    super.key,
    required this.current,
    required this.onSelect,
  });

  /// Opens the sheet and reports the chosen mode. Does nothing if the user
  /// dismisses without picking.
  static Future<void> show(
    BuildContext context, {
    required TuningMode current,
    required ValueChanged<TuningMode> onSelect,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TuningModeSelector(current: current, onSelect: onSelect),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Tuning',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: TuningMode.allModes.length,
              itemBuilder: (_, i) {
                final mode = TuningMode.allModes[i];
                // Compared by name, not identity: the controller may hold a
                // mode rebuilt from storage rather than the canonical const.
                final selected = mode.name == current.name;

                return ListTile(
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelect(mode);
                  },
                  title: Text(
                    mode.name,
                    style: TextStyle(
                      color: selected ? Colors.orange : Colors.white,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    mode.description,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check, color: Colors.orange)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
