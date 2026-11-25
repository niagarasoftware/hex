import 'package:flutter/material.dart';

enum ArrowTabState {complete, inComplete, onProgress}

class ArrowTab extends StatelessWidget {
  final int index;
  final String title;
  final ArrowTabState arrowTabState;
  const ArrowTab({super.key, required this.index, required this.title, required this.arrowTabState});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedContainer(
          width: arrowTabState == ArrowTabState.onProgress ? 200 : 180,
          duration: const Duration(milliseconds: 500),
          child: Image.asset(
              width: 180,
              height: 50,
              fit: BoxFit.fill,
              color: getImageColor(context),
              colorBlendMode: BlendMode.modulate,
              'assets/Images/Png/arrow.png'
          ),
        ),
        getAvatarAndName(context),
      ],
    );
  }

  Widget getAvatarAndName(BuildContext context){
    final colorScheme = Theme.of(context).colorScheme;
    final isProgress = arrowTabState == ArrowTabState.onProgress;
    final textColor = isProgress ? colorScheme.onPrimary : colorScheme.onSurface;

    return Positioned(
      top: 10,
      left: 20,
      child: SizedBox(
        width: 180,
        child: Row(
          spacing: 10,
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: getAvatarColor(context),
              child: Center(
                child: Text('${index+1}', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14 ,overflow: TextOverflow.ellipsis, color: isProgress ? colorScheme.onPrimaryContainer : colorScheme.onSurface)),
              ),
            ),
            Expanded(
                child: Text(title, style: TextStyle(fontWeight: FontWeight.bold,fontSize: 14 ,overflow: TextOverflow.ellipsis, color: textColor),)
            )
          ],
        ),
      ),
    );
  }

  Color getImageColor(BuildContext context){
    final colorScheme = Theme.of(context).colorScheme;
    return arrowTabState == ArrowTabState.complete
        ? colorScheme.outlineVariant
        : arrowTabState == ArrowTabState.onProgress
        ? colorScheme.primary : colorScheme.surface;
  }

  Color getAvatarColor(BuildContext context){
    final colorScheme = Theme.of(context).colorScheme;
    return arrowTabState == ArrowTabState.complete
        ? colorScheme.surface
        : arrowTabState == ArrowTabState.onProgress
        ? colorScheme.primaryContainer : colorScheme.outlineVariant;
  }
}
