import 'package:dio/dio.dart';
import 'package:trenix/services/api/dio_client.dart'; 

class Todo {
  final String id;
  final String title;
  final String description;
  final String status; 

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
    };
  }
}

class TodoApiService {
  final Dio _dio =
      DioClient().dio; // Gunakan instance Dio yang sudah dikonfigurasi

  Future<List<Todo>> getTodos() async {
    try {
      final response = await _dio.get('/tasks'); // Sesuaikan endpoint
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => Todo.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load todos');
      }
    } on DioException catch (e) {
      throw Exception('Failed to load todos: ${e.message}');
    }
  }

  Future<Todo> createTodo(Todo todo) async {
    try {
      final response = await _dio.post('/tasks', data: todo.toJson());
      if (response.statusCode == 201) {
        // 201 Created
        return Todo.fromJson(response.data);
      } else {
        throw Exception('Failed to create todo');
      }
    } on DioException catch (e) {
      throw Exception('Failed to create todo: ${e.message}');
    }
  }

  // Tambahkan method lain seperti updateTodo, deleteTodo sesuai kebutuhan API
}
