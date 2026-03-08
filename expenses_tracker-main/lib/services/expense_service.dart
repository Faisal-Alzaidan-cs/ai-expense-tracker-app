import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID or null if not authenticated
  String? get currentUserId => _auth.currentUser?.uid;

  /// Load IDs of SMS messages that have already been processed
  Future<Set<String>> loadProcessedSmsIds() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('expenses')
            .where('userId', isEqualTo: user.uid)
            .where('smsId', isNull: false)
            .get();

        final processedIds =
            snapshot.docs.map((doc) => doc.data()['smsId'].toString()).toSet();

        debugPrint(
            "✅ Loaded ${processedIds.length} previously processed SMS IDs");
        return processedIds;
      }
    } catch (e) {
      debugPrint("❌ Error loading processed SMS IDs: $e");
    }
    return {};
  }

  /// Save an expense to Firestore and update user balance
  Future<void> saveExpenseAndUpdateBalance(Map<String, dynamic> expense) async {
    final String? userId = currentUserId;
    if (userId == null) {
      debugPrint("❌ Cannot save expense - user not logged in");
      return;
    }

    try {
      final double amount = expense['amount'] is double
          ? expense['amount']
          : double.tryParse(expense['amount'] ?? '0.0') ?? 0.0;

      final userDoc = await _firestore.collection('users').doc(userId).get();

      final userData = userDoc.data();
      double currentBalance = 0.0;
      if (userData != null && userData['balance'] != null) {
        currentBalance = (userData['balance'] as num).toDouble();
      }

      final double newBalance = currentBalance - amount;

      await _firestore.runTransaction((transaction) async {
        transaction.update(
          _firestore.collection('users').doc(userId),
          {'balance': newBalance},
        );

        transaction.set(
          _firestore.collection('expenses').doc(),
          {
            'amount': amount,
            'merchant': expense['merchant'] ?? 'Unknown',
            'category': expense['category'] ?? 'other',
            'date': expense['timestamp'] ?? FieldValue.serverTimestamp(),
            'userId': userId,
            'smsId': expense['smsId'],
            'cardNumber': expense['cardNumber'],
            'cardType': expense['cardType'],
            'notes': expense['notes'],
            'paymentMethod': expense['paymentMethod'] ?? 'Unknown',
            'automatic': expense['automatic'] ?? true,
            'rawInput': expense['rawInput'],
          },
        );
      });

      debugPrint("💰 Balance updated: $currentBalance - $amount = $newBalance");
    } catch (e) {
      debugPrint("❌ Error saving expense to Firestore: $e");
    }
  }

  /// Save multiple expenses to Firestore
  Future<void> saveExtractedExpenses(
      List<Map<String, dynamic>> expenses) async {
    if (currentUserId == null) {
      debugPrint("❌ Cannot save expenses - user not logged in");
      return;
    }

    try {
      for (var expense in expenses) {
        await saveExpenseAndUpdateBalance(expense);
      }
      debugPrint("✅ Expenses saved to Firebase");
    } catch (e) {
      debugPrint("❌ Error batch saving to Firebase: $e");
    }
  }

  /// Check if user has any expenses
  Future<bool> hasExistingExpenses() async {
    final String? userId = currentUserId;
    if (userId == null) {
      debugPrint("❌ Cannot check expenses - user not logged in");
      return false;
    }

    try {
      final snapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint("❌ Error checking for existing expenses: $e");
      return false;
    }
  }
}
