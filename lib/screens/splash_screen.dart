import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qiscus_chat_flutter_sample/providers/auth_provider.dart';
import 'package:qiscus_chat_flutter_sample/screens/login_screen.dart';
import 'package:qiscus_chat_flutter_sample/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Wait minimum 2 seconds for splash screen visibility
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    
    // Wait for auth provider to finish its initialization
    // Check periodically if login check is complete
    int attempts = 0;
    while (attempts < 20 && !_hasNavigated) { // Max 10 seconds
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Check if AuthProvider has finished loading
      if (!authProvider.isLoading) {
        _navigateToNextScreen(authProvider);
        break;
      }
      
      attempts++;
    }
    
    // If still loading after timeout, navigate anyway
    if (!_hasNavigated && mounted) {
      debugPrint('SplashScreen: Timeout waiting for auth check, navigating...');
      _navigateToNextScreen(authProvider);
    }
  }

  void _navigateToNextScreen(AuthProvider authProvider) {
    if (_hasNavigated) return;
    _hasNavigated = true;

    debugPrint('SplashScreen: Navigating...');
    debugPrint('SplashScreen: isLoggedIn = ${authProvider.isLoggedIn}');
    debugPrint('SplashScreen: currentUser = ${authProvider.currentUser?.id}');

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => authProvider.isLoggedIn
            ? const HomeScreen()
            : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_rounded,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'Qiscus Chat SDK',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Example Integration',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
