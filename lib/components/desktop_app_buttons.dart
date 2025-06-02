import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class DesktopAppButtons extends StatefulWidget {
  const DesktopAppButtons({super.key});

  @override
  State<DesktopAppButtons> createState() => _DesktopAppButtonsState();
}

class _DesktopAppButtonsState extends State<DesktopAppButtons> {
  bool isMaximized = false;

  Future<void> toggleMaximize() async {
    if (isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
    setState(() {
      isMaximized = !isMaximized;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(icon: Icon(Icons.minimize, size: 16), onPressed: () => windowManager.minimize()),
        IconButton(
          icon: Icon(isMaximized ? Icons.filter_none : Icons.crop_square, size: 16),
          onPressed: toggleMaximize,
        ),
        IconButton(icon: Icon(Icons.close, size: 16), onPressed: () => windowManager.close()),
      ],
    );
  }
}
