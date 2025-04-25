
import 'package:flutter/material.dart';

class DesktopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DesktopAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 品牌Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FlutterLogo(size: 32),
          ),
          // 顶部菜单项
          _buildMenuButton(context, '文件'),
          _buildMenuButton(context, '编辑'),
          _buildMenuButton(context, '查看'),
          _buildMenuButton(context, '帮助'),
          const Spacer(),
          // 右侧控制按钮
          _buildWindowControlButton(Icons.minimize),
          _buildWindowControlButton(Icons.crop_square),
          _buildWindowControlButton(Icons.close),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: () {},
      child: Text(text),
    );
  }

  Widget _buildWindowControlButton(IconData icon) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: () {},
      ),
    );
  }
}