import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expenses_tracker/models/goal.dart';

class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get all goals for the current user directly from the goals collection
  Stream<List<Goal>> getGoals() {
    try {
      if (currentUserId == null) {
        print('No user logged in, cannot fetch goals');
        return Stream.value([]);
      }

      print('Fetching goals for user: $currentUserId');

      return _firestore
          .collection('goals')
          .where('userId', isEqualTo: currentUserId)
          .snapshots()
          .map((snapshot) {
        print('Goals snapshot received: ${snapshot.docs.length} documents');
        return snapshot.docs.map((doc) {
          final data = doc.data();
          print('Goal data: $data');
          return Goal(
            title: data['title'] ?? 'Unnamed Goal',
            currentAmount: data['currentAmount'] is int
                ? data['currentAmount']
                : int.tryParse(data['currentAmount']?.toString() ?? '0') ?? 0,
            targetAmount: data['targetAmount'] is int
                ? data['targetAmount']
                : int.tryParse(data['targetAmount']?.toString() ?? '0') ?? 0,
            monthlySavings: data['monthlySavings'] is int
                ? data['monthlySavings']
                : int.tryParse(data['monthlySavings']?.toString() ?? '0') ?? 0,
          );
        }).toList();
      });
    } catch (e) {
      print('Exception in getGoals: $e');
      return Stream.value([]);
    }
  }

  // Create a new goal
  Future<void> addGoal(Goal goal) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      print('Adding goal: ${goal.title}');

      await _firestore.collection('goals').add({
        'userId': currentUserId,
        'title': goal.title,
        'currentAmount': goal.currentAmount,
        'targetAmount': goal.targetAmount,
        'monthlySavings': goal.monthlySavings,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Goal added successfully');
    } catch (e) {
      print('Error adding goal: $e');
      rethrow;
    }
  }

  // Update an existing goal
  Future<void> updateGoal(String goalId, Goal goal) {
    return _firestore.collection('goals').doc(goalId).update({
      'title': goal.title,
      'currentAmount': goal.currentAmount,
      'targetAmount': goal.targetAmount,
      'monthlySavings': goal.monthlySavings,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a goal
  Future<void> deleteGoal(String goalId) {
    return _firestore.collection('goals').doc(goalId).delete();
  }

  // Add a sample goal for testing
  Future<void> addSampleGoal() async {
    try {
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final sampleGoal = Goal(
        title: 'Sample Vacation Goal',
        currentAmount: 2000,
        targetAmount: 10000,
        monthlySavings: 500,
      );

      print('Adding sample goal');
      await addGoal(sampleGoal);
      print('Sample goal added successfully');
    } catch (e) {
      print('Error adding sample goal: $e');
      rethrow;
    }
  }
}
