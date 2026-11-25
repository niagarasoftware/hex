import 'package:flutter/material.dart';
import '../../../../utils/Theme/oro_theme.dart';

class SlidingSendButton extends StatefulWidget {
  final Function onSend;

  const SlidingSendButton({super.key, required this.onSend});

  @override
  State<SlidingSendButton> createState() => _SlidingSendButtonState();
}

class _SlidingSendButtonState extends State<SlidingSendButton> {
  double _dragPosition = 0.0;
  final double _maxDragDistance = 200.0;
  IconData icon = Icons.send;
  bool isSent = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          if (!isSent) {
            _dragPosition += details.delta.dx;
            _dragPosition = _dragPosition.clamp(0.0, _maxDragDistance);
          }
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragPosition == _maxDragDistance) {
          widget.onSend();
          setState(() {
            isSent = true;
            icon = Icons.done;
          });
        }
      },
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Background track
          Container(
            width: _maxDragDistance + 50,
            height: 50,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          // "Slide to Send" text
          Positioned(
            left: isSent ? 100 : 70,
            child: Text(
              isSent ? "Sent!" : "-- Slide to Send -->",
              style: TextStyle(
                color: isSent ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          // Sliding button with animation
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            left: _dragPosition,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSent ? colorScheme.tertiary : colorScheme.primary,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: isSent ? colorScheme.onTertiary : colorScheme.onPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
