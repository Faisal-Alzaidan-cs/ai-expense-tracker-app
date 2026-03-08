import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expenses_tracker/services/firebase_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = FirebaseAuthService();

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Register user using Firebase Authentication.
  Future<void> _registerUser() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Link username to Firestore "users" collection
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pushNamed(context, "/home");
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Registration failed. Please try again.";

      if (e.code == 'email-already-in-use') {
        errorMessage = "This email is already registered.";
      } else if (e.code == 'weak-password') {
        errorMessage =
            "Password is too weak. Please choose a stronger password.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Invalid email format.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(63, 153, 236, 0),
              Colors.white,
              Colors.white,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios),
                      color: Colors.black87,
                    ),

                    const SizedBox(height: 20),

                    // Header
                    Text(
                      "Create Account",
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    Text(
                      "Sign up to get started",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Email field
                    _buildTextFormField(
                      label: "Email",
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your email";
                        }
                        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                          return "Please enter a valid email";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Username field
                    _buildTextFormField(
                      label: "Username",
                      controller: _usernameController,
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a username";
                        }
                        if (value.length < 3) {
                          return "Username must be at least 3 characters";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Password field
                    _buildTextFormField(
                      label: "Password",
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline,
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter a password";
                        }
                        if (value.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Confirm Password field
                    _buildTextFormField(
                      label: "Confirm Password",
                      controller: _confirmPasswordController,
                      prefixIcon: Icons.lock_outline,
                      obscureText: !_isConfirmPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please confirm your password";
                        }
                        if (value != _passwordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    // Terms and conditions checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: true,
                          onChanged: (value) {},
                          fillColor: MaterialStateProperty.resolveWith<Color>(
                              (states) {
                            if (states.contains(MaterialState.selected)) {
                              return const Color(0xFF9BEC00);
                            }
                            return Colors.grey;
                          }),
                        ),
                        Expanded(
                          child: Text(
                            "By creating an account, you agree to our Terms & Conditions",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Sign Up button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9BEC00),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.black),
                              )
                            : Text(
                                "Sign Up",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Login link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, "/login");
                        },
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Already have an account? ",
                                style: GoogleFonts.poppins(
                                  color: Colors.black54,
                                ),
                              ),
                              TextSpan(
                                text: "Sign In",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF9BEC00),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper to build text form fields with consistent styling
  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey),
        prefixIcon: Icon(prefixIcon, color: Colors.grey),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF9BEC00), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
