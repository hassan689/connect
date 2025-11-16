import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:linkster/config/app_config.dart';

/// Points Service - Handles point-based transactions and commission
/// Replaces the JazzCash payment system with a point-based system
class PointsService {
  // Commission rates loaded from environment configuration
  static double get platformCommissionRate => AppConfig.platformCommissionRate;
  static double get providerPayoutRate => AppConfig.providerPayoutRate;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Calculate commission amounts for points
  static Map<String, double> calculateCommission(double totalPoints) {
    final platformCommission = totalPoints * platformCommissionRate;
    final providerPayout = totalPoints * providerPayoutRate;
    
    return {
      'totalPoints': totalPoints,
      'platformCommission': platformCommission,
      'providerPayout': providerPayout,
    };
  }

  /// Get user's current point balance
  Future<double> getUserPoints(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return 0.0;
      }
      final userData = userDoc.data() ?? {};
      final pointsData = userData['points'] as Map<String, dynamic>? ?? {};
      return (pointsData['balance'] as num? ?? 0).toDouble();
    } catch (e) {
      print('Error getting user points: $e');
      return 0.0;
    }
  }

  /// Add points to user's account
  Future<Map<String, dynamic>> addPoints({
    required String userId,
    required double points,
    String? description,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        
        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        final userData = userDoc.data() ?? {};
        final pointsData = userData['points'] as Map<String, dynamic>? ?? {};
        final currentBalance = (pointsData['balance'] as num? ?? 0).toDouble();
        final newBalance = currentBalance + points;

        transaction.update(userRef, {
          'points.balance': newBalance,
          'points.updatedAt': FieldValue.serverTimestamp(),
        });

        // Create transaction record
        final transactionId = 'PT${DateTime.now().millisecondsSinceEpoch}';
        await userRef.collection('pointTransactions').add({
          'transactionId': transactionId,
          'points': points,
          'type': 'credit',
          'description': description ?? 'Points added',
          'balanceBefore': currentBalance,
          'balanceAfter': newBalance,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'completed',
        });
      });

      return {
        'success': true,
        'message': 'Points added successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to add points: $e',
      };
    }
  }

  /// Process payment when task is completed
  /// Deducts from task poster's points and splits commission
  Future<Map<String, dynamic>> processTaskPayment({
    required String taskId,
    required String providerId,
    required double taskPoints,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      // Get task details
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        return {'success': false, 'error': 'Task not found'};
      }

      final taskData = taskDoc.data()!;
      final taskPosterId = taskData['userId'] as String;

      // Calculate commission
      final commission = calculateCommission(taskPoints);
      final platformCommission = commission['platformCommission']!;
      final providerPayout = commission['providerPayout']!;

      // Process payment in transaction
      await _firestore.runTransaction((transaction) async {
        // 1. Deduct from task poster's points
        final posterRef = _firestore.collection('users').doc(taskPosterId);
        final posterDoc = await transaction.get(posterRef);
        final posterData = posterDoc.data() ?? {};
        final posterPoints = posterData['points'] as Map<String, dynamic>? ?? {};
        final posterBalance = (posterPoints['balance'] as num? ?? 0).toDouble();

        if (posterBalance < taskPoints) {
          throw Exception('Insufficient points balance');
        }

        // Deduct payment from poster
        transaction.update(posterRef, {
          'points.balance': posterBalance - taskPoints,
          'points.updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. Add commission to platform points (admin account)
        final platformRef = _firestore.collection('users').doc('platform_admin');
        final platformDoc = await transaction.get(platformRef);
        final platformData = platformDoc.data() ?? {};
        final platformPoints = platformData['points'] as Map<String, dynamic>? ?? {};
        final platformBalance = (platformPoints['balance'] as num? ?? 0).toDouble();

        if (platformDoc.exists) {
          transaction.update(platformRef, {
            'points.balance': platformBalance + platformCommission,
            'points.updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Create platform points account if doesn't exist
          transaction.set(platformRef, {
            'points': {
              'balance': platformCommission,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            'role': 'platform',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // 3. Add payout to provider's points
        final providerRef = _firestore.collection('users').doc(providerId);
        final providerDoc = await transaction.get(providerRef);
        final providerData = providerDoc.data() ?? {};
        final providerPoints = providerData['points'] as Map<String, dynamic>? ?? {};
        final providerBalance = (providerPoints['balance'] as num? ?? 0).toDouble();

        // Add points to provider
        if (providerDoc.exists) {
          transaction.update(providerRef, {
            'points.balance': providerBalance + providerPayout,
            'points.updatedAt': FieldValue.serverTimestamp(),
            'totalEarnings': (providerData['totalEarnings'] as num? ?? 0).toDouble() + providerPayout,
          });
        } else {
          transaction.set(providerRef, {
            'points': {
              'balance': providerPayout,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            'totalEarnings': providerPayout,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // 4. Create transaction records
        final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';

        // Task poster transaction (debit)
        final posterTransactionRef = posterRef.collection('pointTransactions').doc();
        transaction.set(posterTransactionRef, {
          'transactionId': transactionId,
          'taskId': taskId,
          'points': taskPoints,
          'type': 'debit',
          'description': 'Payment for task completion',
          'balanceBefore': posterBalance,
          'balanceAfter': posterBalance - taskPoints,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'completed',
        });

        // Provider transaction (credit)
        final providerTransactionRef = providerRef.collection('pointTransactions').doc();
        transaction.set(providerTransactionRef, {
          'transactionId': transactionId,
          'taskId': taskId,
          'points': providerPayout,
          'type': 'credit',
          'description': 'Task completion payout',
          'balanceBefore': providerBalance,
          'balanceAfter': providerBalance + providerPayout,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'completed',
        });

        // Platform commission record
        final commissionRef = _firestore.collection('commissions').doc();
        transaction.set(commissionRef, {
          'commissionId': commissionRef.id,
          'taskId': taskId,
          'points': platformCommission,
          'totalPoints': taskPoints,
          'rate': platformCommissionRate,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Payout record
        final payoutRef = _firestore.collection('payouts').doc();
        transaction.set(payoutRef, {
          'payoutId': payoutRef.id,
          'taskId': taskId,
          'providerId': providerId,
          'taskPosterId': taskPosterId,
          'points': providerPayout,
          'commission': platformCommission,
          'totalPoints': taskPoints,
          'status': 'completed',
          'paymentMethod': 'points',
          'completedAt': FieldValue.serverTimestamp(),
        });
      });

      return {
        'success': true,
        'platformCommission': platformCommission,
        'providerPayout': providerPayout,
        'message': 'Payment processed successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Payment processing failed: $e',
      };
    }
  }

  /// Get platform commission summary
  Future<Map<String, dynamic>> getPlatformCommissionSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('commissions');
      
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      double totalCommission = 0.0;
      int transactionCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('points')) {
          totalCommission += (data['points'] as num).toDouble();
          transactionCount++;
        }
      }

      return {
        'success': true,
        'totalCommission': totalCommission,
        'transactionCount': transactionCount,
        'averageCommission': transactionCount > 0 ? totalCommission / transactionCount : 0.0,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to get commission summary: $e',
      };
    }
  }

  /// Get user's point transaction history
  Stream<QuerySnapshot> getUserPointTransactions(String userId, {int limit = 10}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('pointTransactions')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }
}

