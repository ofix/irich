import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:irich/service/task_scheduler/task.dart';
import 'package:irich/service/task_scheduler/task_scheduler.dart';

class StateTaskList extends StateNotifier<List<Task>> {
  final TaskScheduler _scheduler;

  StateTaskList(this._scheduler) : super(_scheduler.allTasks()) {
    _scheduler.addListener(_updateState);
  }

  void _updateState() {
    state = [..._scheduler.allTasks()];
  }

  void selectTask(Task task) {
    _scheduler.selectTask(task);
  }

  Map<String, dynamic> get stats => _scheduler.stats;

  @override
  void dispose() {
    _scheduler.removeListener(_updateState);
    super.dispose();
  }
}

// 定义全局 TaskScheduler 单例 Provider
final taskSchedulerProvider = Provider<TaskScheduler>((ref) {
  return TaskScheduler(); // 创建单例实例
});

// 定义 StoreTaskList 的 StateNotifierProvider
final stateTaskListProvider = StateNotifierProvider<StateTaskList, List<Task>>((ref) {
  // 通过 ref.read 获取 TaskScheduler 实例
  final scheduler = ref.read(taskSchedulerProvider);
  return StateTaskList(scheduler); // 创建 StoreTaskList 并传入 scheduler
});

// 定义选中任务的 Provider
final selectedTaskProvider = Provider<Task?>((ref) {
  // 使用 select 监听 TaskScheduler 的 selectedTask 变化
  return ref.watch(taskSchedulerProvider.select((scheduler) => scheduler.selectedTask));
});

// 定义统计信息的 Provider
final statsProvider = Provider<Map<String, dynamic>>((ref) {
  // 从 StoreTaskList 的 notifier 获取统计信息
  return ref.watch(stateTaskListProvider.notifier).stats;
});
