import 'package:flutter/material.dart';
import '../logic/services/auth_service.dart';
import 'login_screen.dart';
import 'old/prediction_chat_screen.dart';

/// Gerbang autentikasi: menentukan layar awal berdasarkan status login.
///
/// - Sudah login  -> langsung ke home (PredictionChatScreen)
/// - Belum login   -> ke LoginScreen
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return FutureBuilder<bool>(
      future: authService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: Colors.green.shade700,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.eco_rounded, size: 80, color: Colors.white),
                  SizedBox(height: 24),
                  Text(
                    'PadiCare',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 40),
                  CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          );
        }

        final isLoggedIn = snapshot.data ?? false;
        return isLoggedIn ? const PredictionChatScreen() : const LoginScreen();
      },
    );
  }
}
