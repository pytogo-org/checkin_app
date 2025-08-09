import 'package:checking_app/screens/login_screen.dart';
import 'package:checking_app/screens/scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(EventCheckInApp(cameras: cameras));
}

class EventCheckInApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const EventCheckInApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Event checkin app',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/scanner': (context) => ScannerScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    setState(() {
      _hasToken = token != null;
      _isLoading = false;
    });

    if (_hasToken && mounted) {
      Navigator.pushReplacementNamed(context, '/scanner');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _hasToken ? const SizedBox.shrink() : const LoginScreen();
  }
}