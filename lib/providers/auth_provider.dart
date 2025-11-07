import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseService? _firebaseService;
  
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
    // For development purposes, we'll treat the app as logged out
    // when Firebase is not initialized
    _tryInitializeFirebase();
  }

  void _tryInitializeFirebase() {
    try {
      _auth = FirebaseAuth.instance;
      _firebaseService = FirebaseService();
      _auth?.authStateChanges().listen(_onAuthStateChanged);
      _isFirebaseInitialized = true;
    } catch (e) {
      debugPrint('Firebase not initialized: $e');
      _isFirebaseInitialized = false;
      _currentUser = null;
    }
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (!_isFirebaseInitialized) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    if (firebaseUser != null) {
      _currentUser = await _firebaseService?.getUser(firebaseUser.uid);
      notifyListeners();
    } else {
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    if (!_isFirebaseInitialized) {
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
        _currentUser = await _firebaseService?.getUser(userCredential!.user!.uid);
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
    if (!_isFirebaseInitialized) {
      _errorMessage = 'Firebase is not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _auth?.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential?.user != null) {
        final user = UserModel(
          id: userCredential!.user!.uid,
          email: email,
          name: name,
          isAdmin: false,
          createdAt: DateTime.now(),
        );

        await _firebaseService?.createUser(user);
        _currentUser = user;
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

  Future<void> signOut() async {
    if (_isFirebaseInitialized) {
      await _auth?.signOut();
    }
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> updateProfile({String? name, String? phoneNumber, String? address}) async {
    if (!_isFirebaseInitialized || _currentUser == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      final updatedUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
        address: address ?? _currentUser!.address,
      );

      await _firebaseService?.updateUser(updatedUser);
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
        return 'Authentication failed';
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}