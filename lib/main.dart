import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/dispatcher/firebase_home.dart';
import 'screens/executive/executive_repository.dart';
import 'screens/executive/home.dart';
import 'services/auth_service.dart';
import 'utils/app_constants.dart';
import 'services/delivery_service.dart';
import 'services/escalation_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? initializationError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    initializationError = error;
  }

  runApp(
    MyApp(
      firebaseReady: initializationError == null,
      initializationError: initializationError,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool firebaseReady;
  final Object? initializationError;
  final AuthService? authService;

  const MyApp({
    super.key,
    this.firebaseReady = false,
    this.initializationError,
    this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RouteSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B6C4A)),
        useMaterial3: true,
      ),
      home: firebaseReady
          ? AppRouter(authService: authService ?? AuthService())
          : initializationError == null
          ? const _TestPlaceholder()
          : _InitializationError(error: initializationError!),
    );
  }
}

class RouteSyncApp extends StatelessWidget {
  final ExecutiveRepository? repository;

  const RouteSyncApp({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RouteSync',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E69)),
        useMaterial3: true,
      ),
      home: ExecutiveHome(
        repository: repository ?? const UnavailableExecutiveRepository(),
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  final AuthService authService;

  const AppRouter({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }
        if (snapshot.hasError) {
          return _ErrorState(message: snapshot.error.toString());
        }
        final user = snapshot.data;
        if (user == null) {
          return SignInScreen(authService: authService);
        }
        return _ProfileRouter(authService: authService);
      },
    );
  }
}

class _ProfileRouter extends StatelessWidget {
  final AuthService authService;

  const _ProfileRouter({required this.authService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: authService.requireCurrentUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }
        if (snapshot.hasError) {
          return _ProfileError(
            error: snapshot.error!,
            onSignOut: authService.signOut,
          );
        }

        final profile = snapshot.data!;
        return switch (profile.role) {
          UserRoles.dispatcher => FirebaseDispatcherHome(
            authService: authService,
            deliveryService: DeliveryService(),
            escalationService: EscalationService(),
          ),
          UserRoles.executive => ExecutiveHome(
            repository: FirebaseExecutiveRepository(authService: authService),
          ),
          _ => _ProfileError(
            error: const AuthServiceException(
              'The user profile has an unsupported role.',
            ),
            onSignOut: authService.signOut,
          ),
        };
      },
    );
  }
}

class SignInScreen extends StatefulWidget {
  final AuthService authService;

  const SignInScreen({super.key, required this.authService});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ?? error.code);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RouteSync')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Sign in', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _signIn,
            child: _busy
                ? const CircularProgressIndicator()
                : const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _InitializationError extends StatelessWidget {
  final Object error;

  const _InitializationError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Firebase initialization failed: $error'),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(message)));
  }
}

class _ProfileError extends StatelessWidget {
  final Object error;
  final Future<void> Function() onSignOut;

  const _ProfileError({required this.error, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onSignOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestPlaceholder extends StatelessWidget {
  const _TestPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('RouteSync - Firebase Connected')),
    );
  }
}
