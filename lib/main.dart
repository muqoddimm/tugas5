import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'services/user_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Praktikum 5 - CRUD REST API',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const UserCrudPage(),
    );
  }
}

class UserCrudPage extends StatefulWidget {
  const UserCrudPage({super.key});

  @override
  State<UserCrudPage> createState() => _UserCrudPageState();
}

class _UserCrudPageState extends State<UserCrudPage> {
  final UserService _userService = UserService();
  late Future<List<UserModel>> _usersFuture;
  List<UserModel> _localUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // Mengambil daftar user dari server (GET)
  void _loadUsers() {
    setState(() {
      _usersFuture = _userService.getUsers().then((users) {
        _localUsers = List<UserModel>.from(users);
        return _localUsers;
      });
    });
  }

  // SnackBar konfirmasi
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // (POST)
  Future<void> _showCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final jobController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah User Baru (POST)'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: jobController,
                decoration: const InputDecoration(
                  labelText: 'Pekerjaan (Job)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final name = nameController.text.trim();
              final job = jobController.text.trim();
              Navigator.pop(context);

              try {
                final result = await _userService.createUser(name, job);

                final nameParts = name.split(' ');
                final firstName = nameParts.first;
                final lastName = nameParts.length > 1
                    ? nameParts.sublist(1).join(' ')
                    : '($job)';

                final newUser = UserModel(
                  id: int.tryParse(result['id'].toString()) ??
                      DateTime.now().millisecondsSinceEpoch % 1000,
                  email: '${firstName.toLowerCase()}@reqres.in',
                  firstName: firstName,
                  lastName: lastName,
                  avatar: 'https://reqres.in/img/faces/1-image.jpg',
                );

                setState(() {
                  _localUsers.insert(0, newUser);
                  _usersFuture = Future.value(_localUsers);
                });

                _showSnackBar(
                  'User berhasil dibuat! ID: ${result['id']} ($name - $job)',
                );
              } catch (e) {
                _showSnackBar('Error: $e', isError: true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Dialog Form Edit User
  Future<void> _showUpdateDialog(UserModel user) async {
    final editNameController =
    TextEditingController(text: '${user.firstName} ${user.lastName}');
    final editJobController = TextEditingController(text: 'Staff IT');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: editJobController,
              decoration: const InputDecoration(
                labelText: 'Pekerjaan (Job)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = editNameController.text.trim();
              final job = editJobController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);

              try {
                final res = await _userService.updateUser(user.id, name, job);

                final nameParts = name.split(' ');
                final firstName = nameParts.first;
                final lastName = nameParts.length > 1
                    ? nameParts.sublist(1).join(' ')
                    : '($job)';

                setState(() {
                  final index = _localUsers.indexWhere((u) => u.id == user.id);
                  if (index != -1) {
                    _localUsers[index] = UserModel(
                      id: user.id,
                      email: user.email,
                      firstName: firstName,
                      lastName: lastName,
                      avatar: user.avatar,
                    );
                    _usersFuture = Future.value(_localUsers);
                  }
                });

                _showSnackBar(
                  'PUT Berhasil: ${res['name']} (${res['job']}) diupdate!',
                );
              } catch (e) {
                _showSnackBar('Error PUT: $e', isError: true);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // Fungsi Hapus User
  Future<void> _handleDeleteUser(UserModel user) async {
    try {
      await _userService.deleteUser(user.id);

      setState(() {
        _localUsers.removeWhere((item) => item.id == user.id);
        _usersFuture = Future.value(_localUsers);
      });

      _showSnackBar(
        'DELETE Berhasil: User ${user.firstName} (ID: ${user.id}) dihapus!',
      );
    } catch (e) {
      _showSnackBar('Error DELETE: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar User (reqres.in)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadUsers,
            tooltip: 'Refresh Data',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      // Daftar User menggunakan FutureBuilder
      body: FutureBuilder<List<UserModel>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${snapshot.error.toString().replaceFirst("Exception: ", "")}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadUsers,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Data tidak ditemukan'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final user = users[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    foregroundImage: NetworkImage(user.avatar),
                    child: Text(
                      user.firstName.isNotEmpty ? user.firstName[0] : '?',
                    ),
                  ),
                  title: Text('${user.firstName} ${user.lastName}'),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showUpdateDialog(user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _handleDeleteUser(user),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // Tombol Tambah
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        tooltip: 'Tambah User (POST)',
        child: const Icon(Icons.add),
      ),
    );
  }
}