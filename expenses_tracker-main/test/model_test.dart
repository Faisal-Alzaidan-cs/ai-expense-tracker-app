import 'package:flutter_test/flutter_test.dart';
import 'package:expenses_tracker/models/goal.dart';

void main() {
  group('Goal Model Tests', () {
    test('Goal can be instantiated with correct values', () {
      final goal = Goal(
        title: 'New Car',
        currentAmount: 1000,
        targetAmount: 10000,
        monthlySavings: 500,
      );

      expect(goal.title, 'New Car');
      expect(goal.currentAmount, 1000);
      expect(goal.targetAmount, 10000);
      expect(goal.monthlySavings, 500);
    });

    test('Goal properties can be updated', () {
      final goal = Goal(
        title: 'Vacation',
        currentAmount: 200,
        targetAmount: 2000,
        monthlySavings: 100,
      );

      goal.currentAmount = 300;
      goal.monthlySavings = 150;

      expect(goal.currentAmount, 300);
      expect(goal.monthlySavings, 150);
    });

    test('Goal progress calculation', () {
      final goal = Goal(
        title: 'Home Renovation',
        currentAmount: 5000,
        targetAmount: 20000,
        monthlySavings: 1000,
      );

      // Manually calculate expected progress percentage
      final progress = goal.currentAmount / goal.targetAmount;

      // This is a direct calculation as the Goal class doesn't have a progress method yet
      expect(progress, 0.25); // 25% progress
    });

    test('Goal months remaining calculation', () {
      final goal = Goal(
        title: 'Education Fund',
        currentAmount: 2000,
        targetAmount: 5000,
        monthlySavings: 1000,
      );

      // Calculate how many months are needed to reach the target
      final remainingAmount = goal.targetAmount - goal.currentAmount;
      final monthsNeeded = remainingAmount / goal.monthlySavings;

      // This is a direct calculation as the Goal class doesn't have this method yet
      expect(monthsNeeded, 3.0); // 3 months needed to complete the goal
    });
  });
}
