import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../services/firebase_service.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<OrderModel> _orders = [];
  List<OrderModel> _allOrders = []; // For admin
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get orders => _orders;
  List<OrderModel> get allOrders => _allOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserOrders(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _orders = await _firebaseService.getUserOrders(userId);
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load orders';
      notifyListeners();
    }
  }

  Future<void> fetchAllOrders() async {
    try {
      _isLoading = true;
      notifyListeners();

      _allOrders = await _firebaseService.getAllOrders();
      _allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
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

      await _firebaseService.createOrder(order);
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
        await _firebaseService.updateOrder(updatedOrder);
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