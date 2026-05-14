import 'package:flutter/material.dart';
import '../../../utils/theme_preset.dart';

class ThemePresetPicker extends StatefulWidget {
  final String selectedId;
  final ValueChanged<String> onSelect;

  const ThemePresetPicker({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  State<ThemePresetPicker> createState() => _ThemePresetPickerState();
}

class _ThemePresetPickerState extends State<ThemePresetPicker> {
  late bool _show3Color;

  @override
  void initState() {
    super.initState();
    final preset = ThemePreset.findById(widget.selectedId);
    _show3Color = preset?.isThreeColor ?? false;
  }

  @override
  void didUpdateWidget(covariant ThemePresetPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) {
      final preset = ThemePreset.findById(widget.selectedId);
      if (preset != null) setState(() => _show3Color = preset.isThreeColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = _show3Color ? ThemePreset.threeColor : ThemePreset.twoColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniTab(
                    label: '2-Color',
                    selected: !_show3Color,
                    onTap: () => setState(() => _show3Color = false),
                  ),
                  _MiniTab(
                    label: '3-Color',
                    selected: _show3Color,
                    onTap: () => setState(() => _show3Color = true),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: presets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final preset = presets[i];
              final isSelected = preset.id == widget.selectedId;
              return GestureDetector(
                onTap: () => widget.onSelect(preset.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color.lerp(Colors.white, preset.accent, 0.10)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? preset.accent : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: preset.accent.withAlpha(40), blurRadius: 6, offset: const Offset(0, 2))]
                        : [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 3)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ColorDot(color: preset.accent, size: 11),
                      const SizedBox(width: 3),
                      _ColorDot(color: preset.secondary, size: 11),
                      if (preset.tertiary != null) ...[
                        const SizedBox(width: 3),
                        _ColorDot(color: preset.tertiary!, size: 11),
                      ],
                      const SizedBox(width: 7),
                      Text(
                        preset.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? preset.accent : const Color(0xFF444444),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check_rounded, size: 12, color: preset.accent),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MiniTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF1A1A2E) : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final double size;

  const _ColorDot({required this.color, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
