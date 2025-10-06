import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task;

  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  bool _isDone = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    // Start animation
    _animationController.forward();

    if (_isEditing) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _isDone = widget.task!.isDone;
    } else {
      // Auto focus title for new task
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

      if (_isEditing) {
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          isDone: _isDone,
        );
        await taskProvider.updateTask(updatedTask);

        if (mounted) {
          _showSuccessMessage('Task đã được cập nhật!');
        }
      } else {
        final newTask = Task(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          isDone: _isDone,
        );
        await taskProvider.addTask(newTask);

        if (mounted) {
          _showSuccessMessage('Task mới đã được tạo!');
        }
      }

      if (mounted) {
        await _animationController.reverse();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Đã xảy ra lỗi: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * _slideAnimation.value),
            child: Opacity(opacity: 1 - _slideAnimation.value, child: _buildBody()),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () async {
          await _animationController.reverse();
          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
      title: Text(
        _isEditing ? 'Chỉnh sửa task' : 'Task mới',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      actions: [
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else
          TextButton(
            onPressed: _saveTask,
            child: Text(
              _isEditing ? 'Cập nhật' : 'Lưu',
              style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title input
                  _buildTitleInput(),

                  const SizedBox(height: 20),

                  // Description input
                  _buildDescriptionInput(),

                  const SizedBox(height: 24),

                  // Status toggle (only for editing)
                  if (_isEditing) ...[_buildStatusToggle(), const SizedBox(height: 32)],
                ],
              ),
            ),
          ),

          // Bottom action area
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildTitleInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: TextFormField(
        controller: _titleController,
        focusNode: _titleFocusNode,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Tên task...',
          hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(20),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.task_alt_rounded, color: Theme.of(context).primaryColor, size: 20),
          ),
        ),
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) {
          _descriptionFocusNode.requestFocus();
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Vui lòng nhập tên task';
          }
          if (value.trim().length < 2) {
            return 'Tên task phải có ít nhất 2 ký tự';
          }
          return null;
        },
        maxLength: 100,
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
          return Container(
            padding: const EdgeInsets.only(top: 8, right: 12),
            alignment: Alignment.centerRight,
            child: Text('$currentLength/${maxLength ?? 0}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          );
        },
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: TextFormField(
        controller: _descriptionController,
        focusNode: _descriptionFocusNode,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Mô tả chi tiết (tùy chọn)...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(20),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.description_rounded, color: Colors.grey[600], size: 20),
          ),
          alignLabelWithHint: true,
        ),
        maxLines: 4,
        textInputAction: TextInputAction.done,
        maxLength: 500,
        buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
          return Container(
            padding: const EdgeInsets.only(top: 8, right: 12),
            alignment: Alignment.centerRight,
            child: Text('$currentLength/${maxLength ?? 0}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          );
        },
      ),
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: SwitchListTile(
        title: const Text('Trạng thái task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        subtitle: Text(
          _isDone ? 'Đã hoàn thành' : 'Chưa hoàn thành',
          style: TextStyle(color: _isDone ? const Color(0xFF10B981) : Colors.orange, fontWeight: FontWeight.w500),
        ),
        value: _isDone,
        onChanged: (bool value) {
          setState(() {
            _isDone = value;
          });
        },
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (_isDone ? const Color(0xFF10B981) : Colors.orange).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _isDone ? Icons.check_circle_rounded : Icons.schedule_rounded,
            color: _isDone ? const Color(0xFF10B981) : Colors.orange,
          ),
        ),
        activeColor: const Color(0xFF10B981),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isEditing ? Icons.update_rounded : Icons.add_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isEditing ? 'Cập nhật task' : 'Tạo task',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        await _animationController.reverse();
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Hủy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
