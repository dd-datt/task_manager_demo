import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../database/database_helper.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = false;
  String _searchQuery = '';
  TaskFilter _currentFilter = TaskFilter.all;

  List<Task> get tasks => _filteredTasks;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  TaskFilter get currentFilter => _currentFilter;

  // Lấy số lượng task theo trạng thái
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((task) => task.isDone).length;
  int get pendingTasks => _tasks.where((task) => !task.isDone).length;

  // Khởi tạo và lấy danh sách task từ database
  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _databaseHelper.getTasks();
      _applyFilter();
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Thêm task mới
  Future<void> addTask(Task task) async {
    try {
      final id = await _databaseHelper.insertTask(task);
      final newTask = task.copyWith(id: id);
      _tasks.insert(0, newTask);
      _applyFilter();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding task: $e');
      rethrow;
    }
  }

  // Cập nhật task
  Future<void> updateTask(Task task) async {
    try {
      await _databaseHelper.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        _applyFilter();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  // Xóa task
  Future<void> deleteTask(int id) async {
    try {
      await _databaseHelper.deleteTask(id);
      _tasks.removeWhere((task) => task.id == id);
      _applyFilter();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  // Đánh dấu task hoàn thành/chưa hoàn thành
  Future<void> toggleTaskStatus(Task task) async {
    final updatedTask = task.copyWith(isDone: !task.isDone);
    await updateTask(updatedTask);
  }

  // Xóa tất cả task đã hoàn thành
  Future<void> deleteCompletedTasks() async {
    try {
      await _databaseHelper.deleteCompletedTasks();
      _tasks.removeWhere((task) => task.isDone);
      _applyFilter();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting completed tasks: $e');
      rethrow;
    }
  }

  // Tìm kiếm task
  void searchTasks(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  // Lọc task theo trạng thái
  void filterTasks(TaskFilter filter) {
    _currentFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  // Áp dụng filter và search
  void _applyFilter() {
    List<Task> filtered = List.from(_tasks);

    // Áp dụng search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            task.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Áp dụng filter theo trạng thái
    switch (_currentFilter) {
      case TaskFilter.completed:
        filtered = filtered.where((task) => task.isDone).toList();
        break;
      case TaskFilter.pending:
        filtered = filtered.where((task) => !task.isDone).toList();
        break;
      case TaskFilter.all:
        break;
    }

    _filteredTasks = filtered;
  }

  // Xóa search query
  void clearSearch() {
    _searchQuery = '';
    _applyFilter();
    notifyListeners();
  }

  // Reset filter về tất cả
  void clearFilter() {
    _currentFilter = TaskFilter.all;
    _applyFilter();
    notifyListeners();
  }
}

enum TaskFilter { all, pending, completed }
