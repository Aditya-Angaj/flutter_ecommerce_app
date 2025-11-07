import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../services/firebase_service.dart';

class OrderProvider extends ChangeNotifier {
  FirebaseService? _firebaseService;
  bool _isFirebaseInitialized = false;
  
  List<OrderModel> _orders = [];
  List<OrderModel> _allOrders = []; // For admin
  bool _isLoading = false;
  String? _errorMessage;

  OrderProvider() {
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
    final dummyOrder = OrderModel(
      id: '1',
      userId: 'test-user',
      items: [],
      totalAmount: 0,
      status: OrderStatus.pending,
      shippingAddress: '123 Test St',
      createdAt: DateTime.now(),
    );
    _orders = [dummyOrder];
    _allOrders = [dummyOrder];
  }

  List<OrderModel> get orders => _orders;
  List<OrderModel> get allOrders => _allOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserOrders(String userId) async {
    if (!_isFirebaseInitialized) {
      // Using dummy data
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final orders = await _firebaseService?.getUserOrders(userId);
      if (orders != null) {
        _orders = orders;
        _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load orders';
      notifyListeners();
    }
  }

  Future<void> fetchAllOrders() async {
    if (!_isFirebaseInitialized) {
      // Using dummy data
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final allOrders = await _firebaseService?.getAllOrders();
      if (allOrders != null) {
        _allOrders = allOrders;
        _allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load orders';
      notifyListeners();
    }
  }

  Future<bool> placeOrder({
    required String userId,
    required List<CartItemModel> items,
    required String shippingAddress,
    String? phoneNumber,
  }) async {
    if (!_isFirebaseInitialized) {
      _errorMessage = 'Firebase is not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final totalAmount = items.fold<double>(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

      final order = OrderModel(
        id: const Uuid().v4(),
        userId: userId,
        items: items,
        totalAmount: totalAmount,
        status: OrderStatus.pending,
        shippingAddress: shippingAddress,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
      );

      await _firebaseService?.createOrder(order);
      _orders.insert(0, order);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to place order';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus status) async {
    if (!_isFirebaseInitialized) {
      _errorMessage = 'Firebase is not initialized';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Update in all orders (admin view)
      final allOrderIndex = _allOrders.indexWhere((o) => o.id == orderId);
      if (allOrderIndex != -1) {
        final updatedOrder = _allOrders[allOrderIndex].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
        await _firebaseService?.updateOrder(updatedOrder);
        _allOrders[allOrderIndex] = updatedOrder;
      }

      // Update in user orders if present
      final orderIndex = _orders.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        final updatedOrder = _orders[orderIndex].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
        _orders[orderIndex] = updatedOrder;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update order status';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    return updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  OrderModel? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      try {
        return _allOrders.firstWhere((order) => order.id == orderId);
      } catch (e) {
        return null;
      }
    }
  }

  List<OrderModel> getOrdersByStatus(OrderStatus status) {
    return _allOrders.where((order) => order.status == status).toList();
  }

  int get pendingOrdersCount {
    return _allOrders.where((o) => o.status == OrderStatus.pending).length;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}