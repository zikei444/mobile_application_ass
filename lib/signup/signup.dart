import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_application_ass/login/login.dart';
//import 'package:mobile_application_ass/services/auth_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
//import "package:google_fonts/google_fonts.dart";

class Signup extends StatelessWidget {
  Signup({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: _signin(context),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 50,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 16),
            child: Column(
              children: [
                Center(
                    child: Image.asset(
                      'assets/images/logo.webp',
                      height: 120,
                    ),
                  ),
                  Text(
                    'Create an Account',
                    style: GoogleFonts.raleway(
                        textStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 32
                        )
                    ),
                  ),

                const SizedBox(height: 80,),
                _emailAddress(),
                const SizedBox(height: 20,),
                _password(),
                const SizedBox(height: 50,),
                _signup(context),
              ],
            ),

          ),
        )
    );
  }

  Widget _emailAddress() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: GoogleFonts.raleway(
              textStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                  fontSize: 16
              )
          ),
        ),
        const SizedBox(height: 16,),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
              filled: true,
              hintText: 'mahdiforwork@gmail.com',
              hintStyle: const TextStyle(
                  color: Color(0xff6A6A6A),
                  fontWeight: FontWeight.normal,
                  fontSize: 14
              ),
              fillColor: const Color(0xffF7F7F9) ,
              border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(14)
              )
          ),
        )
      ],
    );
  }

  Widget _password() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: GoogleFonts.raleway(
              textStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                  fontSize: 16
              )
          ),
        ),
        const SizedBox(height: 16,),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xffF7F7F9) ,
              border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(14)
              )
          ),
        )
      ],
    );
  }

  Widget _signup(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF138146),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        minimumSize: const Size(double.infinity, 60),
        elevation: 0,
      ),
      onPressed: () async {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        // mail validation
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(email)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enter a valid email address.")),
          );
          return;
        }

        // password validation
        if (password.isEmpty || password.length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password must be at least 6 characters.")),
          );
          return;
        }

        try {
          await AuthService().signup(
            email: email,
            password: password,
            context: context,
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Signup successful! Please log in.")),
          );

          // Small delay to let user see the message
          await Future.delayed(const Duration(seconds: 1));

          // Navigate to Login page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Login()),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Signup failed: ${e.toString()}")),
          );
        }
      },
      child: const Text(
        "Sign Up",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }



  Widget _signin(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
              children: [
                const TextSpan(
                  text: "Already Have Account? ",
                  style: TextStyle(
                      color: Color(0xff6A6A6A),
                      fontWeight: FontWeight.normal,
                      fontSize: 16
                  ),
                ),
                TextSpan(
                    text: "Log In",
                    style: const TextStyle(
                        color: Color(0xff1A1D1E),
                        fontWeight: FontWeight.normal,
                        fontSize: 16
                    ),
                    recognizer: TapGestureRecognizer()..onTap = () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Login()
                        ),
                      );
                    }
                ),
              ]
          )
      ),
    );
  }
}