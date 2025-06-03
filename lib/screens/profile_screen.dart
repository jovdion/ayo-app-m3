import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'chat_list_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  int _selectedIndex = 1; // Profile tab
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;

  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    _usernameController = TextEditingController(text: user?.username);
    _emailController = TextEditingController(text: user?.email);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ChatListScreen()),
        (route) => false,
      );
    }
    setState(() => _selectedIndex = index);
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _userService.updateProfile(
        username: _usernameController.text,
        email: _emailController.text,
      );

      setState(() {
        _isEditing = false;
        _isLoading = false;
        _passwordController.clear(); // Clear password after successful update
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _logout() {
    _authService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return const SizedBox();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    if (_isEditing) ...[
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'New Password (optional)',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ] else ...[
                      ListTile(
                        title: const Text('Username'),
                        subtitle: Text(user.username),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Email'),
                        subtitle: Text(user.email),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
