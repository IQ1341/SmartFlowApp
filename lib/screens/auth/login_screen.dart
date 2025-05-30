import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim());

      User? user = userCredential.user;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final role = userDoc['role'];

          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/adminDashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          setState(() {
            _errorMessage = 'Data pengguna tidak ditemukan.';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 107, 139, 255),
              Color.fromARGB(255, 140, 163, 247)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.water_drop_rounded,
                    size: 80, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  "Login Monitoring Air",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),
                        if (_errorMessage != null)
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        if (_isLoading)
                          const CircularProgressIndicator()
                        else
                          ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 107, 139, 255),
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Login",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const Text("Belum punya akun? Daftar di sini"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
