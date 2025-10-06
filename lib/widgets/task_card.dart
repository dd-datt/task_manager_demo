import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../screens/add_edit_task_screen.dart';

class TaskCard extends StatefulWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final primaryColor = Theme.of(context).primaryColor;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Dismissible(
              key: Key(widget.task.id.toString()),
              direction: DismissDirection.endToStart,
              background: _buildDismissBackground(),
              confirmDismiss: (direction) => _showDeleteConfirmDialog(context),
              onDismissed: (direction) => _handleDelete(context, taskProvider),
              child: GestureDetector(
                onTapDown: (_) {
                  _animationController.forward();
                },
                onTapUp: (_) {
                  _animationController.reverse();
                },
                onTapCancel: () {
                  _animationController.reverse();
                },
                onTap: () => _navigateToEdit(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.task.isDone ? Colors.grey.shade200 : Colors.grey.shade300,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: _buildTaskContent(context, taskProvider, primaryColor),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskContent(BuildContext context, TaskProvider taskProvider, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => taskProvider.toggleTaskStatus(widget.task),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.task.isDone ? primaryColor : Colors.grey.shade400, width: 2),
                color: widget.task.isDone ? primaryColor : Colors.transparent,
              ),
              child: widget.task.isDone ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
          ),

          const SizedBox(width: 12),

          // Task content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.task.isDone ? Colors.grey.shade500 : const Color(0xFF202020),
                    decoration: widget.task.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                    decorationColor: Colors.grey.shade500,
                  ),
                  child: Text(widget.task.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                ),

                // Description
                if (widget.task.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.task.isDone ? Colors.grey.shade400 : Colors.grey.shade600,
                      decoration: widget.task.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                      decorationColor: Colors.grey.shade400,
                    ),
                    child: Text(widget.task.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                  ),
                ],

                const SizedBox(height: 12),

                // Footer with date and actions
                Row(
                  children: [
                    // Date
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(widget.task.createdAt),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Priority indicator (if needed)
                    if (!widget.task.isDone)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: _getPriorityColor()),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // More actions button
          GestureDetector(
            onTap: () => _showTaskMenu(context, taskProvider),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          const Text(
            'Xóa',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return DateFormat('HH:mm').format(date);
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'Hôm qua';
    } else if (date.year == now.year) {
      return DateFormat('dd/MM').format(date);
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }

  Color _getPriorityColor() {
    // You can customize this based on task priority logic
    return widget.task.isDone ? Colors.green : Theme.of(context).primaryColor.withOpacity(0.7);
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa task'),
        content: Text('Bạn có chắc chắn muốn xóa "${widget.task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _handleDelete(BuildContext context, TaskProvider taskProvider) {
    taskProvider.deleteTask(widget.task.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa "${widget.task.title}"'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Hoàn tác',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Implement undo functionality
          },
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditTaskScreen(task: widget.task)));
  }

  void _showTaskMenu(BuildContext context, TaskProvider taskProvider) {
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
              leading: Icon(
                widget.task.isDone ? Icons.undo_rounded : Icons.check_rounded,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(widget.task.isDone ? 'Đánh dấu chưa xong' : 'Đánh dấu hoàn thành'),
              onTap: () {
                Navigator.pop(context);
                taskProvider.toggleTaskStatus(widget.task);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEdit(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444)),
              title: const Text('Xóa', style: TextStyle(color: Color(0xFFEF4444))),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await _showDeleteConfirmDialog(context);
                if (confirm == true && context.mounted) {
                  _handleDelete(context, taskProvider);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
