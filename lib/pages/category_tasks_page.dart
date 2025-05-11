import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryTasksPage extends StatefulWidget {
  final String categoryName;
  final List<Map<String, dynamic>> tasks;
  final Function(List<Map<String, dynamic>>) onTasksChanged;

  const CategoryTasksPage({
    super.key,
    required this.categoryName,
    required this.tasks,
    required this.onTasksChanged,
  });

  @override
  State<CategoryTasksPage> createState() => _CategoryTasksPageState();
}

class _CategoryTasksPageState extends State<CategoryTasksPage>
    with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> _tasks;
  final bool _showCompleted = true;
  late TabController _tabController;
  late SharedPreferences _prefs;
  bool _isLoading = true;

  // List of icon options with labels
  final List<Map<String, dynamic>> iconOptions = const [
    {'icon': Icons.task, 'label': 'Umum'},
    {'icon': Icons.school, 'label': 'Pendidikan'},
    {'icon': Icons.work, 'label': 'Pekerjaan'},
    {'icon': Icons.home, 'label': 'Rumah'},
    {'icon': Icons.fitness_center, 'label': 'Olahraga'},
  ];

  @override
  void initState() {
    super.initState();
    _tasks = List.from(widget.tasks.map((task) {
      return {
        'title': task['title'],
        'description': task['description'] ?? '',
        'isDone': task['isDone'] ?? false,
        'deadline': task['deadline'],
        'icon': task['icon'] ?? Icons.task.codePoint,
        'isNote': task['isNote'] ?? false,
      };
    }));
    _tabController = TabController(length: 2, vsync: this);
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoading = false;
    });
    _loadTasksFromPrefs();
  }

  Future<void> _loadTasksFromPrefs() async {
    final tasksKey = 'tasks_${widget.categoryName}';
    final tasksString = _prefs.getString(tasksKey);

    if (tasksString != null && tasksString.isNotEmpty) {
      try {
        final List<Map<String, dynamic>> decodedTasks = tasksString
            .split('|')
            .where((s) => s.isNotEmpty)
            .map((s) {
              final parts = s.split('::');
              if (parts.length >= 6) {
                return {
                  'title': parts[0],
                  'description': parts[1],
                  'isDone': parts[2] == 'true',
                  'deadline': parts[3].isEmpty ? null : parts[3],
                  'icon': int.parse(parts[4]),
                  'isNote': parts[5] == 'true',
                };
              }
              return <String, dynamic>{}; // Return empty map if invalid
            })
            .where((item) => item.isNotEmpty) // Filter out empty maps
            .toList();

        if (decodedTasks.isNotEmpty) {
          setState(() {
            _tasks = decodedTasks;
          });
        }
      } catch (e) {
        debugPrint('Error loading tasks: $e');
      }
    }
  }

  Future<void> _saveTasksToPrefs() async {
    final tasksKey = 'tasks_${widget.categoryName}';
    final tasksString = _tasks
        .map((task) =>
            '${task['title']}::${task['description']}::${task['isDone']}::${task['deadline'] ?? ''}::${task['icon']}::${task['isNote']}')
        .join('|');

    await _prefs.setString(tasksKey, tasksString);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addTask(String title, String description, DateTime? deadline,
      IconData icon, bool isNote) {
    setState(() {
      _tasks.add({
        'title': title,
        'description': description,
        'isDone': false,
        'deadline': deadline?.toIso8601String(),
        'icon': icon.codePoint,
        'isNote': isNote,
      });
      widget.onTasksChanged(_tasks);
      _saveTasksToPrefs();
    });
  }

  void _editTask(int index, String newTitle, String newDescription,
      DateTime? newDeadline, IconData newIcon, bool isNote) {
    setState(() {
      _tasks[index] = {
        'title': newTitle,
        'description': newDescription,
        'isDone': _tasks[index]['isDone'],
        'deadline': newDeadline?.toIso8601String(),
        'icon': newIcon.codePoint,
        'isNote': isNote,
      };
      widget.onTasksChanged(_tasks);
      _saveTasksToPrefs();
    });
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
      widget.onTasksChanged(_tasks);
      _saveTasksToPrefs();
    });
  }

  void _toggleTaskStatus(int index) {
    setState(() {
      _tasks[index]['isDone'] = !_tasks[index]['isDone'];
      widget.onTasksChanged(_tasks);
      _saveTasksToPrefs();
    });
  }

  void _showAddItemDialog({bool isNoteDefault = false}) {
    String newTitle = '';
    String newDesc = '';
    DateTime? newDeadline;
    IconData selectedIcon = Icons.task;
    bool isNote = isNoteDefault;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isNote ? 'Tambah Catatan' : 'Tambah Tugas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isNote ? 'Catatan' : 'Tugas'),
                    Switch(
                      value: isNote,
                      onChanged: (value) {
                        setState(() {
                          isNote = value;
                          if (isNote) {
                            newDeadline = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
                TextField(
                  decoration: InputDecoration(
                      hintText: isNote ? 'Judul catatan' : 'Judul tugas'),
                  onChanged: (value) => newTitle = value,
                ),
                TextField(
                  decoration: InputDecoration(
                      hintText: isNote ? 'Isi catatan' : 'Deskripsi tugas'),
                  maxLines: isNote ? 5 : 2,
                  onChanged: (value) => newDesc = value,
                ),
                if (!isNote) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(newDeadline == null
                          ? 'Tidak ada deadline'
                          : 'Deadline: ${DateFormat.yMMMd().format(newDeadline!)}'),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (selectedDate != null) {
                            setState(() => newDeadline = selectedDate);
                          }
                        },
                      ),
                    ],
                  ),
                ],
                DropdownButton<IconData>(
                  value: selectedIcon,
                  items: iconOptions.map((option) {
                    return DropdownMenuItem<IconData>(
                      value: option['icon'],
                      child: Row(
                        children: [
                          Icon(option['icon']),
                          const SizedBox(width: 10),
                          Text(option['label']),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (icon) => setState(() => selectedIcon = icon!),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newTitle.trim().isNotEmpty) {
                  _addTask(newTitle.trim(), newDesc.trim(), newDeadline,
                      selectedIcon, isNote);
                  Navigator.pop(context);
                }
              },
              child: Text(isNote ? 'Simpan Catatan' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, int index) {
    final task = _tasks[index];
    String newTitle = task['title'];
    String newDesc = task['description'];
    DateTime? newDeadline =
        task['deadline'] != null ? DateTime.parse(task['deadline']) : null;
    IconData selectedIcon = IconData(task['icon'], fontFamily: 'MaterialIcons');
    bool isNote = task['isNote'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isNote ? 'Edit Catatan' : 'Edit Tugas'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isNote ? 'Catatan' : 'Tugas'),
                    Switch(
                      value: isNote,
                      onChanged: (value) {
                        setState(() {
                          isNote = value;
                          if (isNote) {
                            newDeadline = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
                TextField(
                  decoration: InputDecoration(
                      hintText: isNote ? 'Judul catatan' : 'Judul tugas'),
                  controller: TextEditingController(text: newTitle),
                  onChanged: (value) => newTitle = value,
                ),
                TextField(
                  decoration: InputDecoration(
                      hintText: isNote ? 'Isi catatan' : 'Deskripsi tugas'),
                  controller: TextEditingController(text: newDesc),
                  maxLines: isNote ? 5 : 2,
                  onChanged: (value) => newDesc = value,
                ),
                if (!isNote) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(newDeadline == null
                          ? 'Tidak ada deadline'
                          : 'Deadline: ${DateFormat.yMMMd().format(newDeadline!)}'),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: newDeadline ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (selectedDate != null) {
                            setState(() => newDeadline = selectedDate);
                          }
                        },
                      ),
                    ],
                  ),
                ],
                DropdownButton<IconData>(
                  value: selectedIcon,
                  items: iconOptions.map((option) {
                    return DropdownMenuItem<IconData>(
                      value: option['icon'],
                      child: Row(
                        children: [
                          Icon(option['icon']),
                          const SizedBox(width: 10),
                          Text(option['label']),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (icon) => setState(() => selectedIcon = icon!),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newTitle.trim().isNotEmpty) {
                  _editTask(index, newTitle.trim(), newDesc.trim(), newDeadline,
                      selectedIcon, isNote);
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
            TextButton(
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 4),
                  Text('Hapus', style: TextStyle(color: Colors.red)),
                ],
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Hapus ${isNote ? 'Catatan' : 'Tugas'}'),
                    content: Text(
                        'Anda yakin ingin menghapus ${isNote ? 'catatan' : 'tugas'} ini?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          _deleteTask(index);
                          Navigator.pop(ctx); // Close confirmation dialog
                          Navigator.pop(context); // Close edit dialog
                        },
                        child: const Text('Hapus',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    final tasks = _tasks.where((task) => !(task['isNote'] ?? false)).toList();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_outlined,
                  size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Tidak ada tugas. Silakan tambah tugas baru.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Tambah Tugas'),
                onPressed: () => _showAddItemDialog(isNoteDefault: false),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];

        if (!_showCompleted && task['isDone'] == true) {
          return const SizedBox.shrink();
        }

        final TextStyle titleStyle = TextStyle(
          fontWeight: FontWeight.bold,
          decoration:
              task['isDone'] ? TextDecoration.lineThrough : TextDecoration.none,
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          color: task['isDone'] ? Colors.grey.shade200 : Colors.white,
          child: Dismissible(
            key: UniqueKey(),
            background: Container(
              color: Colors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(Icons.check, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                return await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Tugas'),
                    content:
                        const Text('Anda yakin ingin menghapus tugas ini?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Hapus',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              } else {
                _toggleTaskStatus(_tasks.indexOf(task));
                return false;
              }
            },
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                _deleteTask(_tasks.indexOf(task));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tugas telah dihapus')),
                );
              }
            },
            child: ListTile(
              leading: Icon(
                IconData(task['icon'], fontFamily: 'MaterialIcons'),
              ),
              title: Text(
                task['title'],
                style: titleStyle,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task['description']),
                  if (task['deadline'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat.yMMMd()
                              .format(DateTime.parse(task['deadline'])),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              trailing: Checkbox(
                value: task['isDone'],
                onChanged: (_) => _toggleTaskStatus(_tasks.indexOf(task)),
              ),
              onTap: () => _showEditDialog(context, _tasks.indexOf(task)),
              onLongPress: () => _deleteTask(_tasks.indexOf(task)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesList() {
    final notes = _tasks.where((task) => task['isNote'] ?? false).toList();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.note_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Tidak ada catatan. Silakan tambah catatan baru.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Tambah Catatan'),
                onPressed: () => _showAddItemDialog(isNoteDefault: true),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          color: Colors.blue.shade50,
          child: Dismissible(
            key: UniqueKey(),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Catatan'),
                  content:
                      const Text('Anda yakin ingin menghapus catatan ini?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Hapus',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) {
              _deleteTask(_tasks.indexOf(note));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Catatan telah dihapus')),
              );
            },
            child: ListTile(
              leading: const Icon(Icons.note, color: Colors.blue),
              title: Text(
                note['title'],
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              subtitle: Text(note['description']),
              trailing: const Icon(Icons.notes, color: Colors.blue),
              onTap: () => _showEditDialog(context, _tasks.indexOf(note)),
              onLongPress: () => _deleteTask(_tasks.indexOf(note)),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.task), text: "Tugas"),
            Tab(icon: Icon(Icons.note), text: "Catatan"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(),
          _buildNotesList(),
        ],
      ),
    );
  }
}