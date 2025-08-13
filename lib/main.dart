import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/video/presentation/screens/record_screen.dart';
import 'features/video/presentation/screens/library_screen.dart';
import 'features/video/presentation/screens/video_analysis_screen.dart';
import 'features/player_shell/presentation/player_shell.dart';
import 'features/home/presentation/player_home_screen.dart';
import 'features/scout/presentation/scout_dashboard_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with proper options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Test Firebase connection
    print('Firebase project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
    print('Firebase auth domain: ${DefaultFirebaseOptions.currentPlatform.authDomain}');

    // Test Firestore connection
    try {
      print('Testing Firestore connection...');
      final firestore = FirebaseFirestore.instance;
      print('Firestore instance created');

      // Try to get a simple document to test connection
      final testDoc = await firestore.collection('test').doc('connection').get();
      print('Firestore connection test successful');
    } catch (firestoreError) {
      print('Firestore connection test failed: $firestoreError');
    }

  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue without Firebase for now
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Router configuration
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthWrapper(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/player',
      builder: (context, state) => const PlayerShell(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/record/:sport',
      builder: (context, state) {
        final sport = state.pathParameters['sport'] ?? 'Football';
        return RecordScreen(sport: sport);
      },
    ),
    GoRoute(
      path: '/library',
      builder: (context, state) => const LibraryScreen(),
    ),
    GoRoute(
      path: '/analysis',
      builder: (context, state) {
        // This will be used when we implement the full analysis screen
        // For now, we'll redirect to library
        return const LibraryScreen();
      },
    ),
  ],
);

// Auth wrapper to handle authentication state
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final currentUser = ref.watch(currentUserProvider);

      return currentUser.when(
        data: (user) {
          print('AuthWrapper - User data: ${user?.email}');
          if (user != null) {
            // Route by user type
            if (user.isPlayer) {
              return const PlayerHomeScreen();
            } else if (user.isScout) {
              return const ScoutDashboardScreen();
            } else {
              return const HomeScreen();
            }
          } else {
            // User is not authenticated, show login screen
            return const LoginScreen();
          }
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) {
          print('AuthWrapper - Error: $error');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppConstants.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Firebase Error: $error',
                    style: const TextStyle(
                      color: AppConstants.errorColor,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please check your Firebase configuration:\n'
                    '1. Authentication (Email/Password)\n'
                    '2. Firestore Database\n'
                    '3. Firestore Rules',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry loading
                      ref.invalidate(currentUserProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('AuthWrapper - Exception: $e');
      // Fallback if there's any error
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppConstants.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                'App Error: $e',
                style: const TextStyle(
                  color: AppConstants.errorColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Show login screen as fallback
                  context.go('/login');
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

// Home screen (placeholder for now)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user?.displayName ?? 'User'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              context.go('/profile');
            },
          ),
          // Logout parked per request
          // IconButton(
          //   icon: const Icon(Icons.logout),
          //   onPressed: () async {
          //     await ref.read(authProvider.notifier).signOut();
          //   },
          // ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports_soccer,
              size: 100,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Talent2Trophy!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You are logged in as: ${user?.userType ?? 'Unknown'}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppConstants.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Phase 1: Foundation & Core Infrastructure',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '✅ Firebase Authentication\n'
              '✅ User Registration/Login\n'
              '✅ User Type Selection (Player/Scout)\n'
              '✅ Clean Architecture Setup\n'
              '✅ Custom UI Components\n'
              '✅ State Management (Riverpod)\n'
              '🔄 Profile Management (In Progress)\n'
              '🔄 Offline Support (In Progress)',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if ((user?.sport ?? '').isEmpty) ...[
              const Text('Set your sport in Profile to start recording'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () { context.go('/profile'); },
                icon: const Icon(Icons.settings),
                label: const Text('Open Profile'),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () { context.go('/record/${user!.sport}'); },
                icon: Icon(user!.sport == 'Football' ? Icons.sports_soccer : Icons.sports_kabaddi),
                label: Text('Record ${user!.sport}'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () { context.go('/library'); },
                icon: const Icon(Icons.video_library),
                label: const Text('Open Library'),
              ),
            ],

          ],
        ),
      ),
    );
  }
}
