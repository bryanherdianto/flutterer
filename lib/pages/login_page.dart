import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterer_app/components/my_button.dart';
import 'package:flutterer_app/components/my_textfield.dart';
import 'package:flutterer_app/components/square_tile.dart';
import 'package:flutterer_app/pages/forgot_pass_page.dart';
import 'package:flutterer_app/services/auth_service.dart';
import 'package:flutterer_app/services/auth_error.dart';

class LoginPage extends StatefulWidget {
  final Function()? onPressed;

  const LoginPage({super.key, required this.onPressed});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userController = TextEditingController();

  final passController = TextEditingController();

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  void signUserIn() async {
    if (userController.text.trim().isEmpty || passController.text.isEmpty) {
      showErrorMessage("Please enter your email and password.");
      return;
    }

    // Capture the navigator up front. A successful sign-in fires
    // authStateChanges, which unmounts this page before the await returns,
    // so `mounted` would be false and a context-based pop would be skipped —
    // leaving the loading dialog stranded on screen forever.
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
      await FirebaseAuth.instance.signInWithEmailAndPassword(
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

  void signInWithGoogle() async {
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

                  const Text('Welcome to Flutterer!',
                      style: TextStyle(fontSize: 25, fontFamily: 'Roboto')),

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

                  const SizedBox(height: 5),

                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                          // Row useful for making a new alignment
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPassPage()));
                              },
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(
                                    color: Colors.purple[900],
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          ])),

                  const SizedBox(height: 25),
                  MyButton(onTap: signUserIn, message: "Sign In"),

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
                      tileText: "Sign In with Google",
                      onTap: signInWithGoogle),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Not a member?",
                          style: TextStyle(color: Colors.grey[600])),
                      TextButton(
                        onPressed: widget.onPressed,
                        child: Text(
                          "Register",
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
