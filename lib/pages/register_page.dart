import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterer_app/components/my_button.dart';
import 'package:flutterer_app/components/my_textfield.dart';
import 'package:flutterer_app/components/square_tile.dart';
import 'package:flutterer_app/services/auth_service.dart';
import 'package:flutterer_app/services/auth_error.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onPressed;

  const RegisterPage({super.key, required this.onPressed});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  void signUserUp() async {
    if (userController.text.trim().isEmpty ||
        passController.text.isEmpty ||
        confirmPassController.text.isEmpty) {
      showErrorMessage("Please fill in all fields.");
      return;
    }
    if (passController.text != confirmPassController.text) {
      showErrorMessage("Passwords do not match.");
      return;
    }
    if (passController.text.length < 6) {
      showErrorMessage("Password must be at least 6 characters.");
      return;
    }

    // See login_page: a successful sign-up fires authStateChanges and
    // unmounts this page before the await returns, so we pop via a captured
    // navigator rather than a (by-then-false) `mounted` check.
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: userController.text.trim(),
        password: passController.text,
      );
      navigator.pop();
    } on FirebaseAuthException catch (e) {
      navigator.pop();
      showErrorMessage(authErrorMessage(e.code));
    } catch (e) {
      navigator.pop();
      showErrorMessage("Something went wrong. Please try again.");
    }
  }

  void signUpWithGoogle() async {
    try {
      await AuthService().signInWithGoogle();
    } catch (e) {
      showErrorMessage("Google sign-in failed. Please try again.");
    }
  }

  void showErrorMessage(String message) {
    if (!mounted) return;
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Error",
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text(
              message,
              style: const TextStyle(fontSize: 18),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.purple[900],
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "OK",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: SafeArea(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 20), // Useful for giving space

                  Icon(
                    Icons.flutter_dash,
                    size: 130,
                    color: Colors.purple[900],
                  ),

                  const SizedBox(height: 30),

                  const Text('Let\'s get started with Flutterer!',
                      style: TextStyle(fontSize: 25)),

                  const SizedBox(height: 20),

                  MyTextField(
                      controller: userController,
                      hintText: "Email",
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      obscureText: false),

                  const SizedBox(height: 20),

                  MyTextField(
                      controller: passController,
                      hintText: "Password",
                      prefixIcon: Icons.lock,
                      obscureText: true),

                  const SizedBox(height: 20),

                  MyTextField(
                      controller: confirmPassController,
                      hintText: "Confirm Password",
                      prefixIcon: Icons.lock,
                      obscureText: true),

                  const SizedBox(height: 25),
                  MyButton(onTap: signUserUp, message: "Sign Up"),

                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey[600],
                            thickness: 0.5,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "OR",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey[600],
                            thickness: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  SquareTile(
                      imagePath: "lib/images/icons8-google-144.png",
                      tileText: "Sign Up with Google",
                      onTap: signUpWithGoogle),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?",
                          style: TextStyle(color: Colors.grey[600])),
                      TextButton(
                        onPressed: widget.onPressed,
                        child: Text(
                          "Login",
                          style: TextStyle(
                              color: Colors.purple[900], fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
