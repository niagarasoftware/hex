import 'package:flutter/material.dart';

class CustomSwitchRow extends StatelessWidget {
  final String iconPath;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomSwitchRow({
    super.key,
    required this.iconPath,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 500),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: value
                ? colorScheme.primaryContainer.withOpacity(0.45)
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: value ? colorScheme.primary : colorScheme.outlineVariant,
              width: value ? 1.2 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Center(
                  child: Image.asset(
                    iconPath,
                    width: 20,
                    height: 20,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: value
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: value ? FontWeight.bold : FontWeight.w600,
                        color: value ? colorScheme.primary : colorScheme.onSurface,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Transform.scale(
                scale: 0.65,
                child: Switch(
                  value: value,
                  activeThumbColor: colorScheme.onPrimary,
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.surfaceContainerHighest,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
