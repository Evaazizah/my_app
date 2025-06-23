import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Todo {
  String id;
  String title;
  String description; 
  bool isCompleted;
  DateTime? dueDate;
  DateTime creationDate; 

  Todo({
    required this.id,
    required this.title,
    this.description = '', // Default kosong
    this.isCompleted = false,
    this.dueDate,
    required this.creationDate,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      isCompleted: json['isCompleted'] as bool,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      creationDate: DateTime.parse(json['creationDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'dueDate': dueDate?.toIso8601String(),
      'creationDate': creationDate.toIso8601String(),
    };
  }
}

class ClassSchedule {
  String id;
  String subject;
  String day;
  TimeOfDay time;
  String? room;
  String? teacher; // Tambahan: Nama Guru/Dosen
  String? className; // Tambahan: Nama Kelas (misal: "Dev Education")

  ClassSchedule({
    required this.id,
    required this.subject,
    required this.day,
    required this.time,
    this.room,
    this.teacher,
    this.className,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      id: json['id'] as String,
      subject: json['subject'] as String,
      day: json['day'] as String,
      time: TimeOfDay(hour: json['timeHour'] as int, minute: json['timeMinute'] as int),
      room: json['room'] as String?,
      teacher: json['teacher'] as String?,
      className: json['className'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'day': day,
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'room': room,
      'teacher': teacher,
      'className': className,
    };
  }
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Todo> _todos = [];
  List<ClassSchedule> _classSchedules = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String>? todosJson = prefs.getStringList('todos');
    if (todosJson != null) {
      setState(() {
        _todos = todosJson.map((jsonString) => Todo.fromJson(json.decode(jsonString))).toList();
      });
    }

    final List<String>? schedulesJson = prefs.getStringList('classSchedules');
    if (schedulesJson != null) {
      setState(() {
        _classSchedules = schedulesJson.map((jsonString) => ClassSchedule.fromJson(json.decode(jsonString))).toList();
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Simpan todo sebagai List<String>
    final List<String> todosJson = _todos.map((todo) => json.encode(todo.toJson())).toList();
    await prefs.setStringList('todos', todosJson);

    // Simpan class schedule
    final List<String> schedulesJson = _classSchedules.map((schedule) => json.encode(schedule.toJson())).toList();
    await prefs.setStringList('classSchedules', schedulesJson);

    // ✅ Tambahan penting agar dashboard & export bekerja:
    final encodedTodos = jsonEncode(_todos.map((t) => t.toJson()).toList());
    await prefs.setString('todo_list', encodedTodos);

    final unfinished = _todos.where((t) => !t.isCompleted).length;
    await prefs.setInt('task_pending', unfinished);
  }

  void _addTodo(Todo newTodo) {
    setState(() {
      _todos.add(newTodo);
      _saveData();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tugas berhasil ditambahkan!')),
    );
  }

  void _toggleTodoStatus(String id) {
    setState(() {
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        _todos[index].isCompleted = !_todos[index].isCompleted;
        _saveData();
      }
    });
  }

  void _deleteTodo(String id) {
    setState(() {
      _todos.removeWhere((todo) => todo.id == id);
      _saveData();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tugas dihapus!')),
    );
  }

  void _addSchedule(ClassSchedule newSchedule) {
    setState(() {
      _classSchedules.add(newSchedule);
      _saveData();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jadwal berhasil ditambahkan!')),
    );
  }

  void _deleteSchedule(String id) {
    setState(() {
      _classSchedules.removeWhere((schedule) => schedule.id == id);
      _saveData();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jadwal dihapus!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TaskRoom & Classroom',
          style: TextStyle(fontFamily: GoogleFonts.poppins().fontFamily),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daftar Tugas', icon: Icon(Icons.assignment)),
            Tab(text: 'Jadwal Kelas', icon: Icon(Icons.calendar_today)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodoTab(),
          _buildClassroomTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddTodoDialog(context);
          } else {
            _showAddClassScheduleDialog(context);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodoTab() {
    if (_todos.isEmpty) {
      return const Center(child: Text('Belum ada tugas. Tambahkan satu!'));
    }

    _todos.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      return a.creationDate.compareTo(b.creationDate); // Urutkan berdasarkan tanggal dibuat jika status sama
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _todos.length,
      itemBuilder: (context, index) {
        final todo = _todos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          color: todo.isCompleted ? Colors.grey[200] : Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                          color: todo.isCompleted ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteTodo(todo.id);
                        }
                        // Bisa tambahkan opsi 'edit' di sini
                      },
                      itemBuilder: (BuildContext context) {
                        return {'Hapus'}.map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice == 'Hapus' ? 'delete' : '',
                            child: Text(choice),
                          );
                        }).toList();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  todo.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: GoogleFonts.poppins().fontFamily,
                    decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                    color: todo.isCompleted ? Colors.grey : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      todo.dueDate != null
                          ? 'Jatuh Tempo: ${todo.dueDate!.day}/${todo.dueDate!.month}/${todo.dueDate!.year}'
                          : 'Tidak ada jatuh tempo',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: GoogleFonts.poppins().fontFamily,
                        color: todo.isCompleted ? Colors.grey : Colors.grey[600],
                      ),
                    ),
                    Checkbox(
                      value: todo.isCompleted,
                      onChanged: (bool? newValue) {
                        if (newValue != null) {
                          _toggleTodoStatus(todo.id);
                        }
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassroomTab() {
    if (_classSchedules.isEmpty) {
      return const Center(child: Text('Belum ada jadwal kelas. Tambahkan satu!'));
    }

    _classSchedules.sort((a, b) {
      final dayOrder = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      int compareDay = dayOrder.indexOf(a.day).compareTo(dayOrder.indexOf(b.day));
      if (compareDay != 0) return compareDay;
      return (a.time.hour * 60 + a.time.minute).compareTo(b.time.hour * 60 + b.time.minute);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _classSchedules.length,
      itemBuilder: (context, index) {
        final schedule = _classSchedules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      schedule.className ?? 'Kelas Tanpa Nama', // Nama kelas di atas
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: GoogleFonts.poppins().fontFamily,
                        color: Colors.grey[700],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteSchedule(schedule.id);
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return {'Hapus'}.map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice == 'Hapus' ? 'delete' : '',
                            child: Text(choice),
                          );
                        }).toList();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  schedule.subject,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: GoogleFonts.poppins().fontFamily,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${schedule.day}, ${schedule.time.format(context)} ${schedule.room != null && schedule.room!.isNotEmpty ? '(${schedule.room})' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: GoogleFonts.poppins().fontFamily,
                    color: Colors.grey[600],
                  ),
                ),
                if (schedule.teacher != null && schedule.teacher!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Dosen: ${schedule.teacher}',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime? selectedDueDate;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah Tugas Baru'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Judul Tugas'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Judul tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Deskripsi'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        title: Text(selectedDueDate == null
                            ? 'Pilih Jatuh Tempo'
                            : 'Jatuh Tempo: ${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null && pickedDate != selectedDueDate) {
                            setState(() {
                              selectedDueDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Tambah'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newTodo = Todo(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    description: descriptionController.text,
                    isCompleted: false,
                    dueDate: selectedDueDate,
                    creationDate: DateTime.now(),
                  );
                  _addTodo(newTodo);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddClassScheduleDialog(BuildContext context) {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController roomController = TextEditingController();
    final TextEditingController teacherController = TextEditingController(); // Tambahan controller
    final TextEditingController classNameController = TextEditingController(); // Tambahan controller
    String selectedDay = 'Senin';
    TimeOfDay selectedTime = TimeOfDay.now();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Jadwal Kelas Baru'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: classNameController,
                        decoration: const InputDecoration(labelText: 'Nama Kelas (ex: Dev Education)'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama Kelas tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: subjectController,
                        decoration: const InputDecoration(labelText: 'Mata Pelajaran'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mata Pelajaran tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedDay,
                        decoration: const InputDecoration(labelText: 'Hari'),
                        items: <String>['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedDay = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        title: Text('Waktu: ${selectedTime.format(context)}'),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked != null && picked != selectedTime) {
                            setState(() {
                              selectedTime = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: roomController,
                        decoration: const InputDecoration(labelText: 'Ruangan (Opsional)'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: teacherController,
                        decoration: const InputDecoration(labelText: 'Dosen/Guru (Opsional)'),
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Tambah'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newSchedule = ClassSchedule(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    subject: subjectController.text,
                    day: selectedDay,
                    time: selectedTime,
                    room: roomController.text.isNotEmpty ? roomController.text : null,
                    teacher: teacherController.text.isNotEmpty ? teacherController.text : null,
                    className: classNameController.text.isNotEmpty ? classNameController.text : null,
                  );
                  _addSchedule(newSchedule);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}