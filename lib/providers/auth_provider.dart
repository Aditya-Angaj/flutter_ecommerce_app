import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  late final FirebaseService _firebaseService;
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFirebaseInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  AuthProvider() {
    _firebaseService = FirebaseService();
    _initializeFirebase();
    debugPrint('AuthProvider initialized');
  }

  void _initializeFirebase() {
    try {
      final app = Firebase.app();
      _auth = FirebaseAuth.instanceFor(app: app);
      _auth!.authStateChanges().listen(_onAuthStateChanged);
      _isFirebaseInitialized = true;
      debugPrint('AuthProvider: Firebase Auth initialized successfully');
    } catch (e, st) {
      debugPrint('AuthProvider: Firebase Auth initialization failed: $e');
      debugPrint(st.toString());
      _isFirebaseInitialized = false;
    }
  }

  Future<bool> _ensureFirebaseInitialized() async {
    if (_isFirebaseInitialized && _auth != null) return true;
    
    try {
      final app = Firebase.app(); // Get the default app
      _auth = FirebaseAuth.instanceFor(app: app);
      await _auth!.authStateChanges().first; // Test the auth state
      _isFirebaseInitialized = true;
      debugPrint('AuthProvider: Firebase Auth verified successfully');
      return true;
    } catch (e, st) {
      debugPrint('AuthProvider: Firebase Auth verification failed: $e');
      debugPrint(st.toString());
      _isFirebaseInitialized = false;
      _currentUser = null;
      return false;
    }
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (!_isFirebaseInitialized) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    if (firebaseUser != null) {
      _currentUser = await _firebaseService.getUser(firebaseUser.uid);
      notifyListeners();
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    final initOk = await _ensureFirebaseInitialized();
    if (!initOk) {
      _errorMessage = 'Firebase is not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _auth?.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential?.user != null) {
        _currentUser = await _firebaseService.getUser(userCredential!.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Initialize Firebase Auth if not already initialized
      if (_auth == null) {
        debugPrint('Initializing Firebase Auth...');
        _auth = FirebaseAuth.instance;
      }

      debugPrint('Attempting to create user with email: $email');
      final userCredential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final createdUser = userCredential.user;
      if (createdUser == null) {
        debugPrint('User creation succeeded but user is null');
        _isLoading = false;
        _errorMessage = 'Failed to create user account';
        notifyListeners();
        return false;
      }

      debugPrint('User created successfully with ID: ${createdUser.uid}');
      final user = UserModel(
        id: createdUser.uid,
        email: email,
        name: name,
        isAdmin: false,
        createdAt: DateTime.now(),
      );

      // Ensure Firestore service is initialized
      if (!_firebaseService.isInitialized) {
        debugPrint('Firestore not initialized, reinitializing...');
        _firebaseService = FirebaseService();
        
        if (!_firebaseService.isInitialized) {
          debugPrint('Failed to initialize Firestore');
          // Delete the auth user since we couldn't save their profile
          await createdUser.delete();
          _isLoading = false;
          _errorMessage = 'Failed to initialize database connection';
          notifyListeners();
          return false;
        }
      }

      try {
        debugPrint('Saving user profile to Firestore...');
        await _firebaseService.createUser(user);
        debugPrint('User profile saved successfully');
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } catch (fsErr) {
        debugPrint('Failed to save user profile: $fsErr');
        // Try to delete the auth user since we couldn't save their profile
        try {
          await createdUser.delete();
        } catch (deleteErr) {
          debugPrint('Failed to clean up auth user after profile creation failed: $deleteErr');
        }
        _isLoading = false;
        _errorMessage = 'Failed to save user profile: ${fsErr.toString()}';
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e, st) {
      _isLoading = false;
      debugPrint('FirebaseAuthException in signUp: code=${e.code}, message=${e.message}');
      debugPrint(st.toString());
      _errorMessage = '${_getErrorMessage(e.code)}${e.message != null ? ': ${e.message}' : ''}';
      notifyListeners();
      return false;
    } catch (e, st) {
      _isLoading = false;
      debugPrint('Unexpected exception in signUp: $e');
      debugPrint(st.toString());
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    final initOk = await _ensureFirebaseInitialized();
    if (initOk) {
      await _auth?.signOut();
    }
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> updateProfile({String? name, String? phoneNumber, String? address}) async {
    final initOk = await _ensureFirebaseInitialized();
    if (!initOk || _currentUser == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      final updatedUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
        address: address ?? _currentUser!.address,
      );

      await _firebaseService.updateUser(updatedUser);
      _currentUser = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update profile';
      notifyListeners();
      return false;
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'Authentication failed ($code)';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}