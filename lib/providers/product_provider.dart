import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/firebase_service.dart';

class ProductProvider extends ChangeNotifier {
  FirebaseService? _firebaseService;
  bool _isFirebaseInitialized = false;
  
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  ProductProvider() {
    _tryInitializeFirebase();
  }

  void _tryInitializeFirebase() {
    try {
      _firebaseService = FirebaseService();
      _isFirebaseInitialized = true;
    } catch (e) {
      debugPrint('Firebase not initialized: $e');
      _isFirebaseInitialized = false;
      // Initialize with dummy data for development
      _initializeDummyData();
    }
  }

  void _initializeDummyData() {
    _products = [
      ProductModel(
        id: '1',
        name: 'Sample Product 1',
        description: 'This is a sample product for development',
        price: 99.99,
        imageUrl: 'https://via.placeholder.com/200',
        category: 'Electronics',
        stock: 10,
        createdAt: DateTime.now(),
        isActive: true,
      ),
      ProductModel(
        id: '2',
        name: 'Sample Product 2',
        description: 'Another sample product for development',
        price: 49.99,
        imageUrl: 'https://via.placeholder.com/200',
        category: 'Clothing',
        stock: 20,
        createdAt: DateTime.now(),
        isActive: true,
      ),
    ];
    _applyFilters();
  }

  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get allProducts => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  List<String> get categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    return ['All', ...cats];
  }

  Future<void> fetchProducts() async {
    if (!_isFirebaseInitialized) {
      // Already initialized with dummy data
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final products = await _firebaseService?.getProducts();
      if (products != null) {
        _products = products;
        _applyFilters();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load products';
      notifyListeners();
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void searchProducts(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      final matchesCategory = _selectedCategory == 'All' || 
                              product.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
                           product.name.toLowerCase().contains(_searchQuery) ||
                           product.description.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch && product.isActive;
    }).toList();
  }

  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> addProduct(ProductModel product) async {
    if (!_isFirebaseInitialized) {
      _errorMessage = 'Firebase is not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService?.addProduct(product);
      _products.add(product);
      _applyFilters();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to add product';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    if (!_isFirebaseInitialized) {
      _errorMessage = 'Firebase is not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService?.updateProduct(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        _applyFilters();
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update product';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    if (!_isFirebaseInitialized) {
      _errorMessage = 'Firebase is not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService?.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
      _applyFilters();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete product';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}