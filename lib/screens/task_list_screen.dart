import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import 'add_edit_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Lấy danh sách task khi màn hình được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar với hiệu ứng
          SliverAppBar(
            expandedHeight: 0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Task Manager', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24)),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              expandedTitleScale: 1.2,
            ),
            actions: [
              // Profile/Settings button
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                  onPressed: () => _showProfileMenu(context),
                ),
              ),
            ],
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm task, project, nhãn...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[400]),
                            onPressed: () {
                              _searchController.clear();
                              Provider.of<TaskProvider>(context, listen: false).clearSearch();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  onChanged: (value) {
                    Provider.of<TaskProvider>(context, listen: false).searchTasks(value);
                  },
                ),
              ),
            ),
          ),

          // Stats cards
          SliverToBoxAdapter(
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatsCard(
                          'Tổng cộng',
                          taskProvider.totalTasks.toString(),
                          Icons.list_alt,
                          const Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatsCard(
                          'Chờ xử lý',
                          taskProvider.pendingTasks.toString(),
                          Icons.schedule,
                          const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatsCard(
                          'Hoàn thành',
                          taskProvider.completedTasks.toString(),
                          Icons.check_circle,
                          const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Filter tabs
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildModernFilterChip(
                          'Tất cả',
                          TaskFilter.all,
                          taskProvider.currentFilter == TaskFilter.all,
                          Icons.list,
                        ),
                        const SizedBox(width: 8),
                        _buildModernFilterChip(
                          'Chờ xử lý',
                          TaskFilter.pending,
                          taskProvider.currentFilter == TaskFilter.pending,
                          Icons.schedule,
                        ),
                        const SizedBox(width: 8),
                        _buildModernFilterChip(
                          'Hoàn thành',
                          TaskFilter.completed,
                          taskProvider.currentFilter == TaskFilter.completed,
                          Icons.check_circle,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Task list
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              if (taskProvider.isLoading) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }

              if (taskProvider.tasks.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState(taskProvider));
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final task = taskProvider.tasks[index];
                  return TaskCard(task: task);
                }, childCount: taskProvider.tasks.length),
              );
            },
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditTaskScreen()));
          },
          backgroundColor: const Color(0xFFEF4444),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF202020)),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFilterChip(String label, TaskFilter filter, bool isSelected, IconData icon) {
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () {
        Provider.of<TaskProvider>(context, listen: false).filterTasks(filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300, width: 1),
          boxShadow: isSelected
              ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('Xóa task đã hoàn thành'),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await _showDeleteCompletedDialog();
                if (confirm) {
                  if (context.mounted) {
                    Provider.of<TaskProvider>(context, listen: false).deleteCompletedTasks();
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Làm mới'),
              onTap: () {
                Navigator.pop(context);
                Provider.of<TaskProvider>(context, listen: false).fetchTasks();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Cài đặt'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to settings
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(TaskProvider taskProvider) {
    String message;
    String subtitle;
    IconData icon;
    Color iconColor;

    if (taskProvider.searchQuery.isNotEmpty) {
      message = 'Không tìm thấy kết quả';
      subtitle = 'Thử tìm kiếm với từ khóa khác';
      icon = Icons.search_off_rounded;
      iconColor = Colors.grey[400]!;
    } else if (taskProvider.currentFilter == TaskFilter.completed) {
      message = 'Chưa có task nào hoàn thành';
      subtitle = 'Hoàn thành task đầu tiên để xem tại đây';
      icon = Icons.task_alt_rounded;
      iconColor = const Color(0xFF10B981);
    } else if (taskProvider.currentFilter == TaskFilter.pending) {
      message = 'Tuyệt vời!';
      subtitle = 'Bạn đã hoàn thành tất cả task';
      icon = Icons.celebration_rounded;
      iconColor = const Color(0xFFF59E0B);
    } else {
      message = 'Bắt đầu với task đầu tiên';
      subtitle = 'Tạo task để tổ chức công việc của bạn';
      icon = Icons.rocket_launch_rounded;
      iconColor = Theme.of(context).primaryColor;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 60, color: iconColor),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF202020)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (taskProvider.searchQuery.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  taskProvider.clearSearch();
                },
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Xóa tìm kiếm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[700],
                  elevation: 0,
                ),
              ),
            )
          else if (taskProvider.totalTasks == 0)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditTaskScreen()));
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tạo task đầu tiên'),
              ),
            ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteCompletedDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Xác nhận xóa'),
              content: const Text('Bạn có chắc chắn muốn xóa tất cả task đã hoàn thành?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
                TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Xóa')),
              ],
            );
          },
        ) ??
        false;
  }
}
