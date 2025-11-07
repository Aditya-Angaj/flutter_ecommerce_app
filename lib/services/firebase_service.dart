import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

class FirebaseService {
  final FirebaseFirestore? _firestore = _initFirestore();

  static FirebaseFirestore? _initFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  bool get isInitialized => _firestore != null;

  // User operations
  Future<void> createUser(UserModel user) async {
    if (!isInitialized) throw Exception('Firebase not initialized');
    await _firestore?.collection('users').doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUser(String userId) async {
    if (!isInitialized) throw Exception('Firebase not initialized');
    final doc = await _firestore?.collection('users').doc(userId).get();
    if (doc?.exists ?? false) {
      return UserModel.fromMap(doc!.data()!);
    }
    return null;
  }

  Future<void> updateUser(UserModel user) async {
    if (!isInitialized) throw Exception('Firebase not initialized');
    await _firestore?.collection('users').doc(user.id).update(user.toMap());
  }

  // Product operations
  Future<List<ProductModel>> getProducts() async {
    if (!isInitialized) throw Exception('Firebase not initialized');
    final snapshot = await _firestore?.collection('products').get();
    return snapshot?.docs
            .map((doc) => ProductModel.fromMap(doc.data()))
            .toList() ??
        [];
  }

  Future<ProductModel?> getProduct(String productId) async {
    if (!isInitialized) throw Exception('Firebase not initialized');
    final doc = await _firestore?.collection('products').doc(productId).get();
    if (doc?.exists ?? false) {
      return ProductModel.fromMap(doc!.data()!);
    }
    return null;
  }

  Future<void> addProduct(ProductModel product) async {
    if (!isInitialized) throw Exception('Firebase not initialized');
    await _firestore?.collection('products').doc(product.id).set(product.toMap());
  }

  Future<void> updateProduct(ProductModel product) async {
    if (!isInitialized) throw Exception('Firebase not initialized');
    await _firestore
        ?.collection('products')
        .doc(product.id)
        .update(product.toMap());
  }

  Future<void> deleteProduct(String productId) async {
    if (!isInitialized) throw Exception('Firebase not initialized');
    await _firestore?.collection('products').doc(productId).delete();
  }

  // Order operations
  Future<void> createOrder(OrderModel order) async {
    if (!isInitialized) throw Exception('Firebase not initialized');
    await _firestore?.collection('orders').doc(order.id).set(order.toMap());
  }

  Future<List<OrderModel>> getUserOrders(String userId) async {
    if (!isInitialized) throw Exception('Firebase not initialized');
    final snapshot = await _firestore
        ?.collection('orders')
        .where('userId', isEqualTo: userId)
        .get();
    
    return snapshot?.docs
            .map((doc) => OrderModel.fromMap(doc.data()))
            .toList() ??
        [];
  }

  Future<List<OrderModel>> getAllOrders() async {
    if (!isInitialized) throw Exception('Firebase not initialized');
    final snapshot = await _firestore?.collection('orders').get();
    return snapshot?.docs
            .map((doc) => OrderModel.fromMap(doc.data()))
            .toList() ??
        [];
  }

  Future<OrderModel?> getOrder(String orderId) async {
    if (!isInitialized) throw Exception('Firebase not initialized');
    final doc = await _firestore?.collection('orders').doc(orderId).get();
    if (doc?.exists ?? false) {
      return OrderModel.fromMap(doc!.data()!);
    }
    return null;
  }

  Future<void> updateOrder(OrderModel order) async {
    if (!isInitialized) throw Exception('Firebase not initialized');
    await _firestore?.collection('orders').doc(order.id).update(order.toMap());
  }

  // Stream operations for real-time updates
  Stream<List<ProductModel>>? productsStream() {
    if (!isInitialized) return null;
    return _firestore?.collection('products').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<OrderModel>>? userOrdersStream(String userId) {
    if (!isInitialized) return null;
    return _firestore
        ?.collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<OrderModel>>? allOrdersStream() {
    if (!isInitialized) return null;
    return _firestore?.collection('orders').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data()))
              .toList(),
        );
  }
}