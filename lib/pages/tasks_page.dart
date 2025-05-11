import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key}); // 1. Tambahkan key parameter

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> tasks = []; // 2. Buat final
  String filter = 'All';
  late final TextEditingController _searchController;
  late final AnimationController _animationController;

  // Variabel state lainnya
  final String _selectedCategory = 'Umum'; // 3. Buat final
  DateTime? selectedDeadline; // 4. Gunakan atau hapus
  String _searchQuery = '';
  bool _isSearching = false;

  // Category colors - dibuat final
  final Map<String, Color> categoryColors = {
    'Umum': Colors.blue,
    'Kerja': Colors.orange,
    'Pribadi': Colors.purple,
    'Belanja': Colors.green,
  };

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _searchController = TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTasks = prefs.getString('tasks');
    if (savedTasks != null) {
      if (!mounted) return; // 5. Tambahkan mounted check
      setState(() {
        tasks.addAll(List<Map<String, dynamic>>.from(jsonDecode(savedTasks)));
        _sortTasksByDeadline();
      });
    }
  }

  void _sortTasksByDeadline() {
    tasks.sort((a, b) {
      if (a['deadline'] == null) return 1;
      if (b['deadline'] == null) return -1;
      return DateTime.parse(a['deadline'])
          .compareTo(DateTime.parse(b['deadline']));
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks', jsonEncode(tasks));
  }

  void _addTask(
      String title, String description, String category, DateTime? deadline) {
    setState(() {
      tasks.add({
        'title': title,
        'description': description,
        'category': category,
        'deadline': deadline?.toIso8601String(),
        'isDone': false,
        'createdAt': DateTime.now().toIso8601String(),
        'priority': 'Medium',
      });
      _sortTasksByDeadline();
    });
    _saveTasks();
  }

  void _toggleTaskStatus(int index) {
    setState(() {
      tasks[index]['isDone'] = !tasks[index]['isDone'];
      if (tasks[index]['isDone']) {
        tasks[index]['completedAt'] = DateTime.now().toIso8601String();
      } else {
        tasks[index].remove('completedAt');
      }
    });
    _saveTasks();
  }

  void _deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
    _saveTasks();
  }

  Future<void> _editTask(int index) async {
    // 6. Buat async untuk handle context
    final task = tasks[index];
    String title = task['title'];
    String description = task['description'] ?? '';
    String category = task['category'];
    DateTime? deadline =
        task['deadline'] != null ? DateTime.parse(task['deadline']) : null;
    String priority = task['priority'] ?? 'Medium';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Task',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: title),
                onChanged: (value) => title = value,
              ),
              const SizedBox(height: 15),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: description),
                onChanged: (value) => description = value,
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Category:'),
                  DropdownButton<String>(
                    value: category,
                    items: ['Umum', 'Kerja', 'Pribadi', 'Belanja']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => category = value!);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Priority:'),
                  DropdownButton<String>(
                    value: priority,
                    items: ['Low', 'Medium', 'High'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => priority = value!);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Deadline:'),
                  TextButton.icon(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: deadline ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null && mounted) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null && mounted) {
                          setState(() {
                            deadline = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(deadline == null
                        ? 'Select Deadline'
                        : DateFormat('dd MMM yyyy, HH:mm')
                            .format(deadline!)), // 7. Gunakan DateFormat
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (title.trim().isNotEmpty) {
                        setState(() {
                          tasks[index]['title'] = title.trim();
                          tasks[index]['description'] = description.trim();
                          tasks[index]['category'] = category;
                          tasks[index]['deadline'] =
                              deadline?.toIso8601String();
                          tasks[index]['priority'] = priority;
                        });
                        _saveTasks();
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00ACC1),
                    ),
                    child: const Text('Update Task'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddTaskDialog() async {
    // 8. Buat async
    String title = '';
    String description = '';
    String category = _selectedCategory;
    DateTime? deadline;
    String priority = 'Medium';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New Task',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Task Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => title = value,
              ),
              const SizedBox(height: 15),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => description = value,
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Category:'),
                  DropdownButton<String>(
                    value: category,
                    items: ['Umum', 'Kerja', 'Pribadi', 'Belanja']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => category = value!);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Priority:'),
                  DropdownButton<String>(
                    value: priority,
                    items: ['Low', 'Medium', 'High'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag,
                              color: value == 'High'
                                  ? Colors.red
                                  : value == 'Medium'
                                      ? Colors.orange
                                      : Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 5),
                            Text(value),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => priority = value!);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Deadline:'),
                  TextButton.icon(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null && mounted) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null && mounted) {
                          setState(() {
                            deadline = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(deadline == null
                        ? 'Select Deadline'
                        : deadline != null
                            ? DateFormat('dd MMM yyyy, HH:mm').format(deadline!)
                            : 'Select Deadline'), // 9. Perbaiki string interpolation
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (title.trim().isNotEmpty) {
                        _addTask(title.trim(), description.trim(), category,
                            deadline);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00ACC1),
                    ),
                    child: const Text('Add Task'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> getFilteredTasks() {
    List<Map<String, dynamic>> result = [];

    // Apply status filter
    if (filter == 'All') {
      result = List.from(tasks);
    } else if (filter == 'Pending') {
      result = tasks.where((task) => !task['isDone']).toList();
    } else {
      result = tasks.where((task) => task['isDone']).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((task) =>
              task['title']
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (task['description'] != null &&
                  task['description']
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase())))
          .toList();
    }

    return result;
  }

  double getProgress() {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t['isDone']).length;
    return completed / tasks.length;
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';

    final date = DateTime.parse(isoDate);
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('HH:mm').format(date)}'; // 10. Gunakan DateFormat
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays > 0 && difference.inDays < 7) {
      return DateFormat('EEEE, HH:mm').format(date);
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = getFilteredTasks();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _isSearching
            ? SizeTransition(
                sizeFactor: _animationController,
                axis: Axis.horizontal,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Color(0xFF00ACC1)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              )
            : const Text(''),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
            color: const Color(0xFF00ACC1),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Color(0xFF00ACC1)),
            onSelected: (value) {
              if (value == 'sort_date') {
                setState(() {
                  _sortTasksByDeadline();
                });
              } else if (value == 'sort_priority') {
                setState(() {
                  final priorityValues = {'High': 0, 'Medium': 1, 'Low': 2};
                  tasks.sort((a, b) {
                    final aVal = priorityValues[a['priority'] ?? 'Medium'] ?? 1;
                    final bVal = priorityValues[b['priority'] ?? 'Medium'] ?? 1;
                    return aVal.compareTo(bVal);
                  });
                });
              } else if (value == 'delete_completed') {
                setState(() {
                  tasks.removeWhere((task) => task['isDone']);
                  _saveTasks();
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sort_date',
                child: Row(
                  children: [
                    Icon(Icons.date_range, size: 18, color: Color(0xFF00ACC1)),
                    SizedBox(width: 8),
                    const Text('Sort by Deadline'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sort_priority',
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 18, color: Color(0xFF00ACC1)),
                    SizedBox(width: 8),
                    const Text('Sort by Priority'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete_completed',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    const Text('Delete Completed'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: getProgress(),
                  backgroundColor: Colors.grey[300],
                  color: const Color(0xFF00ACC1),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(getProgress() * 100).toInt()}% completed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['All', 'Pending', 'Completed'].map((status) {
                final isSelected = filter == status;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? const Color(0xFF00ACC1)
                            : Colors.grey[200],
                        foregroundColor:
                            isSelected ? Colors.white : Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => setState(() => filter = status),
                      child: Text(
                        status,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          filter == 'Completed'
                              ? Icons.check_circle_outline
                              : filter == 'Pending'
                                  ? Icons.hourglass_empty
                                  : Icons.inbox,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${filter.toLowerCase()} tasks!',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        if (_searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Try a different search',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[500]),
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      final originalIndex = tasks.indexOf(task);
                      final deadline = task['deadline'] != null
                          ? DateTime.parse(task['deadline'])
                          : null;
                      final isPending = !task['isDone'];
                      final priority = task['priority'] ?? 'Medium';
                      final isOverdue = isPending &&
                          deadline != null &&
                          deadline.isBefore(DateTime.now());

                      return Dismissible(
                        key: Key('${task['title']}$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.delete_forever,
                              color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteTask(originalIndex),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          elevation: isPending ? 4 : 1,
                          color: isPending ? Colors.white : Colors.grey[100],
                          child: InkWell(
                            onTap: () => _editTask(originalIndex),
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isPending
                                      ? (isOverdue
                                              ? Colors.red
                                              : (categoryColors[
                                                      task['category']] ??
                                                  Colors.blue))
                                          .withAlpha(
                                              76) // 11. Ganti withOpacity(0.3)
                                      : Colors.grey.withAlpha(76),
                                  width: isPending ? 2 : 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                leading: isPending
                                    ? IconButton(
                                        icon: CircleAvatar(
                                          backgroundColor: Colors.grey[200],
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.transparent,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _toggleTaskStatus(originalIndex),
                                      )
                                    : IconButton(
                                        icon: CircleAvatar(
                                          backgroundColor:
                                              const Color(0xFF00ACC1),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _toggleTaskStatus(originalIndex),
                                      ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task['title'],
                                        style: TextStyle(
                                          fontWeight: isPending
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 16,
                                          decoration: isPending
                                              ? null
                                              : TextDecoration.lineThrough,
                                          color: isPending
                                              ? isOverdue
                                                  ? Colors.red[700]
                                                  : Colors.black87
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                    if (priority != 'Medium')
                                      Icon(
                                        Icons.flag,
                                        color: isPending
                                            ? priority == 'High'
                                                ? Colors.red
                                                : priority == 'Medium'
                                                    ? Colors.orange
                                                    : Colors.green
                                            : Colors.grey,
                                        size: 16,
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (task['description'] != null &&
                                        task['description'].isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          task['description'],
                                          style: TextStyle(
                                            color: isPending
                                                ? Colors.grey[700]
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isPending
                                                ? (categoryColors[
                                                            task['category']] ??
                                                        Colors.blue)
                                                    .withAlpha(
                                                        51) // 12. Ganti withOpacity(0.2)
                                                : Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            task['category'],
                                            style: TextStyle(
                                              color: isPending
                                                  ? categoryColors[
                                                          task['category']] ??
                                                      Colors.blue
                                                  : Colors.grey[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (deadline != null)
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isOverdue && isPending
                                                      ? Icons.warning
                                                      : Icons.access_time,
                                                  color: isPending
                                                      ? isOverdue
                                                          ? Colors.red[700]
                                                          : Colors.grey[600]
                                                      : Colors.grey[500],
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    _formatDate(
                                                        task['deadline']),
                                                    style: TextStyle(
                                                      color: isPending
                                                          ? isOverdue
                                                              ? Colors.red[700]
                                                              : Colors.grey[700]
                                                          : Colors.grey[500],
                                                      fontSize: 12,
                                                      fontWeight:
                                                          isOverdue && isPending
                                                              ? FontWeight.bold
                                                              : null,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (!isPending &&
                                        task['completedAt'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.grey[500],
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Completed ${DateFormat('dd MMM, HH:mm').format(DateTime.parse(task['completedAt']))}',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) => Container(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.edit),
                                              title: const Text('Edit Task'),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _editTask(originalIndex);
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              title: const Text('Delete Task',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                              onTap: () {
                                                Navigator.pop(context);
                                                _deleteTask(originalIndex);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00ACC1),
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
