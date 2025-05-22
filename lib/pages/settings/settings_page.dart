import 'package:flutter/material.dart';
import 'package:irich/components/desktop_layout.dart';
import 'package:irich/pages/settings/task_list_panel.dart';
import 'package:irich/pages/settings/task_logs_panel.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return DesktopLayout(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // 左侧任务列表
            const Expanded(flex: 3, child: TaskListPanel()),
            // 分隔线
            const VerticalDivider(width: 1),
            // 右侧日志列表
            const Expanded(flex: 7, child: TaskLogsPanel()),
          ],
        ),
      ),
    );
  }
}
