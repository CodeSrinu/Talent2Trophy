import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String userType,
  }) async {
    try {
      print('AuthService: Starting sign up for $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('AuthService: User created successfully, sending email verification');

      // Send email verification
      await credential.user!.sendEmailVerification();
      print('AuthService: Email verification sent');

      // Create user document in Firestore
      if (credential.user != null) {
        try {
          final userModel = UserModel(
            id: credential.user!.uid,
            email: email,
            name: name,
            userType: userType,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await _firestore
              .collection('users')
              .doc(credential.user!.uid)
              .set(userModel.toFirestore());
          
          print('AuthService: Firestore document created successfully');
        } catch (firestoreError) {
          print('AuthService: Firestore document creation failed: $firestoreError');
          // Continue without Firestore document - user is still created in Auth
        }
        
        // Save user type to local storage
        await _saveUserType(userType);
      }
      
      return credential;
    } catch (e) {
      print('AuthService: Sign up error: $e');
      throw _handleAuthError(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('AuthService: Starting sign in for $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified
      if (credential.user != null && !credential.user!.emailVerified) {
        await _auth.signOut();
        throw Exception('Please verify your email before logging in. Check your inbox for the verification link.');
      }

      print('AuthService: Sign in successful, fetching user data from Firestore');
      
      // Get user type from Firestore and save to local storage
      if (credential.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();
        
        print('AuthService: Firestore document fetched: ${userDoc.exists}');
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          final userType = userData?['userType'] ?? '';
          await _saveUserType(userType);
          print('AuthService: User type saved: $userType');
        } else {
          // Create missing user document
          print('AuthService: User document does not exist, creating one...');
          final userModel = UserModel(
            id: credential.user!.uid,
            email: email,
            name: credential.user!.displayName ?? 'User',
            userType: 'player', // Default to player
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await _firestore
              .collection('users')
              .doc(credential.user!.uid)
              .set(userModel.toFirestore());
          
          print('AuthService: Missing user document created successfully');
          await _saveUserType('player');
        }
      }
      
      return credential;
    } catch (e) {
      print('AuthService: Sign in error: $e');
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('AuthService: Starting sign out');
      await _auth.signOut();
      await _clearLocalData();
      print('AuthService: Sign out successful');
    } catch (e) {
      print('AuthService: Sign out error: $e');
      throw _handleAuthError(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      print('AuthService: Getting user data for $userId');
      final doc = await _firestore.collection('users').doc(userId).get();
      print('AuthService: Firestore response - exists: ${doc.exists}');
      if (doc.exists) {
        final userModel = UserModel.fromFirestore(doc);
        print('AuthService: User data retrieved successfully');
        return userModel;
      }
      print('AuthService: User document does not exist');
      return null;
    } catch (e) {
      print('AuthService: Get user data error: $e');
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        ...data,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Save user type to local storage
  Future<void> _saveUserType(String userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userTypeKey, userType);
  }

  // Get user type from local storage
  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userTypeKey);
  }

  // Clear local data
  Future<void> _clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userTypeKey);
    await prefs.remove(AppConstants.authTokenKey);
  }

  // Handle authentication errors
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'weak-password':
          return 'Password is too weak. Please choose a stronger password.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'This operation is not allowed.';
        case 'permission-denied':
          return 'Permission denied. Please check your Firebase configuration.';
        default:
          return 'Authentication failed: ${error.code}. Please try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  // Check if user is verified (for scouts)
  Future<bool> isUserVerified(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['isVerified'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Request scout verification
  Future<void> requestScoutVerification({
    required String userId,
    required String organization,
    required String designation,
    required String experience,
    required List<String> specializations,
    required String documentUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'scoutVerification': {
          'organization': organization,
          'designation': designation,
          'experience': experience,
          'specializations': specializations,
          'documentUrl': documentUrl,
          'requestedAt': Timestamp.fromDate(DateTime.now()),
          'status': 'pending',
        },
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to request verification: $e');
    }
  }
}
